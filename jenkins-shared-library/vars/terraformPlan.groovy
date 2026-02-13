#!/usr/bin/env groovy
// ============================================================================
// Jenkins Shared Library - Terraform Plan Step
// ============================================================================
// Reusable step for generating and archiving a Terraform plan.
// Part of: jenkins-devops-cicd-library
// ============================================================================

def call(Map config = [:]) {
    def planFile           = config.get('planFile', "tfplan-${env.BUILD_NUMBER}.out")
    def artifactoryCredId  = config.get('artifactoryCredId', 'primedb_cib_artifactory')
    def archivePlan        = config.get('archive', true)

    echo ">>> terraform plan"
    echo "  - Generate plan file: ${planFile}"
    echo "  - Resource diff"

    withCredentials([
        usernamePassword(
            credentialsId: artifactoryCredId,
            usernameVariable: 'USERNAME',
            passwordVariable: 'TF_TOKEN_artifactory_cib_echonet'
        )
    ]) {
        sh """
            terraform plan \
                -input=false \
                -out=${planFile} \
                -detailed-exitcode || PLAN_EXIT=\$?

            echo "Plan exit code: \${PLAN_EXIT:-0}"
        """
    }

    if (archivePlan) {
        archiveArtifacts artifacts: planFile, fingerprint: true
    }

    return planFile
}
