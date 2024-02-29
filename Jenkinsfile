pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = "us-east-1"
        AWS_CREDENTIALS_ID = 'aws-credentials-id' // Ensure this matches the actual ID of your AWS credentials in Jenkins
        ECR_REPOSITORY = "590183924079.dkr.ecr.us-east-1.amazonaws.com/devops-code-challenge"
        PATH = "/opt/homebrew/bin:${env.PATH}"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout([
                    $class: 'GitSCM', 
                    branches: [[name: '*/main']],
                    userRemoteConfigs: [[url: 'https://github.com/ANISHSAJIKUMAR/jenkisn-cicd-test.git']]
                ])
            }
        }

        stage("Build Frontend") {
            steps {
                sh "cd frontend && npm ci && npm install && npm run build"
            }
        }

        stage("Build Backend") {
            steps {
                sh "cd backend && npm ci && npm install"
            }
        }

        stage("Build Docker Images") {
            steps {
                sh "/usr/local/bin/docker build -t ${ECR_REPOSITORY}:frontend-${BUILD_NUMBER} -f frontend/Dockerfile ./frontend"
                sh "/usr/local/bin/docker build -t ${ECR_REPOSITORY}:backend-${BUILD_NUMBER} -f backend/Dockerfile ./backend"
            }
        }

        stage ('Build and Publish to ECR') {
            steps {
                script {
                    withAWS(credentials: "${AWS_CREDENTIALS_ID}", region: "${AWS_DEFAULT_REGION}") {
                        // Login to ECR
                        sh "aws ecr get-login-password | /usr/local/bin/docker login --username AWS --password-stdin ${ECR_REPOSITORY}"
                        
                        // Pushing Docker images to ECR
                        sh "/usr/local/bin/docker push ${ECR_REPOSITORY}:frontend-${BUILD_NUMBER}"
                        sh "/usr/local/bin/docker push ${ECR_REPOSITORY}:backend-${BUILD_NUMBER}"
                    }
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}
