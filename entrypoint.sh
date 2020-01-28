#!/bin/bash

set -e

REGION=$INPUT_AWS_S3_REGION
BUCKET_NAME=$INPUT_AWS_S3_BUCKET_NAME
SITE_DIRECTORY=$INPUT_SITE_DIRECTORY

# Export keys so aws cli can use them
export AWS_ACCESS_KEY_ID=$INPUT_AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$INPUT_AWS_SECRET_KEY

pip3 install awscli --upgrade --user

# Create bucket if not existing
aws s3api create-bucket --bucket $BUCKET_NAME --region $REGION $INPUT_AWS_CREATE_ARGS

# Set bucket to website config
aws s3 website s3://$BUCKET_NAME $INPUT_AWS_WEBSITE_ARGS

# Sync files from given directory
aws s3 sync $SITE_DIRECTORY s3://$BUCKET_NAME $INPUT_AWS_SYNC_ARGS
