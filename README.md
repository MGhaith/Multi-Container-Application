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