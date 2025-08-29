FROM jenkins/jenkins:lts-jdk21

USER root

# Install Git, Groovy, Docker CLI, unzip, curl
RUN apt-get update && \
    apt-get install -y git groovy docker.io unzip curl && \
    rm -rf /var/lib/apt/lists/*

# Switch back to Jenkins user
USER jenkins

# Install required Jenkins plugins
# List of plugins: pipeline, git, docker, blueocean, credentials, sonar
RUN jenkins-plugin-cli --plugins \
    workflow-aggregator \
    git \
    docker-workflow \
    credentials-binding \
    blueocean \
    sonar \
    pipeline-groovy-lib \
    configuration-as-code

# Create folder for Groovy init scripts
RUN mkdir -p /var/jenkins_home/init.groovy.d
