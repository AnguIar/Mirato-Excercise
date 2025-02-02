# Kubernetes Mutating Webhook Project

This project creates a MutatingWebhookConfiguration for Kubernetes that automatically adds missing resources to pods and deployments if they are not defined.

## Project Components

1. **Dockerfile**  
   A Dockerfile to build the webhook application, running on the default port 8080.

2. **Terraform Files**  
   The project contains three Terraform files to manage the webhook setup:
   - **Webhook Deployment & Service**: Defines the deployment and service for the webhook application.
   - **Certificates**: Manages the certificates needed for the MutatingWebhookConfiguration.
   - **MutatingWebhookConfiguration**: Defines the MutatingWebhookConfiguration itself for Kubernetes.

3. **webhook.py**  
   The main application code written in Python that processes webhook requests.

4. **test-pod.yaml**  
   A dummy NGINX pod YAML file for testing the webhook and seeing the automatic modifications.

## Installation

To set up the project, follow these steps:

### 1. Clone the repository
### 2. Build the Docker image
```
docker build -t webhook:v1.0.0 .
```
### 3. Apply Terraform configurations
```
terraform init
terraform apply
```
### 4. Usage
After applying the Terraform files, the webhook will automatically mutate pods and deployments that do not have the necessary resources defined.
To test the webhook:

`kubectl apply -f test-pod.yaml`

Check if resources are adjusted:  

`kubectl describe pod nginx`
