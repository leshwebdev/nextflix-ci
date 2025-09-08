pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-creds') // Jenkins secret for DockerHub (username+password)
        TMDB_KEY = credentials('tmdb-key') // Jenkins secret text for your API key
        DOCKER_IMAGE = "leshwebdev/nextflix"  // Your DockerHub repo
        DOCKER_TAG = "staging"
        EC2_HOST = "ubuntu@63.177.234.233"
        SSH_KEY = credentials('ec2-ssh-key') // Jenkins SSH private key credential
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/leshwebdev/nextflix-ci.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh """
                    docker build -t $DOCKER_IMAGE:$DOCKER_TAG .
                    """
                }
            }
        }

        stage('Login to DockerHub') {
            steps {
                script {
                    sh """
                    echo "$DOCKERHUB_CREDENTIALS_PSW" | docker login -u "$DOCKERHUB_CREDENTIALS_USR" --password-stdin
                    """
                }
            }
        }

        stage('Push Image to DockerHub') {
            steps {
                script {
                    sh "docker push $DOCKER_IMAGE:$DOCKER_TAG"
                }
            }
        }

        stage('Deploy to EC2') {
            steps {
                script {
                    sh """
                    ssh -o StrictHostKeyChecking=no -i $SSH_KEY $EC2_HOST \\
                        'docker pull $DOCKER_IMAGE:$DOCKER_TAG &&
                         docker stop nextflix-staging || true &&
                         docker rm nextflix-staging || true &&
                         docker run -d --name nextflix-staging -p 3000:3000 -e TMDB_KEY=$TMDB_KEY $DOCKER_IMAGE:$DOCKER_TAG'
                    """
                }
            }
        }
    }
}
