#!/bin/bash
set -e

# Example AWS resource creation commands for Moto
aws --endpoint-url=http://localhost:5000 s3 mb s3://claims
aws --endpoint-url=http://localhost:5000 sqs create-queue --queue-name claim-processing-queue --attributes '{"VisibilityTimeout":"30"}'

echo "Startup script completed."
