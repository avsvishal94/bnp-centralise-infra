package org.sre.ecosystem

// ============================================================================
// Jenkins Shared Library - Terraform Helper Class
// ============================================================================
// Utility class providing common Terraform operations and configuration
// helpers for the SRE Ecosystem pipeline.
// Part of: jenkins-devops-cicd-library
// ============================================================================

class TerraformHelper implements Serializable {

    def script

    TerraformHelper(script) {
        this.script = script
    }

    String getStatefilePath(String appName, String environment) {
        return "terraform-statefiles/${appName}/${environment.toLowerCase()}/"
    }

    String getPlanFileName(String environment, String buildNumber) {
        return "tfplan-${environment}-${buildNumber}.out"
    }

    String getOutputFileName(String environment) {
        return "tf-outputs-${environment}.json"
    }

    String getReportFileName(String environment) {
        return "deployment-report-${environment}.txt"
    }

    Map getBackendConfig(String appName, String environment, String artifactoryUrl) {
        return [
            url    : artifactoryUrl,
            repo   : 'terraform-statefiles',
            subpath: "${appName}/${environment.toLowerCase()}"
        ]
    }
}
