# Overview
This repository contains a React frontend, and an Express backend that the frontend connects to.

# Objective
Deploy the frontend and backend to somewhere publicly accessible over the internet. The AWS Free Tier should be more than sufficient to run this project, but you may use any platform and tooling you'd like for your solution.

Fork this repo as a base. You may change any code in this repository to suit the infrastructure you build in this code challenge.

# Submission
1. A github repo that has been forked from this repo with all your code.
2. Modify this README file with instructions for:
* Any tools needed to deploy your infrastructure
* All the steps needed to repeat your deployment process
* URLs to the your deployed frontend.

# Evaluation
You will be evaluated on the ease to replicate your infrastructure. This is a combination of quality of the instructions, as well as any scripts to automate the overall setup process.

# Setup your environment
Install nodejs. Binaries and installers can be found on nodejs.org.
https://nodejs.org/en/download/

For macOS or Linux, Nodejs can usually be found in your preferred package manager.
https://nodejs.org/en/download/package-manager/

Depending on the Linux distribution, the Node Package Manager `npm` may need to be installed separately.

# Running the project
The backend and the frontend will need to run on separate processes. The backend should be started first.
```
cd backend
npm ci
npm start
```
The backend should response to a GET request on `localhost:8080`.

With the backend started, the frontend can be started.
```
cd frontend
npm ci
npm start
```
The frontend can be accessed at `localhost:3000`. If the frontend successfully connects to the backend, a message saying "SUCCESS" followed by a guid should be displayed on the screen.  If the connection failed, an error message will be displayed on the screen.

# Configuration
The frontend has a configuration file at `frontend/src/config.js` that defines the URL to call the backend. This URL is used on `frontend/src/App.js#12`, where the front end will make the GET call during the initial load of the page.

The backend has a configuration file at `backend/config.js` that defines the host that the frontend will be calling from. This URL is used in the `Access-Control-Allow-Origin` CORS header, read in `backend/index.js#14`

# Optional Extras
The core requirement for this challenge is to get the provided application up and running for consumption over the public internet. That being said, there are some opportunities in this code challenge to demonstrate your skill sets that are above and beyond the core requirement.

A few examples of extras for this coding challenge:
1. Dockerizing the application
2. Scripts to set up the infrastructure
3. Providing a pipeline for the application deployment
4. Running the application in a serverless environment

This is not an exhaustive list of extra features that could be added to this code challenge. At the end of the day, this section is for you to demonstrate any skills you want to show that’s not captured in the core requirement.

# CHANGES
   * I had to change from Main branch to Master because my Jenkins pipeline won't recognise Main Branch. 
   
# Manual deployment of Jenkins Server on AWS
  * Instance type T2 Medium with Ubuntu server 20.04LTS
  * Congifure Storage 25GiB Root Volume
  * Security Group open port 8080 to expose Jenkins, port 22 for ssh and port 443 for internet access
  * Create IAM user and attach administrator access policy to the user
  * Install Nodejs and Npm
  * Install Java
  * Install Aws Cli v2
  * Install Docker
  * Install Terraform



# Steps

0. Create a public reposotory on Elastic Container Registery (ECR)
	* Go to AWS ECR and click on create repository
	* Click on "View push commands" tab for usedul commands
	* Some of the push commands are used in the Jenkinsfile to publish image to ECR



1. Buid both frontend and backend applications into docker image
	* use Jenkins automation server for this step
	* Create a Jenkinsfile in the root directory
	* Create Dockerfile in both Frontend and Backend directory
	* To automate the build process using Jenkins automation server, the following is needed:
		* Install "CloudBees AWS Credentials Plugin" which allows storing of AWS IAM credentials
			within the Jenkins Credentials API.
		* Configure credentials using the "Manage credentials" tab under Security in Manage Jenkins to
			store your AWS IAM secret key and secret access key.(needed for publishing to aws ECR)


2. Provision AWS resource for Elastic Container Service (ECS) using Terraform
	* Create VPC
	* Create public(2) and private subnets(2)
	* Create internet and NAT gateways
	* Create elastic IP (2)
	* Create a route table for internet gateway IGW
	* create aws_route to associate public subnets with internet route table 
	* Create a route table for NAT gateway
	* Associate NAT gateway route table with private subnets
	* Create a security group for application load balancer (Only port 80 needed)
	* Create an application load balancer in the public subnets
	* Create a target group for ALB with port value same as mapped host's port to exposed backend app's port
	* Create a listener for ALB with port 80 for HTTP
	* Create ecs task definition
	* Create security group for task with port same as mapped host's port to exposed backend app's port
	* Create ecs cluster
	* Create ecs service in private subnets with FARGATE launch_type

NB: Internet Gateways (IGWs) in AWS are horizontally scalable
	which means that they can automatically handle an increase in traffic without manual intervention.

