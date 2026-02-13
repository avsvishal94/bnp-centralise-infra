# SRE Ecosystem – Step-by-Step Instructions

## Infrastructure Provisioning Pipeline – Setup and Usage Guide

---

## Part A: SRE Team – Initial Setup and Onboarding

### Step 1: Provision Terraform Agents

Use the agent setup script to provision Jenkins worker nodes from a Marketplace VM image:

```bash
sudo ./terraform-agent/setup-agent.sh \
  --jenkins-url "https://jenkins.cib.echonet" \
  --agent-name "jenkins-agent-1" \
  --terraform-version "1.7.5"
```

The script performs the following:
1. Installs system prerequisites (curl, wget, git, openssh-server)
2. Installs Java (OpenJDK 17) for Jenkins agent communication
3. Installs Terraform (pinned version)
4. Installs Ansible and jq
5. Creates `jenkins` user with SSH access
6. Configures SSH-based Jenkins agent connectivity
7. Sets up Artifactory as Terraform provider mirror (`~/.terraformrc`)

Repeat for each agent (`jenkins-agent-1`, `jenkins-agent-2`). Verify each agent is registered in Jenkins under **Manage Jenkins -> Nodes** with the label `terraform-agent`.

---

### Step 2: Deploy Jenkins Shared Library

The shared library (`jenkins-shared-library/`) must be configured in Jenkins:

1. Push the `jenkins-shared-library/` directory to a Bitbucket repo (e.g., `jenkins-devops-cicd-library`)
2. In Jenkins: **Manage Jenkins -> System -> Global Pipeline Libraries**
3. Add a new library:
   - **Name**: `jenkins-devops-cicd-library`
   - **Default version**: `main`
   - **Retrieval method**: Modern SCM -> Git
   - **Project Repository**: `ssh://git@bitbucket.cib.echonet/SRE/jenkins-devops-cicd-library.git`

Available shared library steps:

| Step | File | Purpose |
|------|------|---------|
| `terraformInit` | `vars/terraformInit.groovy` | Initialize Terraform with Artifactory backend |
| `terraformValidate` | `vars/terraformValidate.groovy` | Validate and format-check configuration |
| `terraformPlan` | `vars/terraformPlan.groovy` | Generate and archive execution plan |
| `terraformApply` | `vars/terraformApply.groovy` | Apply plan, capture outputs |
| `terraformDestroy` | `vars/terraformDestroy.groovy` | Destroy infrastructure with confirmation |
| `cyberarkCredentials` | `vars/cyberarkCredentials.groovy` | Load CyberArk certs into pipeline |
| `approvalGate` | `vars/approvalGate.groovy` | Manual approval + ServiceNow |
| `postDeployValidation` | `vars/postDeployValidation.groovy` | Smoke tests, health checks, reports |
| `artifactoryModuleFetch` | `vars/artifactoryModuleFetch.groovy` | Fetch modules from Artifactory |

---

### Step 3: Publish Terraform Modules to Artifactory

Upload the reusable Terraform modules to Artifactory:

```bash
# Package and upload each module
cd terraform-modules/modules/
for module in vsphere-vm haproxy-lb nsx-firewall nfs-server; do
  tar -czf "${module}-v1.0.0.tar.gz" "${module}/"
  curl -X PUT \
    -H "X-JFrog-Art-Api: ${ARTIFACTORY_API_KEY}" \
    -T "${module}-v1.0.0.tar.gz" \
    "https://artifactory.cib.echonet/artifactory/terraform-modules/${module}/v1.0.0/${module}-v1.0.0.tar.gz"
done
```

Available modules:
- `vsphere-vm` — Base VM provisioning (datacenter, datastore, cluster, network, template)
- `haproxy-lb` — HAProxy load balancer (wraps vsphere-vm, single instance)
- `nsx-firewall` — NSX-T security policies (HTTPS/HTTP allow, deny-all default)
- `nfs-server` — NFS storage server (data or binaries type, wraps vsphere-vm)

---

### Step 4: Create Statefile Directories in Artifactory

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

### Step 5: Configure Jenkins Credentials

Add the following credentials in Jenkins (**Manage Jenkins -> Credentials**):

| Credential ID | Type | Description |
|---------------|------|-------------|
| `AIM-PBGBLPRIMEDB-OPSD-Cyberark.cert` | Certificate | CyberArk TLS certificate |
| `AIM-PBGBLPRIMEDB-OPSD-Cyberark.key` | Certificate | CyberArk TLS private key |
| `CA_Bundle.pem` | Certificate | CyberArk CA bundle |
| `primedb_cib_artifactory` | Username/Password | Artifactory service account |
| `APIGEE_PDB_DEV` | Secret text | Apigee API key |

---

### Step 6: Generate and Push the Jenkinsfile

```bash
./sre_onboard_app.sh \
  --app-name <application-name> \
  --environments "DEV,STG,PT,QA" \
  --ecosystems "PB-GLOBALPRIMEDB,Puma" \
  --repo-url "ssh://git@bitbucket.cib.echonet/<PROJECT>/<REPO>.git" \
  --push
```

This generates:
- `generated/Jenkinsfile` — Pipeline using shared library steps
- `generated/terraform/` — Sample Terraform files with app name substituted

Use `--no-sample-tf` to skip copying sample Terraform files.

Alternatively, copy the generated files manually into the application repo root and push via PR.

---

### Step 7: Create Jenkins Pipeline Job

1. In Jenkins, create a **Multibranch Pipeline** job
2. Set **Branch Source** -> Bitbucket with the repo URL
3. Set **Build Configuration** -> by Jenkinsfile (path: `Jenkinsfile`)
4. Under **Scan Repository Triggers**, enable webhook-based scanning
5. Configure Bitbucket webhook to point to `https://<jenkins-url>/bitbucket-scmsource-hook/notify`

---

### Step 8: Configure ServiceNow Integration (Optional)

If using the Stage 3 ServiceNow approval flow, configure the ServiceNow Jenkins plugin or REST API credentials. Update the Jenkinsfile template placeholders for `{{APPROVER_GROUP}}` and ServiceNow API endpoint.

---

## Part B: Application Team – Using the Pipeline

### Step 1: Write Your Terraform Files

Use the sample files from `sample-app-terraform/` as a starting point, or write your own.

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
    nsxt = {
      source  = "vmware/nsxt"
      version = "~> 3.0"
    }
  }
}
```

**`main.tf`** — Use SRE-managed modules from Artifactory:
```hcl
module "firewall" {
  source      = "artifactory.cib.echonet/artifactory/terraform-modules/modules/nsx-firewall"
  app_name    = var.app_name
  environment = var.env
  ecosystem   = var.ecosystem
}

module "load_balancer" {
  source      = "artifactory.cib.echonet/artifactory/terraform-modules/modules/haproxy-lb"
  app_name    = var.app_name
  environment = var.env
  ecosystem   = var.ecosystem
  # ... vSphere config
}

module "app_servers" {
  source         = "artifactory.cib.echonet/artifactory/terraform-modules/modules/vsphere-vm"
  name_prefix    = "app-${var.app_name}"
  environment    = var.env
  ecosystem      = var.ecosystem
  instance_count = 4
  # ... vSphere config
}
```

**`outputs.tf`** — Captured by the pipeline:
```hcl
output "lb_ip" {
  value = module.load_balancer.lb_ip
}

output "app_server_ips" {
  value = module.app_servers.vm_ip_addresses
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
| **1. Checkout Code** | Git checkout, module fetch via `artifactoryModuleFetch` | None (automatic) |
| **2. TF Init & Validate** | `terraformInit` -> `terraformValidate` -> `terraformPlan` | Review plan in archived artifacts |
| **3. Approval & Change Mgmt** | `approvalGate` with ServiceNow ticket, approval prompt | **Click "Approve"** in Jenkins |
| **4. TF Apply** | `terraformApply` — Infrastructure deployed | Monitor console output |
| **5. TF Destroy** | `terraformDestroy` (Only if action=destroy) | **Confirm destruction** |
| **6. Post-Deployment** | `postDeployValidation` — Smoke tests, health checks, report | Review archived report |

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
| Module not found | Verify module is published to Artifactory registry |
| Shared library step fails | Check library version in Jenkins Global Pipeline Libraries config |

---

## Contact

For pipeline issues, credential rotation, agent provisioning, or onboarding: contact the **SRE Ecosystem team**.
