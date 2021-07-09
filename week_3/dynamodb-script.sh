#!/bin/bash

aws dynamodb list-tables --region us-west-2

aws dynamodb put-item --table-name dynamodb-table-student --item '{"itin": {"S": "itin-1"}, "First name": {"S": "Vasya"}, "Last name": {"S": "Pupkin"}
, "Course": {"N": "1"}}' --region us-west-2

aws dynamodb put-item --table-name dynamodb-table-student --item '{"itin": {"S": "itin-2"}, "First name": {"S": "Petya"}, "Last name": {"S": "Pyatochk
in"}, "Course": {"N": "2"}}' --region us-west-2

aws dynamodb get-item --table-name dynamodb-table-student --key '{"itin": {"S": "itin-2"}, "Last name": {"S": "Pyatochk
in"}}' --region us-west-2

aws dynamodb get-item --table-name dynamodb-table-student --key '{"itin": {"S": "itin-2"}, "Last name": {"S": "Not existing"}}' --region us-west-2