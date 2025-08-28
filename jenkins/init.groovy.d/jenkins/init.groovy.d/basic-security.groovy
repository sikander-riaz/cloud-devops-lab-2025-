[200~#!groovy

import jenkins.model.* import hudson.security.*
def instance = Jenkins.getInstance()

def username = System.getenv("JENKINS_ADMIN_USER")
def password = System.getenv("JENKINS_ADMIN_PASS")

if (username && password) {
    println "Creating admin user..."
    def hudsonRealm = new HudsonPrivateSecurityRealm(false)
    hudsonRealm.createAccount(username, password)
    instance.setSecurityRealm(hudsonRealm)

    def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
    strategy.setAllowAnonymousRead(false)
    instance.setAuthorizationStrategy(strategy)

    instance.save()
}

