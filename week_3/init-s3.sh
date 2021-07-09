#!/bin/bash

aws s3api create-bucket --bucket dimzul-week-3-bucket --region us-west-2 --create-bucket-configuration LocationConstraint=us-west-2

aws s3api put-object --bucket dimzul-week-3-bucket --key week-3/rds-script.sql --body rds-script.sql

aws s3api put-object --bucket dimzul-week-3-bucket --key week-3/dynamodb-script.sh --body dynamodb-script.sh
