import jenkins.model.*
import hudson.security.*
import jenkins.security.s2m.AdminWhitelistRule

def env = System.getenv()
def adminUser = env['JENKINS_ADMIN_USER'] ?: 'admin'
def adminPass = env['JENKINS_ADMIN_PASS'] ?: 'admin'

def instance = Jenkins.getInstance()

// Create admin user
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount(adminUser, adminPass)
instance.setSecurityRealm(hudsonRealm)

// Full control authorization
def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)

// Approve Groovy scripts automatically
AdminWhitelistRule.get().setMasterKillSwitch(true)

instance.save()
