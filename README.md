# Centralised Infrastructure Pipeline

Terraform-based infrastructure provisioning managed through Jenkins CI/CD with JFrog Artifactory as the remote state backend.

## Pipeline Flow

```
Jenkins (on-prem VM)
      |
Terraform (agent-node)
      |
JFrog Artifactory Backend
      |
terraform-state/<ecosystem>/<app>/<env>/terraform.tfstate
```

## Repository Structure

```
.
├── Environments/
│   ├── shared/                  # Shared Terraform config (provider, backend, modules)
│   │   ├── main.tf              # Provider config, backend, module calls
│   │   ├── variables.tf         # All input variables
│   │   └── locals.tf            # Common locals and tags
│   ├── dev/
│   │   └── terraform.tfvars     # Dev environment overrides
│   ├── stg/
│   │   └── terraform.tfvars     # Staging environment overrides
│   ├── qa/
│   │   └── terraform.tfvars     # QA environment overrides
│   ├── uat/
│   │   └── terraform.tfvars     # UAT environment overrides
│   └── prod/
│       └── terraform.tfvars     # Production environment overrides
├── Modules/
│   ├── apache/                  # Apache HTTPD 2.4 reverse proxy module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── locals.tf
│   └── redhatvm/                # Red Hat VM application server module
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── terraform.tfvars
├── Jenkinsfile                  # CI/CD pipeline definition
├── Jenkinsfile.template         # SRE-managed pipeline template
├── sre_onboard_app.sh           # Application onboarding script
├── .editorconfig
├── .gitignore
└── README.md
```

## Prerequisites

- **Jenkins** on-prem VM with the following plugins:
  - Pipeline Plugin
  - Git Plugin
  - Credentials Plugin
- **Jenkins Agent** with label `terraform-agent` and these tools installed:
  - Terraform >= 1.3.0
  - Ansible
  - jq
- **JFrog Artifactory** accessible from the agent node
- **Jenkins Credentials** configured:

| Credential ID | Type | Purpose |
|---|---|---|
| `primedb_cib_artifactory` | Username/Password | Artifactory access |
| `APIGEE_PDB_DEV` | Secret text | Apigee API key |
| `AIM-PBGBLPRIMEDB-OPSD-Cyberark.cert` | Certificate | CyberArk TLS cert |
| `AIM-PBGBLPRIMEDB-OPSD-Cyberark.key` | Certificate | CyberArk TLS key |
| `CA_Bundle.pem` | Certificate | CyberArk CA bundle |

## How It Works

### State Management

Terraform state is stored in JFrog Artifactory following this path convention:

```
terraform-state/<ecosystem>/<app>/<env>/terraform.tfstate
```

Example:
```
terraform-state/PB-GLOBALPRIMEDB/centralise-infra/dev/terraform.tfstate
terraform-state/PB-GLOBALPRIMEDB/centralise-infra/stg/terraform.tfstate
terraform-state/PB-GLOBALPRIMEDB/centralise-infra/prod/terraform.tfstate
```

The backend is configured at `terraform init` time using `-backend-config` flags, so each environment gets its own isolated state file.

### Pipeline Stages

| Stage | Description |
|---|---|
| **Clone Repo** | Checks out the repository from version control |
| **Terraform Init** | Initialises Terraform with Artifactory backend, downloads providers and modules |
| **Terraform Validate** | Runs `terraform validate` and `terraform fmt -check` |
| **Terraform Plan** | Generates an execution plan using the environment-specific `.tfvars` file |
| **Approval** | Manual approval gate (skippable via `AUTO_APPROVE` parameter) |
| **Terraform Apply** | Applies the plan and stores outputs as build artifacts |
| **Terraform Destroy** | (Conditional) Destroys infrastructure with confirmation prompt |
| **Post-Deployment Validation** | Runs smoke tests and generates a deployment report |

### Environment Configuration

Each environment has its own `terraform.tfvars` under `Environments/<env>/`. The shared Terraform configuration in `Environments/shared/` is used for all environments -- the correct `.tfvars` file is selected at plan time based on the `ENVIRONMENT` pipeline parameter.

## Usage

### Running the Pipeline

1. Navigate to the Jenkins job
2. Click **Build with Parameters**
3. Configure:
   - **ENVIRONMENT**: `dev`, `stg`, `qa`, `uat`, or `prod`
   - **ECOSYSTEM**: `PB-GLOBALPRIMEDB` or `Puma`
   - **ACTION**: `plan` (dry run), `apply` (deploy), or `destroy` (tear down)
   - **APP_NAME**: Application name (used in state path)
   - **AUTO_APPROVE**: Check to skip manual approval (non-production only)
   - **TARGET_BRANCH**: Branch to build from
4. Click **Build**

### Running Locally (for development)

```bash
cd Environments/shared

# Initialise with Artifactory backend
terraform init \
    -backend-config="url=https://artifactory.cib.echonet/artifactory" \
    -backend-config="repo=terraform-state" \
    -backend-config="subpath=PB-GLOBALPRIMEDB/centralise-infra/dev" \
    -backend-config="username=$ARTIFACTORY_USER" \
    -backend-config="password=$ARTIFACTORY_PASSWORD"

# Plan with environment-specific vars
terraform plan -var-file="../dev/terraform.tfvars"

# Apply
terraform apply -var-file="../dev/terraform.tfvars"
```

### Onboarding a New Application

Use the SRE onboarding script to create Artifactory state directories and generate a Jenkinsfile:

```bash
./sre_onboard_app.sh \
    --app-name <application-name> \
    --environments "DEV,STG,QA,UAT,PROD" \
    --ecosystems "PB-GLOBALPRIMEDB,Puma"
```

## Adding a New Module

1. Create a directory under `Modules/<module-name>/`
2. Add `main.tf`, `variables.tf`, `outputs.tf`
3. Reference the module in `Environments/shared/main.tf`
4. Add any required variables to `Environments/shared/variables.tf`
5. Set values in each `Environments/<env>/terraform.tfvars`

## Troubleshooting

| Issue | Resolution |
|---|---|
| `terraform init` fails with 401 | Artifactory credentials expired -- contact SRE |
| `terraform validate` fails | Syntax error in `.tf` files -- fix and re-push |
| Plan shows unexpected changes | State drift -- run `terraform refresh` or contact SRE |
| Approval timeout | Pipeline expires after 60 min -- re-trigger the build |
| State file locked | Concurrent build running -- wait or force-unlock via Artifactory |
| Agent offline | Check agent connectivity under Jenkins > Manage Nodes |
