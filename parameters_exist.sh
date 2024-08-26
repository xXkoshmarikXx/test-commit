#!/usr/bin/env bash
set -euxo pipefail

REGION="il-central-1"
echo "region: $REGION"

ACCOUNT_ID="992382682634"
echo "account: $ACCOUNT_ID"

TOPIC_NAME="errors"
echo "topic: $TOPIC_NAME"

GET_PIP_URL="s3://resource-opinion-stg/get-pip.py"
echo "Get Pip URL: $GET_PIP_URL"

PLAYBOOK_BASE_URL="s3://bootstrap-opinion-stg/playbooks"
echo "Playbook Base URL: $PLAYBOOK_BASE_URL"

PLAYBOOK_NAME="ansible-openvpn"
echo "playbook_name: $PLAYBOOK_NAME"

VAULT_PASSWORD="123123"

bash parameters_accepts.sh --get_pip_url "$GET_PIP_URL" --playbook_name "$PLAYBOOK_NAME" --playbook_base_url "$PLAYBOOK_BASE_URL" -r "$REGION" --account_id "$ACCOUNT_ID" --topic_name "$TOPIC_NAME" --vault_password $VAULT_PASSWORD