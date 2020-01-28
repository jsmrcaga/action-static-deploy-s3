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

	echo "Setting up bucket public access policy"
	sed "s/{BUCKET_NAME}/$BUCKET_NAME/g" ./aws-policies/bucket-policy-template.json > ./aws-policies/bucket-policy.json
	aws s3api put-bucket-policy --bucket $BUCKET_NAME --policy file://aws-policies/bucket-policy.json

	echo "Setting up cloudfront distribution"
	caller_reference=$(date +%s)
	sed "s/{BUCKET_NAME}/$BUCKET_NAME/g" ./aws-policies/cloudfront-distribution-template.json > ./aws-policies/cloudfront-distribution-template-bucket.json
	sed "s/{CALLER_REFERENCE}/$caller_reference/g" ./aws-policies/cloudfront-distribution-template-bucket.json > ./aws-policies/cloudfront-distribution.json
	distribution_result=`aws cloudfront create-distribution --distribution-config file://aws-policies/cloudfront-distribution.json`
	cloudfront_domain=`"echo $distribution_result" | jq '.Distribution.DomainName'`
	cloudfront_location=`"echo $distribution_result" | jq '.Location'`

	echo "Your new cloudfront distribution can be found at:"
	echo $cloudfront_location
	echo "You will be able to access your website at:"
	echo $cloudfront_domain

else
	echo "Bucket $BUCKET_NAME already exists, ignoring creation."
fi

# Sync files from given directory
echo "Syncing files to $BUCKET_NAME..."
aws s3 sync $SITE_DIRECTORY s3://$BUCKET_NAME $INPUT_AWS_SYNC_ARGS --acl=public-read
