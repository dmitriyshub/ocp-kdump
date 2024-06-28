#!/bin/bash

# Configure AWS CLI to use the s3 bucket
aws configure set aws_access_key_id "$S3_ACCESS_KEY_ID"
aws configure set aws_secret_access_key "$S3_SECRET_ACCESS_KEY"
aws configure set default.region "$BUCKET_REGION"
aws configure set s3.endpoint_url "http://$S3_ENDPOINT:$S3_PORT"

# Function to upload file to S3 and delete locally on success
upload_and_delete() {
    local file="$1"
    local hostname=$(hostname)
    local timestamp=$(stat -c %Y "$file")
    local formatted_date=$(date -d @"$timestamp" +"%d-%m-%Y-%H:%M:%S")
    local filename="$file-$formatted_date"
    
    # Upload file to S3
    if aws s3 cp "$file" "s3://$S3_BUCKET_NAME/$hostname/$filename"; then
        echo "File uploaded successfully: $file"
        # Delete file locally after successful upload
        if rm -rf "$file"; then
            echo "Deleted local file: $file"
        else
            echo "Error: Unable to delete local file: $file"
        fi
    else
        echo "Error: Failed to upload file: $file"
    fi
}

# Check for new vmcore files and upload them to the S3 bucket
for dir in /var/crash/*; do
    if [ -d "$dir" ]; then
        for file in "$dir"/*; do
            if [ -f "$file" ]; then
                upload_and_delete "$file"
            fi
        done
    fi
done

