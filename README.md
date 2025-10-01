# Multi-Container Application (WIP)
Use Docker Compose to run a multi-container application

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
