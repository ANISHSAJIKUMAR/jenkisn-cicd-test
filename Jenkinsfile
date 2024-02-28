pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = "us-east-1"
        // Reference the ID of the AWS credentials stored in Jenkins
        AWS_CREDENTIALS_ID = 'aws-credentials-id'
    }

    stages {
        stage('Checkout') {
            steps {
                git url: ''
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
                    // Use withAWS plugin to setup AWS credentials for the block
                    withAWS(credentials: "${env.AWS_CREDENTIALS_ID}", region: "${env.AWS_DEFAULT_REGION}") {
                        sh '''
                        $(aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 590183924079.dkr.ecr.us-east-1.amazonaws.com)
                        
                        docker tag lightfeather-backend:$BUILD_NUMBER public.ecr.aws/h8n2j7c4/lightfeather-backend:$BUILD_NUMBER
                        docker push public.ecr.aws/h8n2j7c4/lightfeather-backend:$BUILD_NUMBER
                        
                        docker tag lightfeather-frontend:$BUILD_NUMBER public.ecr.aws/h8n2j7c4/lightfeather-frontend:$BUILD_NUMBER
                        docker push public.ecr.aws/h8n2j7c4/lightfeather-frontend:$BUILD_NUMBER
                        '''
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
