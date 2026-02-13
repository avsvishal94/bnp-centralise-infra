#!/bin/bash
# ============================================================================
# SRE Ecosystem - Application Onboarding Script
# ============================================================================
# This script is run by the SRE team to onboard a new application into the
# centrally managed Terraform infrastructure pipeline.
#
# What it does:
#   1. Creates statefile directories in Artifactory for the application
#   2. Generates a Jenkinsfile from the SRE template
#   3. (Optional) Pushes the Jenkinsfile to the application repository
#
# Usage:
#   ./sre_onboard_app.sh \
#     --app-name <application_name> \
#     --ecosystem <ecosystem_name> \
#     --environments "DEV,STG,PT,QA" \
#     --artifactory-url <artifactory_base_url> \
#     --repo-url <bitbucket_repo_url>
# ============================================================================

set -euo pipefail

# ---- Defaults ----
ENVIRONMENTS="DEV,STG"
ECOSYSTEMS="PB-GLOBALPRIMEDB,Puma"
ARTIFACTORY_BASE_URL="${ARTIFACTORY_BASE_URL:-https://artifactory.cib.echonet/artifactory}"
STATEFILE_REPO="terraform-statefiles"
CYBERARK_CERT_ID="AIM-PBGBLPRIMEDB-OPSD-Cyberark.cert"
CYBERARK_KEY_ID="AIM-PBGBLPRIMEDB-OPSD-Cyberark.key"
ARTIFACTORY_CRED_ID="primedb_cib_artifactory"
APIGEE_CRED_ID="APIGEE_PDB_DEV"
TEMPLATE_FILE="$(dirname "$0")/Jenkinsfile.template"
OUTPUT_DIR="./generated"

# ---- Color Output ----
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}[INFO]${NC}  $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}    $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# ---- Parse Arguments ----
APP_NAME=""
REPO_URL=""
PUSH_TO_REPO=false

usage() {
    echo "Usage: $0 --app-name <name> [--environments 'DEV,STG,PT,QA'] [--ecosystems 'PB-GLOBALPRIMEDB,Puma'] [--repo-url <url>] [--push]"
    echo ""
    echo "Options:"
    echo "  --app-name        (Required) Application name for statefile directories"
    echo "  --environments    Comma-separated environments (default: DEV,STG)"
    echo "  --ecosystems      Comma-separated ecosystems (default: PB-GLOBALPRIMEDB,Puma)"
    echo "  --artifactory-url Artifactory base URL"
    echo "  --repo-url        Bitbucket repository URL for the application"
    echo "  --push            Push generated Jenkinsfile to application repo"
    echo "  --help            Show this help message"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --app-name)        APP_NAME="$2"; shift 2 ;;
        --environments)    ENVIRONMENTS="$2"; shift 2 ;;
        --ecosystems)      ECOSYSTEMS="$2"; shift 2 ;;
        --artifactory-url) ARTIFACTORY_BASE_URL="$2"; shift 2 ;;
        --repo-url)        REPO_URL="$2"; shift 2 ;;
        --push)            PUSH_TO_REPO=true; shift ;;
        --help)            usage ;;
        *)                 log_error "Unknown option: $1"; usage ;;
    esac
done

if [[ -z "$APP_NAME" ]]; then
    log_error "Application name is required."
    usage
fi

echo ""
echo "============================================================"
echo " SRE Ecosystem - Application Onboarding"
echo "============================================================"
echo " Application:  $APP_NAME"
echo " Environments: $ENVIRONMENTS"
echo " Ecosystems:   $ECOSYSTEMS"
echo "============================================================"
echo ""

# ============================================================================
# STEP 1: Create Statefile Directories in Artifactory
# ============================================================================
log_info "Step 1: Creating statefile directories in Artifactory..."

IFS=',' read -ra ENV_ARRAY <<< "$ENVIRONMENTS"

for env in "${ENV_ARRAY[@]}"; do
    env_lower=$(echo "$env" | tr '[:upper:]' '[:lower:]')
    dir_path="${STATEFILE_REPO}/${APP_NAME}/${env_lower}/"

    log_info "  Creating: ${dir_path}"

    # Create directory in Artifactory using REST API
    # The trailing slash tells Artifactory to create a folder
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
        -X PUT \
        -H "X-JFrog-Art-Api: ${ARTIFACTORY_API_KEY:-}" \
        "${ARTIFACTORY_BASE_URL}/${dir_path}" \
        2>/dev/null || echo "000")

    if [[ "$HTTP_CODE" == "201" || "$HTTP_CODE" == "200" ]]; then
        log_ok "  Created: ${dir_path}"
    elif [[ "$HTTP_CODE" == "000" ]]; then
        log_warn "  Dry-run (no API key): ${dir_path} - would be created"
    else
        log_warn "  HTTP ${HTTP_CODE} for ${dir_path} - may already exist"
    fi
done

echo ""

# ============================================================================
# STEP 2: Generate Jenkinsfile from Template
# ============================================================================
log_info "Step 2: Generating Jenkinsfile from template..."

mkdir -p "$OUTPUT_DIR"

# Format environment choices for Jenkinsfile
ENV_CHOICES=$(echo "$ENVIRONMENTS" | sed "s/,/', '/g" | sed "s/^/'/" | sed "s/$/'/" )

# Format ecosystem choices for Jenkinsfile
ECO_CHOICES=$(echo "$ECOSYSTEMS" | sed "s/,/', '/g" | sed "s/^/'/" | sed "s/$/'/" )

if [[ ! -f "$TEMPLATE_FILE" ]]; then
    log_error "Template file not found: $TEMPLATE_FILE"
    exit 1
fi

# Generate Jenkinsfile by replacing placeholders
sed \
    -e "s|{{CYBERARK_CERT_ID}}|${CYBERARK_CERT_ID}|g" \
    -e "s|{{CYBERARK_KEY_ID}}|${CYBERARK_KEY_ID}|g" \
    -e "s|{{ARTIFACTORY_CRED_ID}}|${ARTIFACTORY_CRED_ID}|g" \
    -e "s|{{APIGEE_CRED_ID}}|${APIGEE_CRED_ID}|g" \
    -e "s|{{ENVIRONMENT_CHOICES}}|${ENV_CHOICES}|g" \
    -e "s|{{ECOSYSTEM_CHOICES}}|${ECO_CHOICES}|g" \
    -e "s|{{APP_NAME}}|${APP_NAME}|g" \
    "$TEMPLATE_FILE" > "${OUTPUT_DIR}/Jenkinsfile"

log_ok "Generated: ${OUTPUT_DIR}/Jenkinsfile"

echo ""

# ============================================================================
# STEP 3: (Optional) Push to Application Repository
# ============================================================================
if [[ "$PUSH_TO_REPO" == true && -n "$REPO_URL" ]]; then
    log_info "Step 3: Pushing Jenkinsfile to application repository..."

    TEMP_CLONE=$(mktemp -d)
    git clone "$REPO_URL" "$TEMP_CLONE" 2>/dev/null

    cp "${OUTPUT_DIR}/Jenkinsfile" "${TEMP_CLONE}/Jenkinsfile"

    cd "$TEMP_CLONE"
    git add Jenkinsfile
    git commit -m "chore(sre): add SRE managed Jenkinsfile for Terraform pipeline

Onboarded by SRE Ecosystem automation.
Application: ${APP_NAME}
Environments: ${ENVIRONMENTS}
Ecosystems: ${ECOSYSTEMS}"

    git push origin HEAD
    cd -
    rm -rf "$TEMP_CLONE"

    log_ok "Jenkinsfile pushed to repository."
else
    log_info "Step 3: Skipped (use --push --repo-url <url> to push to repo)"
fi

echo ""
echo "============================================================"
echo " Onboarding Complete!"
echo "============================================================"
echo ""
echo " Next Steps for Application Team:"
echo "   1. Review the generated Jenkinsfile in: ${OUTPUT_DIR}/Jenkinsfile"
echo "   2. Add/modify your Terraform files (main.tf, variables.tf, outputs.tf)"
echo "   3. Ensure your backend config points to the SRE statefile location"
echo "   4. Run the Jenkins pipeline with the appropriate environment"
echo ""
echo "============================================================"
