#!/bin/bash

# Get Deps
wget https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-linux-amd64
mv jq-linux-amd64 jq
chmod +x jq

BITNAMI_NAME_REGEXP="^$PG_MAJOR_VERSION.*debian"
echo $BITNAMI_NAME_REGEXP
BITNAMI_POSTGRES_REG_CONTENT=$(wget -q -O - "https://hub.docker.com/v2/namespaces/bitnami/repositories/postgresql/tags?page_size=100")
BITNAMI_NAME=$(echo -n $BITNAMI_POSTGRES_REG_CONTENT | jq -r --arg BITNAMI_NAME_REGEXP $BITNAMI_NAME_REGEXP '.results[] | select(.name | test($BITNAMI_NAME_REGEXP)) | .name' | head -n 1)
BITNAMI_DIGEST=$(echo -n $BITNAMI_POSTGRES_REG_CONTENT | jq -r --arg BITNAMI_NAME_REGEXP $BITNAMI_NAME_REGEXP '.results[] | select(.name | test($BITNAMI_NAME_REGEXP)) | .digest' | head -n 1)
echo "Bitnami - Name: $BITNAMI_NAME, Digest: ${BITNAMI_DIGEST:7:5}"

PGVECTOR_REG_CONTENT=$(wget -q -O - "https://hub.docker.com/v2/namespaces/pgvector/repositories/pgvector/tags?page_size=100")
PGVECTOR_NAME=$(echo -n $PGVECTOR_REG_CONTENT | jq -r '.results[] | select(.name | test(".*\\..*\\..*-pg16")) | .name' | head -n 1)
PGVECTOR_DIGEST=$(echo -n $PGVECTOR_REG_CONTENT | jq -r '.results[] | select(.name | test(".*\\..*\\..*-pg16")) | .digest' | head -n 1)
echo "PGVector - Name: $PGVECTOR_NAME, Digest: ${PGVECTOR_DIGEST:7:5}"

TAG_IDENTIFIER=pg$PG_MAJOR_VERSION-${BITNAMI_DIGEST:7:5}-${PGVECTOR_DIGEST:7:5}
echo "Identifier will be $TAG_IDENTIFIER"

response_code=$(curl --head --fail -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $GITHUB_TOKEN" -X GET https://ghcr.io/v2/bat-bs/bitnami-pgvector/manifests/$TAG_IDENTIFIER)
if [ $response_code -eq 200 ]; then
  echo "latest Tag found in Registry, no further build is required"
  exit 1
fi
elif [ $response_code -eq 404 ]; then
  echo "Tag not found in registry. The image will be build."
else
  echo "Error: " + $response_code + " please check the script"
fi

# export vars for later jobs

echo "TAG_IDENTIFIER=$TAG_IDENTIFIER" >> $GITHUB_ENV

echo "PGVECTOR_NAME=$PGVECTOR_NAME" >> $GITHUB_ENV
echo "BITNAMI_NAME=$BITNAMI_NAME" >> $GITHUB_ENV