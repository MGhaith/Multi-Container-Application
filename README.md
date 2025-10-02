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

## License
This project is licensed under the MIT License - see the [LICENSE](https://github.com/MGhaith/Multi-Container-Application/blob/main/LICENSE) file for details.