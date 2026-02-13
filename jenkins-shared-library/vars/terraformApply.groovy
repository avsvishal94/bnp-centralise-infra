#!/usr/bin/env groovy
// ============================================================================
// Jenkins Shared Library - Terraform Apply Step
// ============================================================================
// Reusable step for applying a Terraform plan and capturing outputs.
// Part of: jenkins-devops-cicd-library
// ============================================================================

def call(Map config = [:]) {
    def planFile          = config.get('planFile', "tfplan-${env.BUILD_NUMBER}.out")
    def environment       = config.get('environment', 'dev')
    def artifactoryCredId = config.get('artifactoryCredId', 'primedb_cib_artifactory')
    def apigeeCredId      = config.get('apigeeCredId', 'APIGEE_PDB_DEV')
    def captureOutputs    = config.get('captureOutputs', true)

    echo ">>> terraform apply"
    echo "  - Loading plan file: ${planFile}"
    echo "  - Executing deployment to ${environment}"

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
        sh """
            export TF_LOG=TRACE

            terraform apply \
                -input=false \
                -auto-approve \
                ${planFile}

            echo "  - State updated in Artifactory"
        """

        if (captureOutputs) {
            sh """
                echo ">>> Capturing outputs..."
                terraform output -json > tf-outputs-${environment}.json
                echo "  - Outputs captured"
            """
            archiveArtifacts artifacts: "tf-outputs-${environment}.json", fingerprint: true
        }
    }
}
