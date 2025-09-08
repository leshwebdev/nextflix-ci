pipeline {
    agent any

    environment {
        TMDB_KEY = credentials('tmdb-key')               // Jenkins secret for your API key
        EC2_HOST = "ubuntu@63.177.234.233"
        SSH_KEY = credentials('ec2-ssh-key')             // Jenkins SSH private key credential
        DOCKER_IMAGE = "ohadlesh/nextflix"
        DOCKER_TAG = "staging"
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-creds') // DockerHub creds
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/leshwebdev/nextflix-ci.git'
            }
        }

        stage('Build on Staging') {
            steps {
                sshagent(['ec2-ssh-key']) {
                    sh """
                    ssh -o StrictHostKeyChecking=no $EC2_HOST \\
                    cd ~/nextflix-ci \\
                    git pull origin main
                    docker build -t $DOCKER_IMAGE:$DOCKER_TAG .
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