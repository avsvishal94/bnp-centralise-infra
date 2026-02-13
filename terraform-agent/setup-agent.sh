#!/bin/bash
# ============================================================================
# SRE Ecosystem - Terraform Agent Setup Script
# ============================================================================
# Provisions a Terraform agent node from a Marketplace VM image.
# This script is run on a fresh VM to configure it as a Jenkins worker node
# capable of executing Terraform infrastructure pipelines.
#
# Steps:
#   1. Create VM from Marketplace image
#   2. Install Java (required for Jenkins agent)
#   3. Install Terraform
#   4. Install supporting tools (Ansible, jq)
#   5. Create jenkins user
#   6. Configure SSH-based Jenkins agent
#   7. Label agent for infra/terraform jobs
#
# Usage:
#   sudo ./setup-agent.sh \
#     --jenkins-url <jenkins_controller_url> \
#     --agent-name <agent_name> \
#     --terraform-version <version>
# ============================================================================

set -euo pipefail

# ---- Defaults ----
TERRAFORM_VERSION="${TERRAFORM_VERSION:-1.7.5}"
ANSIBLE_VERSION="${ANSIBLE_VERSION:-latest}"
JENKINS_URL="${JENKINS_URL:-}"
AGENT_NAME="${AGENT_NAME:-terraform-agent}"
AGENT_LABEL="terraform-agent"
JENKINS_USER="jenkins"
JENKINS_HOME="/home/${JENKINS_USER}"
AGENT_WORKDIR="${JENKINS_HOME}/agent"

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
while [[ $# -gt 0 ]]; do
    case $1 in
        --jenkins-url)        JENKINS_URL="$2"; shift 2 ;;
        --agent-name)         AGENT_NAME="$2"; shift 2 ;;
        --terraform-version)  TERRAFORM_VERSION="$2"; shift 2 ;;
        --ansible-version)    ANSIBLE_VERSION="$2"; shift 2 ;;
        --help)
            echo "Usage: $0 --jenkins-url <url> [--agent-name <name>] [--terraform-version <ver>]"
            exit 0 ;;
        *) log_error "Unknown option: $1"; exit 1 ;;
    esac
done

echo ""
echo "============================================================"
echo " SRE Ecosystem - Terraform Agent Setup"
echo "============================================================"
echo " Agent Name:         ${AGENT_NAME}"
echo " Agent Label:        ${AGENT_LABEL}"
echo " Terraform Version:  ${TERRAFORM_VERSION}"
echo " Jenkins URL:        ${JENKINS_URL:-not set}"
echo "============================================================"
echo ""

# ============================================================================
# STEP 1: System Prerequisites
# ============================================================================
log_info "Step 1: Installing system prerequisites..."

apt-get update -qq
apt-get install -y -qq \
    curl \
    wget \
    unzip \
    git \
    openssh-server \
    python3 \
    python3-pip \
    ca-certificates \
    gnupg \
    lsb-release

log_ok "System prerequisites installed."

# ============================================================================
# STEP 2: Install Java (Jenkins Agent Requirement)
# ============================================================================
log_info "Step 2: Installing Java (OpenJDK 17)..."

apt-get install -y -qq openjdk-17-jdk-headless

java -version 2>&1
log_ok "Java installed: $(java -version 2>&1 | head -1)"

# ============================================================================
# STEP 3: Install Terraform
# ============================================================================
log_info "Step 3: Installing Terraform ${TERRAFORM_VERSION}..."

TERRAFORM_ZIP="terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
TERRAFORM_URL="https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/${TERRAFORM_ZIP}"

wget -q "${TERRAFORM_URL}" -O "/tmp/${TERRAFORM_ZIP}"
unzip -o "/tmp/${TERRAFORM_ZIP}" -d /usr/local/bin/
rm -f "/tmp/${TERRAFORM_ZIP}"

terraform version
log_ok "Terraform ${TERRAFORM_VERSION} installed."

# ============================================================================
# STEP 4: Install Supporting Tools (Ansible, jq)
# ============================================================================
log_info "Step 4: Installing supporting tools..."

# Install jq
apt-get install -y -qq jq
log_ok "jq installed: $(jq --version)"

# Install Ansible
if [[ "$ANSIBLE_VERSION" == "latest" ]]; then
    pip3 install --quiet ansible
else
    pip3 install --quiet "ansible==${ANSIBLE_VERSION}"
fi
log_ok "Ansible installed: $(ansible --version | head -1)"

# ============================================================================
# STEP 5: Create Jenkins User
# ============================================================================
log_info "Step 5: Creating jenkins user..."

if id "${JENKINS_USER}" &>/dev/null; then
    log_warn "User '${JENKINS_USER}' already exists, skipping creation."
else
    useradd -m -d "${JENKINS_HOME}" -s /bin/bash "${JENKINS_USER}"
    log_ok "User '${JENKINS_USER}' created with home: ${JENKINS_HOME}"
fi

mkdir -p "${AGENT_WORKDIR}"
chown -R "${JENKINS_USER}:${JENKINS_USER}" "${JENKINS_HOME}"

# ============================================================================
# STEP 6: Configure SSH-based Jenkins Agent
# ============================================================================
log_info "Step 6: Configuring SSH-based Jenkins agent..."

SSH_DIR="${JENKINS_HOME}/.ssh"
mkdir -p "${SSH_DIR}"

if [[ ! -f "${SSH_DIR}/id_rsa" ]]; then
    ssh-keygen -t rsa -b 4096 -f "${SSH_DIR}/id_rsa" -N "" -C "${AGENT_NAME}@jenkins"
    log_ok "SSH keypair generated."
else
    log_warn "SSH keypair already exists, skipping generation."
fi

chown -R "${JENKINS_USER}:${JENKINS_USER}" "${SSH_DIR}"
chmod 700 "${SSH_DIR}"
chmod 600 "${SSH_DIR}/id_rsa"
chmod 644 "${SSH_DIR}/id_rsa.pub"

# Copy public key to authorized_keys for inbound agent connection
cp "${SSH_DIR}/id_rsa.pub" "${SSH_DIR}/authorized_keys"
chmod 600 "${SSH_DIR}/authorized_keys"

# Ensure SSH service is running
systemctl enable ssh
systemctl start ssh

log_ok "SSH agent configured."
echo ""
echo "  Public key for Jenkins controller:"
echo "  $(cat "${SSH_DIR}/id_rsa.pub")"
echo ""

# ============================================================================
# STEP 7: Configure Terraform Provider Mirror (Artifactory)
# ============================================================================
log_info "Step 7: Configuring Terraform provider mirror..."

cat > "${JENKINS_HOME}/.terraformrc" << 'TFRC'
provider_installation {
  network_mirror {
    url = "https://artifactory.cib.echonet/artifactory/api/terraform/terraform-providers/"
  }
  direct {
    exclude = ["registry.terraform.io/*/*"]
  }
}
TFRC

chown "${JENKINS_USER}:${JENKINS_USER}" "${JENKINS_HOME}/.terraformrc"
log_ok "Terraform provider mirror configured."

# ============================================================================
# Summary
# ============================================================================
echo ""
echo "============================================================"
echo " Terraform Agent Setup Complete"
echo "============================================================"
echo ""
echo " Agent Name:  ${AGENT_NAME}"
echo " Agent Label: ${AGENT_LABEL}"
echo " Work Dir:    ${AGENT_WORKDIR}"
echo " Jenkins User: ${JENKINS_USER}"
echo ""
echo " Installed Software:"
echo "   - Java:      $(java -version 2>&1 | head -1)"
echo "   - Terraform: $(terraform version | head -1)"
echo "   - Ansible:   $(ansible --version | head -1)"
echo "   - jq:        $(jq --version)"
echo ""
echo " Next Steps:"
echo "   1. Add SSH public key to Jenkins controller credentials"
echo "   2. In Jenkins: Manage Jenkins -> Nodes -> New Node"
echo "   3. Set name: '${AGENT_NAME}'"
echo "   4. Set label: '${AGENT_LABEL}'"
echo "   5. Set launch method: 'Launch agents via SSH'"
echo "   6. Set remote root directory: '${AGENT_WORKDIR}'"
echo "   7. Save and verify agent comes online"
echo ""
echo "============================================================"
