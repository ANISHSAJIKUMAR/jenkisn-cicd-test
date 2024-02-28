pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = "us-east-1"
        AWS_CREDENTIALS_ID = 'aws-credentials-id' 
    }

    stages {
        stage('Checkout') {
            steps {
                // Correctly checks out the 'main' branch
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
                sh "cd .."
            }
        }

        stage("Build Backend") {
            steps {
                sh "cd backend && npm ci && npm install"
                sh "cd .."
            }
        }

        stage("Build Docker Images") {
            steps {
                sh "docker build -t lightfeather-frontend:$BUILD_NUMBER -f frontend/Dockerfile ./frontend"
                sh "docker build -t lightfeather-backend:$BUILD_NUMBER -f backend/Dockerfile ./backend"
            }
        }

        stage ('Build and Publish to ECR') {
            steps {
                script {
                    withAWS(credentials: "${env.AWS_CREDENTIALS_ID}", region: "${env.AWS_DEFAULT_REGION}") {
                        // Login to ECR
                        sh "aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin 590183924079.dkr.ecr.us-east-1.amazonaws.com"
                        
                        // Tagging Docker images for ECR
                        sh "docker tag lightfeather-backend:$BUILD_NUMBER 590183924079.dkr.ecr.us-east-1.amazonaws.com/lightfeather-backend:$BUILD_NUMBER"
                        sh "docker tag lightfeather-frontend:$BUILD_NUMBER 590183924079.dkr.ecr.us-east-1.amazonaws.com/lightfeather-frontend:$BUILD_NUMBER"
                        
                        // Pushing Docker images to ECR
                        sh "docker push 590183924079.dkr.ecr.us-east-1.amazonaws.com/lightfeather-backend:$BUILD_NUMBER"
                        sh "docker push 590183924079.dkr.ecr.us-east-1.amazonaws.com/lightfeather-frontend:$BUILD_NUMBER"
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
