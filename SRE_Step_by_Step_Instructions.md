# SRE Ecosystem – Step-by-Step Instructions

## Infrastructure Provisioning Pipeline – Setup and Usage Guide

---

## Part A: SRE Team – Initial Setup and Onboarding

### Step 1: Prepare Jenkins Agents

Provision two Jenkins agent nodes (`jenkins-agent-1`, `jenkins-agent-2`) with the following installations:

```bash
# Install Terraform
wget https://releases.hashicorp.com/terraform/<version>/terraform_<version>_linux_amd64.zip
unzip terraform_<version>_linux_amd64.zip -d /usr/local/bin/

# Install Ansible
pip install ansible

# Install jq
apt-get install -y jq

# Configure vSphere provider
# Ensure ~/.terraformrc has Artifactory as provider mirror
```

Verify each agent is registered in Jenkins under **Manage Jenkins → Nodes** with the label `terraform-agent`.

---

### Step 2: Create Statefile Directories in Artifactory

Run the onboarding script for each application:

```bash
export ARTIFACTORY_API_KEY="your-api-key"

./sre_onboard_app.sh \
  --app-name <application-name> \
  --environments "DEV,STG,PT,QA" \
  --ecosystems "PB-GLOBALPRIMEDB,Puma" \
  --artifactory-url "https://artifactory.cib.echonet/artifactory"
```

This creates:
```
terraform-statefiles/
└── <application-name>/
    ├── dev/
    ├── stg/
    ├── pt/
    └── qa/
```

---

### Step 3: Configure Jenkins Credentials

Add the following credentials in Jenkins (**Manage Jenkins → Credentials**):

| Credential ID | Type | Description |
|---------------|------|-------------|
| `AIM-PBGBLPRIMEDB-OPSD-Cyberark.cert` | Certificate | CyberArk TLS certificate |
| `AIM-PBGBLPRIMEDB-OPSD-Cyberark.key` | Certificate | CyberArk TLS private key |
| `CA_Bundle.pem` | Certificate | CyberArk CA bundle |
| `primedb_cib_artifactory` | Username/Password | Artifactory service account |
| `APIGEE_PDB_DEV` | Secret text | Apigee API key |

---

### Step 4: Generate and Push the Jenkinsfile

```bash
./sre_onboard_app.sh \
  --app-name <application-name> \
  --environments "DEV,STG,PT,QA" \
  --ecosystems "PB-GLOBALPRIMEDB,Puma" \
  --repo-url "ssh://git@bitbucket.cib.echonet/<PROJECT>/<REPO>.git" \
  --push
```

Alternatively, copy the generated `Jenkinsfile` manually into the application repo root and push via PR.

---

### Step 5: Create Jenkins Pipeline Job

1. In Jenkins, create a **Multibranch Pipeline** job
2. Set **Branch Source** → Bitbucket with the repo URL
3. Set **Build Configuration** → by Jenkinsfile (path: `Jenkinsfile`)
4. Under **Scan Repository Triggers**, enable webhook-based scanning
5. Configure Bitbucket webhook to point to `https://<jenkins-url>/bitbucket-scmsource-hook/notify`

---

### Step 6: Configure ServiceNow Integration (Optional)

If using the Stage 3 ServiceNow approval flow, configure the ServiceNow Jenkins plugin or REST API credentials. Update the Jenkinsfile template placeholders for `{{APPROVER_GROUP}}` and ServiceNow API endpoint.

---

## Part B: Application Team – Using the Pipeline

### Step 1: Write Your Terraform Files

In the `infra-repo`, create or modify these files:

**`backend.tf`** — Remote backend configuration:
```hcl
terraform {
  backend "artifactory" {
    url     = "https://artifactory.cib.echonet/artifactory"
    repo    = "terraform-statefiles"
    subpath = "<app-name>/${var.env}"
  }

  required_providers {
    vsphere = {
      source  = "hashicorp/vsphere"
      version = "~> 2.0"
    }
  }
}
```

**`variables.tf`** — Pipeline-injected variables:
```hcl
variable "env" {
  description = "Target environment (dev, stg, pt, qa)"
  type        = string
}

variable "ecosystem" {
  description = "Ecosystem name"
  type        = string
}
```

**`main.tf`** — Infrastructure resource definitions (example):
```hcl
# Load Balancer - HAProxy
resource "vsphere_virtual_machine" "lb" {
  name   = "lb-${var.env}"
  num_cpus = 1
  memory   = var.lb_memory_mb
  # ... vsphere configuration
}

# Reverse Proxies - Apache HTTPD 2.4
resource "vsphere_virtual_machine" "reverse_proxy" {
  count  = 2
  name   = "rp-${count.index + 1}-${var.env}"
  num_cpus = 1
  memory   = var.rp_memory_mb
  # ... vsphere configuration
}

# App Servers - Java/Dataframe
resource "vsphere_virtual_machine" "app_server" {
  count  = 4
  name   = "app-${count.index + 1}-${var.env}"
  num_cpus = 1
  memory   = var.app_memory_mb
  # ... vsphere configuration
}

# NFS Data Server
resource "vsphere_virtual_machine" "nfs_data" {
  name   = "nfs-data-${var.env}"
  # ... NFS mount /mnt/data
}

# NFS Binary Server
resource "vsphere_virtual_machine" "nfs_binaries" {
  name   = "nfs-bin-${var.env}"
  # ... NFS mount /mnt/binaries
}

# NSX-T Firewall Rules
resource "nsxt_policy_security_policy" "firewall" {
  display_name = "fw-${var.env}"
  rule {
    display_name       = "allow-https"
    destination_groups = [/* app servers */]
    services           = ["HTTPS", "HTTP"]
    action             = "ALLOW"
  }
}
```

**`outputs.tf`** — Captured by the pipeline:
```hcl
output "lb_ip" {
  value = vsphere_virtual_machine.lb.default_ip_address
}

output "app_server_ips" {
  value = vsphere_virtual_machine.app_server[*].default_ip_address
}
```

---

### Step 2: Push Code and Trigger Pipeline

```bash
git checkout -b feature/infra-setup
git add *.tf
git commit -m "feat: add infrastructure definitions for dataframe-webservice"
git push origin feature/infra-setup
```

The webhook automatically triggers the Jenkins pipeline. Alternatively, merge to `develop` or `main` to trigger for those branches.

---

### Step 3: Run the Pipeline (Build with Parameters)

1. Navigate to your Jenkins job
2. Click **"Build with Parameters"**
3. Fill in:
   - **ENVIRONMENT**: `DEV`, `STG`, `PT`, or `QA`
   - **ECOSYSTEM**: `PB-GLOBALPRIMEDB` or `Puma`
   - **ACTION**: `apply` (deploy) or `destroy` (tear down)
   - **AUTO_APPROVE**: Leave unchecked for production (enables Stage 3 approval gate)
   - **TARGET_BRANCH**: `main`, `develop`, or `feature/*`
4. Click **"Build"**

---

### Step 4: Monitor the 6 Pipeline Stages

| Stage | What Happens | Action Required |
|-------|-------------|-----------------|
| **1. Checkout Code** | Git checkout, module fetch | None (automatic) |
| **2. TF Init & Validate** | init → validate → plan | Review plan in archived artifacts |
| **3. Approval & Change Mgmt** | ServiceNow ticket, approval prompt | **Click "Approve"** in Jenkins |
| **4. TF Apply** | Infrastructure deployed | Monitor console output |
| **5. TF Destroy** | (Only if action=destroy) | **Confirm destruction** |
| **6. Post-Deployment** | Smoke tests, health checks, report | Review archived report |

---

### Step 5: Verify Deployment

After Stage 6 completes, check:

1. **Deployment Report** — Download from Jenkins build artifacts
2. **Terraform Outputs** — Check `tf-outputs-<env>.json` for IP addresses and resource IDs
3. **Application URL** — Verify the URL is accessible through the NSX-T firewall
4. **Health Endpoints** — Confirm load balancer, proxies, and app servers are responding
5. **NFS Mounts** — Verify `/mnt/data` and `/mnt/binaries` are accessible from app servers

---

### Step 6: Destroying Infrastructure

1. Trigger pipeline with **ACTION** = `destroy`
2. Select the correct **ENVIRONMENT**
3. Confirm the destruction prompt
4. Verify state file is updated in Artifactory (empty state = all resources destroyed)

---

## Troubleshooting

| Issue | Resolution |
|-------|------------|
| `terraform init` fails with 401 | Artifactory credential expired — contact SRE |
| `terraform validate` fails | Syntax error in `.tf` files — fix and re-push |
| `terraform plan` shows unexpected changes | State drift — run `terraform refresh` or contact SRE |
| Stage 3 approval timeout | Pipeline expires after 60 min — re-trigger the build |
| ServiceNow ticket not created | Check ServiceNow API credentials and connectivity |
| Health checks fail in Stage 6 | Infrastructure may need time to boot — check VM status in vSphere |
| Agent offline | Check `jenkins-agent-1` / `jenkins-agent-2` connectivity |
| NFS mount fails | Verify NFS server is provisioned and firewall allows NFS ports |
| State file locked | Concurrent build in progress — wait or force-unlock via Artifactory |

---

## Contact

For pipeline issues, credential rotation, agent provisioning, or onboarding: contact the **SRE Ecosystem team**.
