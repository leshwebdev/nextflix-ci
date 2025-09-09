pipeline {
    agent any

    environment {
        TMDB_KEY = credentials('tmdb-key')               // Jenkins secret for API key
        STAGING_HOST = "ubuntu@63.177.234.233"
        PRODUCTION_HOST = "ubuntu@18.198.187.28"
        SSH_KEY = credentials('ec2-ssh-key')            // Jenkins SSH private key
        DOCKER_IMAGE = "ohadlesh/nextflix"
        DOCKER_TAG_STAGING = "staging"
        DOCKER_TAG_PRODUCTION = "production"
        DOCKER_TAG_LATEST = "latest"
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-creds') // DockerHub creds
        GITHUB_TOKEN = credentials('github-token')     // Personal access token
        REPO = "leshwebdev/nextflix-ci"
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/leshwebdev/nextflix-ci.git'
            }
        }

        stage('Wait for GitHub Workflow') {
            steps {
                script {
                    def sha = sh(script: "git rev-parse HEAD", returnStdout: true).trim()
                    echo "Latest commit SHA: ${sha}"

                    def conclusion = ""
                    int retries = 0
                    int maxRetries = 3      // retry up to 3 times
                    int sleepSec = 5        // wait 5s between attempts

                    while ((conclusion == "" || conclusion == "null") && retries < maxRetries) {
                        // Query the GitHub check-runs API and extract the first conclusion using jq
                        conclusion = sh(script: """
                            curl -s -H "Authorization: token $GITHUB_TOKEN" \\
                                 -H "Accept: application/vnd.github+json" \\
                                 https://api.github.com/repos/$REPO/commits/$sha/check-runs \\
                            | jq -r '.check_runs[0].conclusion'
                        """, returnStdout: true).trim()

                        if (conclusion == "" || conclusion == "null") {
                            echo "GitHub workflow still running. Waiting ${sleepSec}s..."
                            sleep sleepSec
                            retries++
                        }
                    }

                    echo "GitHub workflow conclusion: ${conclusion}"

                    if (conclusion != "success") {
                        error("GitHub workflow did not complete successfully. Aborting pipeline.")
                    } else {
                        echo "GitHub workflow passed. Proceeding with build."
                    }
                }
            }
        }

        stage('Determine Deployment Target') {
            steps {
                script {
                    // Detect if this is a merge event
                    env.IS_PR_MERGE = sh(
                        script: 'git log -1 --pretty=%s | grep -q "Merge pull request" && echo "true" || echo "false"',
                        returnStdout: true
                    ).trim()
                    echo "Is PR merge: ${env.IS_PR_MERGE}"
                }
            }
        }

        stage('Build and Push Docker Image') {
            steps {
                sshagent(['ec2-ssh-key']) {
                    script {
                        if (env.IS_PR_MERGE == "true") {
                            // Build production image on staging EC2
                            sh """
                            ssh -o StrictHostKeyChecking=no ${STAGING_HOST} \\
                              'cd ~/nextflix-ci && git pull origin main && \\
                               docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG_PRODUCTION} -t ${DOCKER_IMAGE}:${DOCKER_TAG_LATEST} .' 
                            """
                            // Push production image with both production and latest tags
                            sh """
                            ssh -o StrictHostKeyChecking=no ${STAGING_HOST} \\
                              'echo "$DOCKERHUB_CREDENTIALS_PSW" | docker login -u "$DOCKERHUB_CREDENTIALS_USR" --password-stdin && \\
                               docker push ${DOCKER_IMAGE}:${DOCKER_TAG_PRODUCTION} && \\
                               docker push ${DOCKER_IMAGE}:${DOCKER_TAG_LATEST}' 
                            """
                        } else {
                            // Normal push to main → build staging image
                            sh """
                            ssh -o StrictHostKeyChecking=no ${STAGING_HOST} \\
                              'cd ~/nextflix-ci && git pull origin main && \\
                               docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG_STAGING} .' 
                            """
                            // Push staging image
                            sh """
                            ssh -o StrictHostKeyChecking=no ${STAGING_HOST} \\
                              'echo "$DOCKERHUB_CREDENTIALS_PSW" | docker login -u "$DOCKERHUB_CREDENTIALS_USR" --password-stdin && \\
                               docker push ${DOCKER_IMAGE}:${DOCKER_TAG_STAGING}' 
                            """
                        }
                    }
                }
            }
        }

        stage('Deploy') {
            steps {
                sshagent(['ec2-ssh-key']) {
                    script {
                        if (env.IS_PR_MERGE == "true") {
                            // Deploy to production
                            sh """
                            ssh -o StrictHostKeyChecking=no ${PRODUCTION_HOST} \\
                              'docker pull ${DOCKER_IMAGE}:${DOCKER_TAG_LATEST} && \\
                               docker stop nextflix-production || true && \\
                               docker rm nextflix-production || true && \\
                               docker run -d --name nextflix-production -p 3000:3000 -e TMDB_KEY=${TMDB_KEY} ${DOCKER_IMAGE}:${DOCKER_TAG_LATEST}'
                            """
                        } else {
                            // Deploy to staging
                            sh """
                            ssh -o StrictHostKeyChecking=no ${STAGING_HOST} \\
                              'docker stop nextflix-staging || true && \\
                               docker rm nextflix-staging || true && \\
                               docker run -d --name nextflix-staging -p 3000:3000 -e TMDB_KEY=${TMDB_KEY} ${DOCKER_IMAGE}:${DOCKER_TAG_STAGING}'
                            """
                        }
                    }
                }
            }
        }
    }
}
