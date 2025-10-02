# Multi-Container Application (WIP)
This project uses Docker Compose to orchestrate a multi-container environment consisting of a Node.js API and a MongoDB database. Infrastructure is provisioned with Terraform, the EC2 instance is configured via Ansible, and the entire stack is built and deployed to AWS using a GitHub Actions CI/CD pipeline.

## Project Structure
The project follows a standard directory structure:
```bash
.
├── docker-compose.yml # Docker Compose configuration file
├── node_api/
│   ├── Dockerfile # Node.js API Dockerfile
│   ├── server.js # Main Node.js API server file
│   ├── models/
│   │   └── todo.js # Mongoose model for Todo items
│   ├── package.json
│   └── routes/
│       └── todos.js # Express routes for Todo items
├── ansible/
│   └── playbook.yml # Ansible playbook for server configuration
├── terraform/ # Terraform configuration files
└── .github/
    └── workflows/
            └── ci.yml # GitHub Actions workflow for CI/CD
```
## Deployment
### Prerequisites

- [GitHub account](https://github.com/)
- [AWS account](https://console.aws.amazon.com)

### Setup
#### 1. Clone the project's GitHub repository.

Clone the repository:
   ```bash
   git clone https://github.com/MGhaith/Multi-Container-Application.git
   cd Multi-Container-Application
   ```

#### 2. Create a Github Repository and Add Secrets
You need this repository to store the project code, trigger the deployment workflow, and store secrets.

1. Create a new repository on [GitHub](https://github.com) for the project.
2. Generate an SSH key pair, if you don't one already.
   ```bash
   ssh-keygen -t rsa -P "" -f ~/.ssh/id_rsa
   ```
3. Create a new secret in the repository settings (Settings > Secrets and variables > Actions > New repository secret).
    - Docker Hub secrets:
        - `DOCKERHUB_USERNAME` — Docker Hub username (or registry user)
        - `DOCKERHUB_TOKEN` — Docker Hub access token (or password)
    - SSH secrets:
        - `SSH_PRIVATE_KEY` — Your private SSH key (contents of `~/.ssh/id_rsa`)
        - `SSH_PUBLIC_KEY` — Your public SSH key (contents of `~/.ssh/id_rsa.pub`)
    - Terraform secrets:
        - `TERRAFORM_ROLE_ARN` — ARN of the IAM role with Terraform permissions ( check step 4 for more details )

#### 3. Create S3 bucket and DynamoDB table for Terraform state
1. Log in to the [AWS Management Console](https://console.aws.amazon.com/).
2. Navigate to the S3 service and create a new S3 bucket.
    - Bucket name: `multi-container-app-terraform-state-<Your AWS Account ID>` (Replace `<Your AWS Account ID>` with your AWS Account ID)
    - Region: `us-east-1` or any other region.
    - Enable versioning
    - Enable public access block
    - Create bucket
3. Navigate to the S3 service and create a new DynamoDB table in the same region for state locking
    - Table name: `multi-container-app-terraform-locks`
    - Partition key: `LockID` (String)
    - Create table
4. update `terraform\backend.tf` with your bucket name and DynamoDB table name.
    ``` hcl
    terraform {
      required_version = ">= 1.13.0"
  
      backend "s3" {
        bucket         = "multi-container-app-terraform-state-<Your AWS Account ID>" # Change this
        key            = "global/terraform.tfstate"                     
        region         = "us-east-1"                                    
        dynamodb_table = "multi-container-app-terraform-locks" # And this 
        encrypt        = true                                           
      }
    }
    ```

#### 4. Create IAM Role for OIDC
1. Log in to the [AWS Management Console](https://console.aws.amazon.com/).
2. Navigate to the IAM service.
3. Create a new `Web identity` role
    - Trusted entity type: `Web identity`
    - Identity provider: `token.actions.githubusercontent.com`
    - Audience: `sts.amazonaws.com`
    - GitHub organization: `Your Github Username` or `Your Github Organization`
    - GitHub repository: `Your repository name`
4. In the new role you created add the following inline policy:
    ```json
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "EC2FullAccess",
                "Effect": "Allow",
                "Action": "ec2:*",
                "Resource": "*"
            },
            {
                "Sid": "STSGetCallerIdentity",
                "Effect": "Allow",
                "Action": "sts:GetCallerIdentity",
                "Resource": "*"
            },
            {
                "Sid": "TerraformS3Backend",
                "Effect": "Allow",
                "Action": [
                    "s3:GetObject",
                    "s3:PutObject",
                    "s3:DeleteObject",
                    "s3:ListBucket"
                ],
                "Resource": [
                    "<Your S3 Bucket Name ARN>",
                    "<Your S3 Bucket Name ARN>/*"
                ]
            },
            {
                "Sid": "TerraformDynamoDBLock",
                "Effect": "Allow",
                "Action": [
                    "dynamodb:GetItem",
                    "dynamodb:PutItem",
                    "dynamodb:DeleteItem",
                    "dynamodb:UpdateItem"
                ],
                "Resource": "<Your DynamoDB Table ARN>"
            }
        ]
    }
    ```
    > **Note**: Replace `<Your S3 Bucket Name ARN>` and `<Your DynamoDB Table ARN>` with your State Bucket ARN and DynamoDB Table ARN created for Terraform remote state (`./terraform/backend.tf`).

5. Copy the Role ARN, and add it as a value to `TERRAFORM_ROLE_ARN` secret in your repository.

#### 5. Update files.
In `./docker-compose.yml`, change the api **image** value to your Docker Hub username (replace `yourdockerhubusername` with same value used for `DOCKERHUB_USERNAME` secret).
``` yml
services:
    api:
        image: yourdockerhubusername/multi-container-app:latest #Change this to your Docker Hub username
        ports:
        - "3000:3000"
        environment:
        - MONGO_URL=mongodb://mongo:27017/todos
        depends_on:
        - mongo
```
#### 6. Push changes to trigger deployment.
1. Commit and push your changes to the `main` branch of the repository you created.
    ```
    git add .
    git commit -m "Deploy Node.js api"
    git push origin main
    ```
2. Check the Actions tab in your repository to monitor the deployment progress.

## Verification and Testing
1. Once the deployment is complete, check the Actions tab in your repository to verify that the deployment job has passed.
2. Access the deployed service using the public IP outputted by **Terraform** or the **AWS EC2 Console** with the port (e.g., `http://<public-ip>:3000`). You should see the “Todo API is running. Use /todos to interact with the API.” message.
3. Try accessing the `/todos` endpoint. You should see an empty array `[]`.
4. Test the `/todos` endpoint with POST, PUT, DELETE methods to ensure CRUD operations work as expected using one of these methods:
    - Test with `curl`:
        ```bash
        # Create a todo
        curl -X POST -H "Content-Type: application/json" -d '{"title": "Buy groceries"}' http://<public-ip>:3000/todos

        # Get all todos
        curl http://<public-ip>:3000/todos

        # Get a single todo
        curl http://<public-ip>:3000/todos/<id>
        
        # Update a todo
        curl -X PUT -H "Content-Type: application/json" -d '{"title": "Buy groceries", "completed": true}' http://<public-ip>:3000/todos/<id>
        
        # Delete a todo
        curl -X DELETE http://<public-ip>:3000/todos/<id>
        ```
    - Postman:
        - **Create a todo**  
          Method: POST  
          URL: `http://<public-ip>:3000/todos`  
          Body (raw JSON):
          ```json
          {
              "title": "Buy groceries"
          }
          ```

        - **Get all todos**  
          Method: GET  
          URL: `http://<public-ip>:3000/todos`

        - **Get a single todo**  
          Method: GET  
          URL: `http://<public-ip>:3000/todos/<id>`

        - **Update a todo**  
          Method: PUT  
          URL: `http://<public-ip>:3000/todos/<id>`  
          Body (raw JSON):
          ```json
          {
              "title": "Buy groceries",
              "completed": true
          }
          ```

        - **Delete a todo**  
          Method: DELETE  
          URL: `http://<public-ip>:3000/todos/<id>`

### Infrastructure Destruction
To destroy the infrastructure created by this project, follow these steps:
1. Navigate to the project directory.
2. Ensure you have Terraform installed and configured with AWS credentials.
3. Run the following command to destroy the resources:
    ```
    cd terraform
    terraform destroy
    ```
3. Enter you public key content from `~/.ssh/id_rsa.pub` and confirm the destruction when prompted.

## Node.js API Application

The Node.js API is a lightweight RESTful service built with Express and Mongoose that provides CRUD operations for Todo items. It listens on port 3000 and connects to MongoDB via the `MONGO_URL` environment variable.

### Core Files
- **server.js** – Entry point that bootstraps Express, wires middleware, connects to MongoDB, and mounts the `/todos` router.
- **models/todo.js** – Mongoose schema defining a Todo with `title` (required string) and `completed` (boolean, default false).
- **routes/todos.js** – Express router exposing endpoints:
  - `GET /todos` – list all todos
  - `POST /todos` – create a new todo
  - `GET /todos/:id` – fetch a single todo
  - `PUT /todos/:id` – update a todo
  - `DELETE /todos/:id` – remove a todo
- **package.json** – Dependencies: Express 5.1.0 & Mongoose 8.0.0; dev script uses nodemon for local development.

## Ansible Configuration

The Ansible playbook (`./ansible/playbook.yml`) automates the configuration of the EC2 instance after Terraform provisions it. The playbook runs as root and performs the following tasks:

1. Installs Docker (`docker.io`) and Docker Compose on the target host.
2. Creates the application directory `/home/ubuntu/multi-container-app` with proper ownership for the ubuntu user.
3. Copies the local `docker-compose.yml` file to the server.
4. Pulls the latest images and starts the multi-container stack in detached mode.

This ensures the Node.js API and MongoDB containers are up and running immediately after the infrastructure is created.

## GitHub Actions CI/CD Workflow

The GitHub Actions workflow (`./.github/workflows/cicd.yml`) automates the entire deployment pipeline through three sequential jobs:

### 1. build-infra (Terraform)
- Triggered on push to `main`, ignoring README, gitignore, gitattributes and LICENSE changes
- Uses OIDC to assume the role stored in `TERRAFORM_ROLE_ARN`
- Initializes, plans and applies Terraform to spin up an EC2 instance
- Exposes the instance’s public IP as an output (`server_ip`) for downstream jobs

### 2. build-and-deploy (Docker & Ansible)
- Depends on successful `build-infra`
- Builds the Node.js Docker image locally
- Logs in to Docker Hub via `DOCKERHUB_USER` / `DOCKERHUB_TOKEN` and pushes the image
- Dynamically generates an Ansible inventory targeting the newly created server
- Runs the Ansible playbook (`playbook.yml`) to install Docker-Compose and start the multi-container stack

### 3. cleanup (Terraform Destroy)
- Executes only if any previous job fails (`if: failure()`)
- Re-assumes the same OIDC role and runs `terraform destroy -auto-approve` to remove all AWS resources, preventing orphaned infrastructure

The workflow leverages repository secrets for Docker Hub, SSH keys, and AWS role assumption, adhering to IaC best-practices with Terraform for provisioning and Ansible for configuration management.

## License
This project is licensed under the MIT License - see the [LICENSE](https://github.com/MGhaith/Multi-Container-Application/blob/main/LICENSE) file for details.