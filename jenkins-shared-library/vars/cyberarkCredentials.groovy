#!/usr/bin/env groovy
// ============================================================================
// Jenkins Shared Library - CyberArk Credentials Helper
// ============================================================================
// Reusable step for loading CyberArk certificates and keys from Jenkins
// credential store. Provides a closure-based wrapper for credential injection.
// Part of: jenkins-devops-cicd-library
// ============================================================================

def call(Map config = [:], Closure body) {
    def certId   = config.get('certId', 'AIM-PBGBLPRIMEDB-OPSD-Cyberark.cert')
    def keyId    = config.get('keyId', 'AIM-PBGBLPRIMEDB-OPSD-Cyberark.key')
    def caBundle = config.get('caBundle', 'CA_Bundle.pem')

    echo "Loading CyberArk credentials..."
    echo "  - Certificate: ${certId}"
    echo "  - Key: ${keyId}"
    echo "  - CA Bundle: ${caBundle}"

    withCredentials([
        file(credentialsId: certId, variable: 'CYBERARK_CERT'),
        file(credentialsId: keyId, variable: 'CYBERARK_KEY'),
        file(credentialsId: caBundle, variable: 'CYBERARK_CA_BUNDLE')
    ]) {
        body()
    }
}
