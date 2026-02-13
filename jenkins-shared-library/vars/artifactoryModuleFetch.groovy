#!/usr/bin/env groovy
// ============================================================================
// Jenkins Shared Library - Artifactory Module Fetch Step
// ============================================================================
// Reusable step for fetching Terraform modules from Artifactory registry.
// Part of: jenkins-devops-cicd-library
// ============================================================================

def call(Map config = [:]) {
    def artifactoryCredId = config.get('artifactoryCredId', 'primedb_cib_artifactory')
    def targetBranch      = config.get('targetBranch', 'main')

    echo "Fetching Terraform modules from Artifactory..."
    echo "  - Repository: infra-repo"
    echo "  - Branch: ${targetBranch}"

    withCredentials([
        usernamePassword(
            credentialsId: artifactoryCredId,
            usernameVariable: 'USERNAME',
            passwordVariable: 'TF_TOKEN_artifactory_cib_echonet'
        )
    ]) {
        sh '''
            echo "Fetching Terraform modules from Artifactory..."
            echo "Repository: infra-repo"
        '''
    }
}
