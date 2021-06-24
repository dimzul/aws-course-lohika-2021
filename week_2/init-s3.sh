#!/bin/bash

echo 'Text file for S3' >> text.txt

aws s3api create-bucket --bucket dimzul-week-2-bucket --region us-west-2 --create-bucket-configuration LocationConstraint=us-west-2

aws s3api put-bucket-versioning --bucket dimzul-week-2-bucket --versioning-configuration Status=Enabled

aws s3api put-object --bucket dimzul-week-2-bucket --key week-2/text.txt --body text.txt