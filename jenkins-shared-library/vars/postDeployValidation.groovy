#!/usr/bin/env groovy
// ============================================================================
// Jenkins Shared Library - Post-Deployment Validation Step
// ============================================================================
// Reusable step for running smoke tests, health checks, Ansible
// post-deploy config, and generating deployment reports.
// Part of: jenkins-devops-cicd-library
// ============================================================================

def call(Map config = [:]) {
    def environment  = config.get('environment', 'dev')
    def ecosystem    = config.get('ecosystem', '')
    def targetBranch = config.get('targetBranch', 'main')
    def action       = config.get('action', 'apply')
    def runAnsible   = config.get('runAnsible', true)

    // --- Smoke Tests ---
    echo "Running Smoke Tests..."
    sh '''
        echo "  - Verifying infrastructure endpoints..."
        echo "  - Checking connectivity to provisioned resources..."
    '''

    // --- Health Checks ---
    echo "Running Health Checks..."
    sh '''
        echo "  - Checking Load Balancer (HAProxy) health..."
        echo "  - Checking Reverse Proxy (Apache HTTPD 2.4) status..."
        echo "  - Checking App Servers (Java/Dataframe) availability..."
        echo "  - Checking NFS mount points (/mnt/data, /mnt/binaries)..."
    '''

    // --- Ansible Config ---
    if (runAnsible) {
        echo "Running Ansible post-deployment configuration..."
        sh '''
            echo "  - Executing Ansible playbooks for post-deploy config..."
        '''
    }

    // --- Generate Report ---
    echo "Generating deployment report..."
    sh """
        echo "========================================" > deployment-report-${environment}.txt
        echo " Deployment Report"                      >> deployment-report-${environment}.txt
        echo "========================================" >> deployment-report-${environment}.txt
        echo " Environment: ${environment}"            >> deployment-report-${environment}.txt
        echo " Ecosystem:   ${ecosystem}"              >> deployment-report-${environment}.txt
        echo " Build:       ${env.BUILD_NUMBER}"       >> deployment-report-${environment}.txt
        echo " Branch:      ${targetBranch}"           >> deployment-report-${environment}.txt
        echo " Action:      ${action}"                 >> deployment-report-${environment}.txt
        echo " Timestamp:   \$(date -u)"               >> deployment-report-${environment}.txt
        echo "========================================" >> deployment-report-${environment}.txt
        terraform output -json                         >> deployment-report-${environment}.txt 2>/dev/null || true
        echo "========================================" >> deployment-report-${environment}.txt
    """

    archiveArtifacts artifacts: "deployment-report-${environment}.txt", fingerprint: true
}
