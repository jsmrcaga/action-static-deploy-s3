#!/bin/bash

set -e

echo "Setting up environment..."

REGION=$INPUT_AWS_S3_REGION
BUCKET_NAME=$INPUT_AWS_S3_BUCKET_NAME
SITE_DIRECTORY=$INPUT_SITE_DIRECTORY

# Export keys so aws cli can use them
echo "Setting up keys..."
export AWS_ACCESS_KEY_ID=$INPUT_AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$INPUT_AWS_SECRET_KEY

# Create bucket if not existing
echo "Creating bucket $BUCKET_NAME..."
aws s3api create-bucket --bucket $BUCKET_NAME --region $REGION --create-bucket-configuration=LocationConstraint=$REGION $INPUT_AWS_CREATE_ARGS 

# Set bucket to website config
echo "Setting bucket $BUCKET_NAME configuration to WEBSITE..."
aws s3 website s3://$BUCKET_NAME $INPUT_AWS_WEBSITE_ARGS --index-document index.html --error-document index.html

# Sync files from given directory
echo "Syncing files to $BUCKET_NAME..."
aws s3 sync $SITE_DIRECTORY s3://$BUCKET_NAME $INPUT_AWS_SYNC_ARGS
