#!/usr/bin/env bash
set -euxo pipefail
# Constants
LOCAL_IDENTIFY_OS_SCRIPT="identify_os.sh"
REMOTE_IDENTIFY_OS_SCRIPT="https://raw.githubusercontent.com/inqwise/ansible-automation-toolkit/default/identify_os.sh"
VAULT_PASSWORD_FILE="vault_password"
PLAYBOOK_VERSION="latest"

ACCOUNT_ID=""
TOPIC_NAME=""
REGION=""
SKIP_TAGS=""
TAGS=""
EXTRA=""
OFFLINE=false
TEST_MODE=false
PIP_COMMAND="pip"
GET_PIP_URL=""
PLAYBOOK_NAME=""
PLAYBOOK_BASE_URL=""

VAULT_PASSWORD=""
METADATA_TOKEN=""

usage() {
    echo "Usage: $0 [-e <extra>] [--skip-tags <skip-tags>] [--tags <tags>] [--offline] [--test] [--token <token>] [--get_pip_url <url>] [--playbook_name <name>] [--playbook_base_url <url>] [-r <name>] [--account_id <name>] [--topic_name <name>] [--vault_password <name>]"
    exit 1
}

while getopts ":e:r:-:" option; do
  case "${option}" in
    e) EXTRA="${OPTARG}";;
    -)
      case "${OPTARG}" in
        skip-tags) SKIP_TAGS="${!OPTIND}"; OPTIND=$((OPTIND + 1));;
        tags) TAGS="${!OPTIND}"; OPTIND=$((OPTIND + 1));;
        account_id) ACCOUNT_ID="${!OPTIND}"; OPTIND=$((OPTIND + 1));;
        topic_name) TOPIC_NAME="${!OPTIND}"; OPTIND=$((OPTIND + 1));;
        get_pip_url) GET_PIP_URL="${!OPTIND}"; OPTIND=$((OPTIND + 1));;
        playbook_name) PLAYBOOK_NAME="${!OPTIND}"; OPTIND=$((OPTIND + 1));;
        playbook_base_url) PLAYBOOK_BASE_URL="${!OPTIND}"; OPTIND=$((OPTIND + 1));;
        vault_password) VAULT_PASSWORD="${!OPTIND}"; OPTIND=$((OPTIND + 1));;
        metadata_token) METADATA_TOKEN="${!OPTIND}"; OPTIND=$((OPTIND + 1));;
        offline) OFFLINE=true;;
        test) TEST_MODE=true;;
        *) echo "Invalid option --${OPTARG}"; usage;;
      esac
      ;;
    \?) echo "Invalid option: -${OPTARG}" >&2; usage;;
    :) echo "Option -${OPTARG} requires an argument." >&2; usage;;
  esac
done

# Functions
assert_var() {
    local var_name="$1"
    local var_value="$2"
    if [ -z "$var_value" ]; then
        echo "Error: $var_name is not set." >&2
        exit 1
    fi
}

# Global Variables
PYTHON_BIN=python3
MAIN_SCRIPT_URL=""

identify_os() {
    echo 'identify_os'
    if [ -z "${OS_FAMILY:-}" ]; then
        echo "OS_FAMILY is not defined."
        if [ -f "$LOCAL_IDENTIFY_OS_SCRIPT" ]; then
            echo "Executing local identify_os.sh..."
            source "$LOCAL_IDENTIFY_OS_SCRIPT"
        else
            echo "Local identify_os.sh not found. Executing from remote URL..."
            source <(curl -s "$REMOTE_IDENTIFY_OS_SCRIPT")
        fi
    fi
}

cleanup() {
    if [ -f "$VAULT_PASSWORD_FILE" ]; then
        rm -f "$VAULT_PASSWORD_FILE"
        echo "vault_password file removed."
    fi
}

catch_error() {
    echo "An error occurred in goldenimage_script: '$1'"
    cleanup
    local instance_id=$(ec2-metadata --instance-id | sed -n 's/.*instance-id: \(i-[a-f0-9]\{17\}\).*/\1/p')
    aws sns publish --topic-arn "arn:aws:sns:$REGION:$ACCOUNT_ID:$TOPIC_NAME" --message "$1" --subject "$instance_id" --region "$REGION"
}

setup_environment() {
    echo 'setup_environment'
    sudo mkdir /deployment
    sudo chown -R "$(whoami)": /deployment

    if [[ "$OS_FAMILY" == "amzn" && "$OS_VERSION" -eq 2 ]]; then
        echo 'amzn2 tweaks'
        PYTHON_BIN="python3.8"
        MAIN_SCRIPT_URL="https://raw.githubusercontent.com/inqwise/ansible-automation-toolkit/default/main_amzn2.sh"
        sudo yum -y erase python3 && sudo amazon-linux-extras install $PYTHON_BIN
    else
        MAIN_SCRIPT_URL="https://raw.githubusercontent.com/inqwise/ansible-automation-toolkit/default/main_amzn2023.sh"
    fi

    $PYTHON_BIN -m venv /deployment/ansibleenv
    source /deployment/ansibleenv/bin/activate
}

install_pip() {
    echo 'install_pip'
    local url=$1
    if [[ $url == s3://* ]]; then
        echo "Downloading get-pip from S3..."
        aws s3 cp "$url" - | $PYTHON_BIN
    elif [[ $url == http*://* ]]; then
        echo "Downloading get-pip via HTTP..."
        curl -s "$url" | $PYTHON_BIN
    else
        echo "Unsupported URL scheme: $url" >&2
        exit 1
    fi
}

download_playbook() {
    local base_url=$1
    local name=$2
    local local_folder=$3
    local s3_folder="$base_url/$name/$PLAYBOOK_VERSION"
    
    if aws s3 ls "$s3_folder" --region $REGION >/dev/null 2>&1; then
        echo "download playbook '$s3_folder'"
        mkdir "$local_folder" 
        aws s3 cp "$s3_folder/" "$local_folder" --recursive --region "$REGION" --exclude '.*' --exclude '*/.*'
        chmod -R 755 "$local_folder"
    else
        echo "S3 folder $s3_folder does not exist. Exiting." >&2
        exit 1
    fi
}

run_main_script() {
    echo 'run_main_script'
    cd /deployment/playbook
    echo "$VAULT_PASSWORD" > "$VAULT_PASSWORD_FILE"

    if [ ! -f "main.sh" ]; then
        echo "Local main.sh not found. Downloading main.sh script from URL..."
        curl -s "$MAIN_SCRIPT_URL" -o main.sh
    fi
    
    bash main.sh -e "playbook_name=$PLAYBOOK_NAME" --tags "installation"
    cleanup
}

main() {
    set -euo pipefail
    echo "Start goldenimage.sh"

    identify_os

    echo "playbook_name: $PLAYBOOK_NAME"

    assert_var "PLAYBOOK_NAME" "$PLAYBOOK_NAME"
    assert_var "PLAYBOOK_BASE_URL" "$PLAYBOOK_BASE_URL"
    assert_var "VAULT_PASSWORD" "$VAULT_PASSWORD"
    assert_var "GET_PIP_URL" "$GET_PIP_URL"

    setup_environment
    install_pip "$GET_PIP_URL"
    download_playbook "$PLAYBOOK_BASE_URL" "$PLAYBOOK_NAME" /deployment/playbook
    run_main_script

    echo "End goldenimage.sh"
}

# Trap errors and execute the catch_error function
trap 'catch_error "$ERROR"' ERR

# Execute the main function and capture errors
ERROR=$(main 2>&1)

# If you want to ensure that the script exits after an error, you can use:
if [ $? -ne 0 ]; then
    exit 1
fi