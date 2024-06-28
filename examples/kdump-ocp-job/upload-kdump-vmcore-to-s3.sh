#!/bin/bash

# Configure AWS CLI to use the s3 bucket
aws configure set aws_access_key_id $S3_ACCESS_KEY_ID
aws configure set aws_secret_access_key $S3_SECRET_ACCESS_KEY
aws configure set default.region $BUCKET_REGION
aws configure set s3.endpoint_url "http://$S3_ENDPOINT:$S3_PORT"
# Check for new vmcore files and upload them to the S3 bucket
for dir in /var/crash/*; do
  if [ -d "$dir" ]; then
    for file in "$dir"/*; do
      if [ -f "$file" ]; then
        timestamp=$(stat -c %Y "$file")  # Get file modification timestamp
        formatted_date=$(date -d @$timestamp +"%d-%m-%Y-%H:%M:%S")
        hostname=$(hostname)
        filename="$file-$formatted_date"
        aws s3 cp "$file" "s3://$S3_BUCKET_NAME/$hostname/$filename"
      fi
    done
  fi
done

