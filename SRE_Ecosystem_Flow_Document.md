# SRE Ecosystem – Infrastructure Provisioning with Jenkins CI/CD and Terraform IaC

## Flow Document

---

## 1. Overview

This document describes the end-to-end flow for infrastructure provisioning using a Jenkins CI/CD pipeline integrated with Terraform Infrastructure as Code (IaC). The architecture is split into two major halves: the CI/CD orchestration (left side) and the target infrastructure in a DC/DR setup (right side). Jenkins agents with Terraform installed act as the bridge, executing Terraform commands that provision and manage the infrastructure components.

---

## 2. Architecture Components

### 2.1 Version Control (Bitbucket)

All infrastructure code lives in a Bitbucket repository called `infra-repo`. The team works across three branch types: `main` (production-ready), `develop` (integration), and `feature/*` (development). A webhook trigger fires on every Push or Pull Request, automatically invoking the Jenkins pipeline.

### 2.2 Jenkins CI/CD Orchestration

The Jenkins controller orchestrates the entire pipeline. It runs on agents that have Terraform pre-installed and uses several key plugins: the Terraform Plugin for executing `terraform` commands, Git Plugin for SCM checkout, Pipeline Plugin for declarative/scripted pipelines, and Credentials Plugin for secure secret management. The pipeline accepts choice parameters — `apply` or `destroy` — to determine the execution path.

### 2.3 Jenkins Pipeline Stages (Jenkinsfile)

The pipeline is defined in a Jenkinsfile with six stages:

**Stage 1 — Checkout Code.** The pipeline checks out the target branch from Bitbucket, pulls the Terraform code, and fetches any required modules from the Artifactory module registry.

**Stage 2 — Terraform Initialization and Validation.** This stage runs three sub-steps. First, `terraform init` configures the Artifactory remote backend, downloads the hashicorp/vsphere provider, and initializes modules from Artifactory. Next, `terraform validate` performs syntax checking, configuration validation, and format checking. Finally, `terraform plan` generates a plan file showing the resource diff and archives it as a build artifact for audit.

**Stage 3 — Approval and Change Management.** Before any infrastructure changes are applied, the pipeline pauses for a manual approval gate. An input message asks the operator to approve deployment to the selected environment. In parallel, the pipeline integrates with ServiceNow API to create a CHG (Change) ticket, validate the approval, and attach the plan file. Notifications are sent via email alerts and Microsoft Teams messages to keep stakeholders informed.

**Stage 4 — Terraform Apply (Infrastructure Deployment).** This stage loads the archived plan file and executes the deployment with `terraform apply`. Outputs are captured in JSON format and the state file is updated in Artifactory. This is the stage where the Jenkins agent reaches across to the infrastructure DC/DR and provisions all the components.

**Stage 5 — Terraform Destroy (Conditional).** This stage only executes when the operator selects `destroy` as the action parameter. It loads the plan file and state file, executes `terraform destroy -auto-approve`, captures outputs, and updates the state in Artifactory. An additional confirmation prompt provides a safety gate.

**Stage 6 — Post-Deployment Validation.** After a successful apply, the pipeline runs four validation steps: smoke tests to verify endpoint connectivity, health checks against the load balancer, reverse proxies, and app servers, Ansible configuration for any post-deploy setup, and a deployment report generator that archives the full summary.

### 2.4 Infrastructure — DC/DR (Target Environment)

The right side of the architecture represents the infrastructure that Terraform provisions. Traffic flows from the top down:

**URL Entry Point** — The public or internal URL that routes traffic into the environment.

**NSX-T Firewall** — A network firewall allowing only ports 443 (HTTPS) and 80 (HTTP). This is the security perimeter.

**Load Balancing / Proxy Layer** — An HAProxy load balancer (tagged `terraform-managed`) distributes traffic to two Apache HTTPD 2.4 reverse proxies. Each proxy runs on 1 CPU with configurable RAM. This layer provides SSL termination, request routing, and high availability.

**Application Layer** — Four Java/Dataframe application servers running the `dataframe-webservice` process. Each server is allocated 1 CPU with configurable RAM and disk. The four-server setup ensures horizontal scalability and fault tolerance.

**Storage Layer** — Two NFS servers provide shared storage. The NFS Data Server exports `/mnt/data` for application data, and the NFS Binary Server exports `/mnt/binaries` for application binaries. Both are encrypted at rest with daily backups.

### 2.5 Jenkins Agents (Terraform Installed)

Two dedicated Jenkins agents (`jenkins-agent-1` and `jenkins-agent-2`) execute the Terraform commands. Each agent has the `hashicorp/vsphere` Terraform provider configured (for VMware vSphere infrastructure) along with `terraform`, `ansible`, and `jq` installed. These agents are the execution bridge between the Jenkins pipeline and the target infrastructure.

---

## 3. End-to-End Flow

A developer pushes code to the `infra-repo` on Bitbucket. The webhook triggers Jenkins. The pipeline checks out the code, initializes Terraform with the Artifactory backend, validates the configuration, and generates a plan. The plan is archived and a ServiceNow change ticket is created. After manual approval and team notification, Terraform applies the plan through a Jenkins agent, provisioning the full stack: firewall rules, load balancer, reverse proxies, application servers, and NFS storage. Post-deployment validation confirms everything is healthy, and a report is generated.

For teardown, the operator triggers the pipeline with `destroy` selected. After confirmation, Terraform destroys all provisioned resources and updates the state.

---

## 4. Infrastructure Resources Provisioned

| Component | Quantity | Technology | Specs |
|-----------|----------|------------|-------|
| NSX-T Firewall | 1 | NSX-T | Ports 443, 80 |
| Load Balancer | 1 | HAProxy | 1 CPU, configurable RAM |
| Reverse Proxy | 2 | Apache HTTPD 2.4 | 1 CPU, configurable RAM |
| App Server | 4 | Java/Dataframe | 1 CPU, configurable RAM/Disk |
| NFS Data Server | 1 | NFS | /mnt/data, encrypted, daily backup |
| NFS Binary Server | 1 | NFS | /mnt/binaries, encrypted, daily backup |
| Jenkins Agent | 2 | Terraform/Ansible/jq | hashicorp/vsphere provider |

---

## 5. Security Model

All credentials flow through Jenkins Credential Store backed by CyberArk. The NSX-T firewall restricts ingress to ports 443 and 80 only. NFS storage is encrypted at rest. The pipeline enforces manual approval gates and ServiceNow change management before any production changes. Terraform state files are stored securely in Artifactory with locking to prevent concurrent modifications.

---

## 6. Files and Artifacts

| File | Purpose | Owner |
|------|---------|-------|
| `Jenkinsfile.template` | Master pipeline template with 6 stages | SRE |
| `sre_onboard_app.sh` | Onboarding automation script | SRE |
| `Jenkinsfile` (generated) | Application-specific pipeline | SRE (generated) |
| `*.tf` files | Terraform infrastructure definitions | Application Team |
| `tfplan-*.out` | Archived plan files per build | Pipeline (auto) |
| `tf-outputs-*.json` | Terraform output captures | Pipeline (auto) |
| `deployment-report-*.txt` | Post-deployment validation report | Pipeline (auto) |
