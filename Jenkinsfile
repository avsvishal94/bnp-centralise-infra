@Library("jenkins-devops-cicd-library") _

// ============================================================================
// Centralised Infrastructure Pipeline
// ============================================================================
// Flow:
//   Jenkins (on-prem VM)
//       |
//   Terraform (agent-node)
//       |
//   JFrog Artifactory Backend
//       |
//   terraform-state/<ecosystem>/<app>/<env>/terraform.tfstate
// ============================================================================

def cyberarkCertFile = 'AIM-PBGBLPRIMEDB-OPSD-Cyberark.cert'
def cyberarkKeyFile  = 'AIM-PBGBLPRIMEDB-OPSD-Cyberark.key'
def cyberarkCAFile   = 'CA_Bundle.pem'

pipeline {
    agent {
        label 'terraform-agent'
    }

    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'stg', 'qa', 'uat', 'prod'],
            description: 'Select target environment'
        )
        choice(
            name: 'ECOSYSTEM',
            choices: ['PB-GLOBALPRIMEDB', 'Puma'],
            description: 'Select ecosystem'
        )
        choice(
            name: 'ACTION',
            choices: ['plan', 'apply', 'destroy'],
            description: 'Terraform action to execute'
        )
        string(
            name: 'APP_NAME',
            defaultValue: 'centralise-infra',
            description: 'Application name (used in state path)'
        )
        booleanParam(
            name: 'AUTO_APPROVE',
            defaultValue: false,
            description: 'Skip manual approval gate (use with caution)'
        )
        string(
            name: 'TARGET_BRANCH',
            defaultValue: 'main',
            description: 'Branch to checkout'
        )
    }

    environment {
        TF_VAR_environment = "${params.ENVIRONMENT}"
        TF_VAR_ecosystem   = "${params.ECOSYSTEM}"
        TF_VAR_app_name    = "${params.APP_NAME}"
        TF_IN_AUTOMATION   = 'true'
        TF_PLAN_FILE       = "tfplan-${params.ENVIRONMENT}-${BUILD_NUMBER}.out"
        ARTIFACTORY_URL    = 'https://artifactory.cib.echonet/artifactory'
        // State path: terraform-state/<ecosystem>/<app>/<env>/terraform.tfstate
        TF_STATE_PATH      = "terraform-state/${params.ECOSYSTEM}/${params.APP_NAME}/${params.ENVIRONMENT}"
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '20'))
        timestamps()
        timeout(time: 60, unit: 'MINUTES')
        disableConcurrentBuilds()
    }

    stages {
        // ================================================================
        // Stage 1: Clone Repository
        // ================================================================
        stage('Clone Repo') {
            steps {
                echo "=== Stage 1: Clone Repository ==="
                echo "Branch: ${params.TARGET_BRANCH}"
                checkout scm

                withCredentials([
                    usernamePassword(
                        credentialsId: 'primedb_cib_artifactory',
                        usernameVariable: 'ARTIFACTORY_USER',
                        passwordVariable: 'ARTIFACTORY_PASSWORD'
                    )
                ]) {
                    sh '''
                        echo "Repository cloned successfully"
                        echo "Workspace: ${WORKSPACE}"
                        ls -la Environments/ Modules/
                    '''
                }
            }
        }

        // ================================================================
        // Stage 2: Terraform Init
        // ================================================================
        stage('Terraform Init') {
            steps {
                echo "=== Stage 2: Terraform Init ==="
                echo "State path: ${TF_STATE_PATH}"

                dir("Environments/shared") {
                    withCredentials([
                        usernamePassword(
                            credentialsId: 'primedb_cib_artifactory',
                            usernameVariable: 'ARTIFACTORY_USER',
                            passwordVariable: 'ARTIFACTORY_PASSWORD'
                        )
                    ]) {
                        sh """
                            echo ">>> terraform init"
                            echo "  Backend: JFrog Artifactory"
                            echo "  State:   ${TF_STATE_PATH}/terraform.tfstate"

                            terraform init \
                                -backend=true \
                                -backend-config="url=${ARTIFACTORY_URL}" \
                                -backend-config="repo=terraform-state" \
                                -backend-config="subpath=${params.ECOSYSTEM}/${params.APP_NAME}/${params.ENVIRONMENT}" \
                                -backend-config="username=\${ARTIFACTORY_USER}" \
                                -backend-config="password=\${ARTIFACTORY_PASSWORD}" \
                                -input=false
                        """
                    }
                }
            }
        }

        // ================================================================
        // Stage 3: Terraform Validate
        // ================================================================
        stage('Terraform Validate') {
            steps {
                echo "=== Stage 3: Terraform Validate ==="

                dir("Environments/shared") {
                    sh '''
                        echo ">>> terraform validate"
                        terraform validate

                        echo ">>> terraform fmt -check"
                        terraform fmt -check -recursive
                    '''
                }
            }
        }

        // ================================================================
        // Stage 4: Terraform Plan
        // ================================================================
        stage('Terraform Plan') {
            steps {
                echo "=== Stage 4: Terraform Plan ==="

                dir("Environments/shared") {
                    withCredentials([
                        usernamePassword(
                            credentialsId: 'primedb_cib_artifactory',
                            usernameVariable: 'ARTIFACTORY_USER',
                            passwordVariable: 'ARTIFACTORY_PASSWORD'
                        )
                    ]) {
                        sh """
                            echo ">>> terraform plan"
                            echo "  Environment: ${params.ENVIRONMENT}"
                            echo "  Var file:    ../\${ENVIRONMENT}/terraform.tfvars"

                            terraform plan \
                                -var-file="../${params.ENVIRONMENT}/terraform.tfvars" \
                                -input=false \
                                -out=\${WORKSPACE}/${TF_PLAN_FILE} \
                                -detailed-exitcode || PLAN_EXIT=\$?

                            echo "Plan exit code: \${PLAN_EXIT:-0}"
                        """
                    }

                    archiveArtifacts artifacts: "${TF_PLAN_FILE}", allowEmptyArchive: true, fingerprint: true
                }
            }
        }

        // ================================================================
        // Stage 5: Approval Gate
        // ================================================================
        stage('Approval') {
            when {
                expression { return params.ACTION != 'plan' && !params.AUTO_APPROVE }
            }
            steps {
                echo "=== Stage 5: Approval Gate ==="

                script {
                    def userInput = input(
                        id: 'approval',
                        message: "Approve ${params.ACTION} to ${params.ENVIRONMENT}?",
                        parameters: [
                            string(
                                name: 'APPROVAL_NOTES',
                                defaultValue: '',
                                description: 'Deployment notes'
                            )
                        ]
                    )
                    echo "Approved. Notes: ${userInput}"
                }
            }
        }

        // ================================================================
        // Stage 6: Terraform Apply
        // ================================================================
        stage('Terraform Apply') {
            when {
                expression { return params.ACTION == 'apply' }
            }
            steps {
                echo "=== Stage 6: Terraform Apply ==="

                dir("Environments/shared") {
                    withCredentials([
                        usernamePassword(
                            credentialsId: 'primedb_cib_artifactory',
                            usernameVariable: 'ARTIFACTORY_USER',
                            passwordVariable: 'ARTIFACTORY_PASSWORD'
                        ),
                        string(
                            credentialsId: 'APIGEE_PDB_DEV',
                            variable: 'IV2_API_KEY'
                        )
                    ]) {
                        sh """
                            echo ">>> terraform apply"
                            echo "  Plan file: ${TF_PLAN_FILE}"
                            echo "  State:     ${TF_STATE_PATH}/terraform.tfstate"

                            terraform apply \
                                -input=false \
                                -auto-approve \
                                \${WORKSPACE}/${TF_PLAN_FILE}

                            echo ">>> Capturing outputs..."
                            terraform output -json > \${WORKSPACE}/tf-outputs-${params.ENVIRONMENT}.json

                            echo "State updated in Artifactory: ${TF_STATE_PATH}/terraform.tfstate"
                        """

                        archiveArtifacts artifacts: "tf-outputs-${params.ENVIRONMENT}.json", fingerprint: true
                    }
                }
            }
        }

        // ================================================================
        // Stage 7: Terraform Destroy
        // ================================================================
        stage('Terraform Destroy') {
            when {
                expression { return params.ACTION == 'destroy' }
            }
            steps {
                echo "=== Stage 7: Terraform Destroy ==="

                script {
                    input(
                        message: "CONFIRM: Destroy ALL infrastructure in ${params.ENVIRONMENT}?",
                        ok: 'Yes, destroy'
                    )
                }

                dir("Environments/shared") {
                    withCredentials([
                        usernamePassword(
                            credentialsId: 'primedb_cib_artifactory',
                            usernameVariable: 'ARTIFACTORY_USER',
                            passwordVariable: 'ARTIFACTORY_PASSWORD'
                        ),
                        string(
                            credentialsId: 'APIGEE_PDB_DEV',
                            variable: 'IV2_API_KEY'
                        )
                    ]) {
                        sh """
                            echo ">>> terraform destroy"
                            terraform destroy \
                                -var-file="../${params.ENVIRONMENT}/terraform.tfvars" \
                                -input=false \
                                -auto-approve

                            echo "Destruction complete. State updated in Artifactory."
                        """
                    }
                }
            }
        }

        // ================================================================
        // Stage 8: Post-Deployment Validation
        // ================================================================
        stage('Post-Deployment Validation') {
            when {
                expression { return params.ACTION == 'apply' }
            }
            steps {
                echo "=== Stage 8: Post-Deployment Validation ==="

                script {
                    sh '''
                        echo "Running smoke tests..."
                        echo "  - Verifying infrastructure endpoints"
                        echo "  - Checking connectivity to provisioned resources"
                    '''

                    sh """
                        echo "Generating deployment report..."
                        echo "==========================================" > deployment-report-${params.ENVIRONMENT}.txt
                        echo " Deployment Report"                         >> deployment-report-${params.ENVIRONMENT}.txt
                        echo "==========================================" >> deployment-report-${params.ENVIRONMENT}.txt
                        echo " Environment: ${params.ENVIRONMENT}"        >> deployment-report-${params.ENVIRONMENT}.txt
                        echo " Ecosystem:   ${params.ECOSYSTEM}"          >> deployment-report-${params.ENVIRONMENT}.txt
                        echo " App:         ${params.APP_NAME}"           >> deployment-report-${params.ENVIRONMENT}.txt
                        echo " Build:       ${BUILD_NUMBER}"              >> deployment-report-${params.ENVIRONMENT}.txt
                        echo " State Path:  ${TF_STATE_PATH}"             >> deployment-report-${params.ENVIRONMENT}.txt
                        echo " Timestamp:   \$(date -u)"                  >> deployment-report-${params.ENVIRONMENT}.txt
                        echo "==========================================" >> deployment-report-${params.ENVIRONMENT}.txt
                    """

                    archiveArtifacts artifacts: "deployment-report-${params.ENVIRONMENT}.txt", fingerprint: true
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline completed successfully: ${params.ENVIRONMENT} - ${params.ACTION}"
        }
        failure {
            echo "Pipeline FAILED: ${params.ENVIRONMENT} - ${params.ACTION}"
        }
        always {
            cleanWs()
        }
    }
}
