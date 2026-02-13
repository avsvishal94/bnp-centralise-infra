#!/usr/bin/env groovy
// ============================================================================
// Jenkins Shared Library - Terraform Init Step
// ============================================================================
// Reusable step for initializing Terraform with Artifactory backend.
// Part of: jenkins-devops-cicd-library
// ============================================================================

def call(Map config = [:]) {
    def artifactoryCredId = config.get('artifactoryCredId', 'primedb_cib_artifactory')
    def backendEnabled    = config.get('backend', true)

    echo ">>> terraform init"
    echo "  - Backend config: Artifactory"
    echo "  - Provider download: hashicorp/vsphere"
    echo "  - Module init from Artifactory"

    withCredentials([
        usernamePassword(
            credentialsId: artifactoryCredId,
            usernameVariable: 'USERNAME',
            passwordVariable: 'TF_TOKEN_artifactory_cib_echonet'
        )
    ]) {
        sh """
            terraform init \
                -backend=${backendEnabled} \
                -input=false
        """
    }
}
