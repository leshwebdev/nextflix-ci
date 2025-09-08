pipeline {
    agent any

    environment {
        TMDB_KEY = credentials('tmdb-key')               // Jenkins secret for your API key
        EC2_HOST = "ubuntu@63.177.234.233"
        SSH_KEY = credentials('ec2-ssh-key')             // Jenkins SSH private key credential
        DOCKER_IMAGE = "ohadlesh/nextflix"
        DOCKER_TAG = "staging"
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-creds') // DockerHub creds
        GITHUB_TOKEN = credentials('github-token')      // GitHub PAT with repo access
        REPO = "leshwebdev/nextflix-ci"
        BRANCH = "main"
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: "${BRANCH}",
                    url: "https://github.com/${REPO}.git"
            }
        }

        stage('Wait for GitHub Workflow') {
            steps {
                script {
                    def sha = sh(script: "git rev-parse HEAD", returnStdout: true).trim()
                    echo "Latest commit SHA: ${sha}"

                    def conclusion = ""
                    int retries = 0
                    int maxRetries = 3      // retry up to 20 times
                    int sleepSec = 5        // wait 10s between attempts

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

        stage('Build on Staging') {
            steps {
                sshagent(['ec2-ssh-key']) {
                    sh """
                    ssh -o StrictHostKeyChecking=no $EC2_HOST \\
                    'cd ~/nextflix-ci && \\
                     git pull origin main && \\
                     docker build -t $DOCKER_IMAGE:$DOCKER_TAG .'
                    """
                }
            }
        }

        stage('Push to DockerHub') {
            steps {
                sshagent(['ec2-ssh-key']) {
                    sh """
                    ssh -o StrictHostKeyChecking=no $EC2_HOST \\
                    'echo "$DOCKERHUB_CREDENTIALS_PSW" | docker login -u "$DOCKERHUB_CREDENTIALS_USR" --password-stdin && \\
                     docker tag $DOCKER_IMAGE:$DOCKER_TAG $DOCKER_IMAGE:$DOCKER_TAG && \\
                     docker push $DOCKER_IMAGE:$DOCKER_TAG'
                    """
                }
            }
        }

        stage('Deploy on Staging') {
            steps {
                sshagent(['ec2-ssh-key']) {
                    sh """
                    ssh -o StrictHostKeyChecking=no $EC2_HOST \\
                    'docker stop nextflix-staging || true && \\
                     docker rm nextflix-staging || true && \\
                     docker run -d --name nextflix-staging -p 3000:3000 -e TMDB_KEY=$TMDB_KEY $DOCKER_IMAGE:$DOCKER_TAG'
                    """
                }
            }
        }
    }
}