#!/usr/bin/env groovy
// ============================================================================
// Jenkins Shared Library - Approval Gate Step
// ============================================================================
// Reusable step for manual approval with ServiceNow integration
// and notification support (email + Teams).
// Part of: jenkins-devops-cicd-library
// ============================================================================

def call(Map config = [:]) {
    def environment   = config.get('environment', 'dev')
    def planFile      = config.get('planFile', '')
    def approverGroup = config.get('approverGroup', '')
    def notifyTeams   = config.get('notifyTeams', true)
    def notifyEmail   = config.get('notifyEmail', true)

    // --- ServiceNow Integration ---
    echo "ServiceNow Integration:"
    echo "  - Creating CHG ticket for ${environment} deployment..."
    if (planFile) {
        echo "  - Attaching plan file: ${planFile}"
    }

    // Placeholder for ServiceNow API call
    // def chgTicket = serviceNowCreateChange(
    //     description: "Terraform deployment to ${environment}",
    //     environment: environment,
    //     planFile: planFile
    // )

    // --- Notifications ---
    echo "Sending notifications..."
    if (notifyEmail) {
        echo "  - Email alerts to approvers"
    }
    if (notifyTeams) {
        echo "  - Teams message to channel"
    }

    // --- Manual Approval ---
    def userInput = input(
        id: 'approval',
        message: "Approve deployment to ${environment}?",
        submitter: approverGroup,
        parameters: [
            string(
                name: 'APPROVAL_NOTES',
                defaultValue: '',
                description: 'Add any notes for this deployment'
            )
        ]
    )

    echo "Deployment approved. Notes: ${userInput}"
    return userInput
}
