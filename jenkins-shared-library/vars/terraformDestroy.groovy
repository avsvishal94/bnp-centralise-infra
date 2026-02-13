#!/usr/bin/env groovy
// ============================================================================
// Jenkins Shared Library - Terraform Destroy Step
// ============================================================================
// Reusable step for destroying Terraform-managed infrastructure.
// Part of: jenkins-devops-cicd-library
// ============================================================================

def call(Map config = [:]) {
    def environment       = config.get('environment', 'dev')
    def artifactoryCredId = config.get('artifactoryCredId', 'primedb_cib_artifactory')
    def apigeeCredId      = config.get('apigeeCredId', 'APIGEE_PDB_DEV')
    def confirmDestroy    = config.get('confirm', true)

    if (confirmDestroy) {
        input(
            message: "CONFIRM: Destroy ALL infrastructure in ${environment}?",
            ok: 'Yes, destroy it'
        )
    }

    echo ">>> terraform destroy"
    echo "  - Loading state file from Artifactory"
    echo "  - Executing destruction in ${environment}"

    withCredentials([
        usernamePassword(
            credentialsId: artifactoryCredId,
            usernameVariable: 'USERNAME',
            passwordVariable: 'TF_TOKEN_artifactory_cib_echonet'
        ),
        string(
            credentialsId: apigeeCredId,
            variable: 'IV2_API_KEY'
        )
    ]) {
        sh '''
            export TF_LOG=TRACE

            terraform destroy \
                -input=false \
                -auto-approve

            echo "  - Destruction complete"
            echo "  - State updated in Artifactory"
        '''
    }
}
