#!/bin/bash
set -e

# Upload content guidance and style guide to Localstack S3 bucket
# This script syncs the local content folders to the ai-uc-content-swarm-context bucket

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONTENT_GUIDANCE_DIR="$SCRIPT_DIR/notebooks/outputs/content-guidance"
CONTENT_STYLE_GUIDE_DIR="$SCRIPT_DIR/notebooks/outputs/content-style-guide"

BUCKET_NAME="ai-uc-content-swarm-context"
LOCALSTACK_ENDPOINT="${LOCALSTACK_ENDPOINT:-http://localhost:4566}"

echo "Uploading content guidance from: $CONTENT_GUIDANCE_DIR"
aws s3 sync "$CONTENT_GUIDANCE_DIR" "s3://$BUCKET_NAME/content-guidance/" \
  --endpoint-url "$LOCALSTACK_ENDPOINT" \
  --region "${AWS_REGION:-eu-west-2}"

echo "Uploading content style guide from: $CONTENT_STYLE_GUIDE_DIR"
aws s3 sync "$CONTENT_STYLE_GUIDE_DIR" "s3://$BUCKET_NAME/content-style-guide/" \
  --endpoint-url "$LOCALSTACK_ENDPOINT" \
  --region "${AWS_REGION:-eu-west-2}"

echo "Upload complete!"
