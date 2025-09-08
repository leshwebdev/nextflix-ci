pipeline {
    agent any

    environment {
        TMDB_KEY = credentials('tmdb-key')               // Jenkins secret for your API key
        EC2_HOST = "ubuntu@63.177.234.233"
        SSH_KEY = credentials('ec2-ssh-key')             // Jenkins SSH private key credential
        DOCKER_IMAGE = "ohadlesh/nextflix"
        DOCKER_TAG = "staging"
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-creds') // DockerHub creds
        GITHUB_TOKEN = credentials('github-token')      // GitHub PAT with repo:status scope
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

        stage('Check GitHub Pre-Check') {
            steps {
                script {
                    def sha = sh(script: "git rev-parse HEAD", returnStdout: true).trim()
                    echo "Latest commit SHA: ${sha}"

                    // Retry loop
                    def status = "pending"
                    int retries = 0
                    int maxRetries = 3      // Number of attempts
                    int sleepSec = 5        // Wait between retries (seconds)

                    while (status == "pending" && retries < maxRetries) {
                        status = sh(script: """
                            curl -s -H "Authorization: token $GITHUB_TOKEN" \\
                            https://api.github.com/repos/$REPO/commits/$sha/status \\
                            | grep -o '"state": *"[^"]*"' | head -n 1 | sed 's/.*"\\([^"]*\\)".*/\\1/'
                        """, returnStdout: true).trim()

                        if (status == "pending") {
                            echo "GitHub pre-check still pending. Waiting ${sleepSec}s..."
                            sleep sleepSec
                            retries++
                        }
                    }

                    echo "GitHub pre-check status: ${status}"

                    if (status != "success") {
                        error("GitHub pre-check failed or did not complete in time. Aborting pipeline.")
                    } else {
                        echo "GitHub pre-check passed. Continuing..."
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