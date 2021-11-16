#!/usr/bin/env bash
set -euo pipefail

GIT_REPO_ROOT=$(git rev-parse --show-toplevel)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

docker build $GIT_REPO_ROOT --tag prometheus-ado-exporter
docker save --output prometheus-ado-exporter.tar prometheus-ado-exporter

sha256sum prometheus-ado-exporter.tar
echo 'aws s3 cp prometheus-ado-exporter.tar s3://<bucket-name>/prometheus-ado-exporter.tar'