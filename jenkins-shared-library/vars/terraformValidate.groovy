#!/usr/bin/env groovy
// ============================================================================
// Jenkins Shared Library - Terraform Validate Step
// ============================================================================
// Reusable step for validating Terraform configuration.
// Runs: terraform validate, terraform fmt -check
// Part of: jenkins-devops-cicd-library
// ============================================================================

def call(Map config = [:]) {
    def checkFormat = config.get('checkFormat', true)

    echo ">>> terraform validate"
    echo "  - Syntax check"
    echo "  - Config validation"

    sh 'terraform validate'

    if (checkFormat) {
        echo "  - Format check"
        sh 'terraform fmt -check -recursive'
    }
}
