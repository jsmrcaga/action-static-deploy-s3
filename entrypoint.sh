#!/bin/bash

echo "Setting up environment..."

REGION=$INPUT_AWS_S3_REGION
BUCKET_NAME=$INPUT_AWS_S3_BUCKET_NAME
SITE_DIRECTORY=$INPUT_SITE_DIRECTORY

# Export keys so aws cli can use them
echo "Setting up keys..."
export AWS_ACCESS_KEY_ID=$INPUT_AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$INPUT_AWS_SECRET_KEY

# Check if bucket exists, 2>&1 because printed to stderr
echo "Checking if bucket already exists"
exists=`(aws s3api head-bucket --bucket $BUCKET_NAME) 2>&1`

reg="404"
if [[ $exists =~ $reg ]]
then
	# Create bucket if not existing
	echo "Creating bucket $BUCKET_NAME..."
	aws s3api create-bucket --bucket $BUCKET_NAME --region $REGION --create-bucket-configuration=LocationConstraint=$REGION $INPUT_AWS_CREATE_ARGS 
	
	# Set bucket to website config
	echo "Setting bucket $BUCKET_NAME configuration to WEBSITE..."
	aws s3 website s3://$BUCKET_NAME $INPUT_AWS_WEBSITE_ARGS --index-document index.html --error-document index.html

	echo "Setting up bucket redirection policy for serving index.html and static/ files..."
	aws s3api put-bucket-website --bucket $BUCKET_NAME --website-configuration file://aws-policies/redirection-policy.json

	echo "Setting up bucket public access policy"
	aws s3api put-bucket-policy --bucket $BUCKET_NAME --policy file://aws-policies/bucket-policy.json

else
	echo "Bucket $BUCKET_NAME already exists, ignoring creation."
fi

# Sync files from given directory
echo "Syncing files to $BUCKET_NAME..."
aws s3 sync $SITE_DIRECTORY s3://$BUCKET_NAME $INPUT_AWS_SYNC_ARGS --acl=public-read
