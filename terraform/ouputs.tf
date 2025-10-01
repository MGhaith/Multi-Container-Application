output "server_ip" {
  value       = aws_instance.multi-container-app.public_ip
  description = "The public IP of the Node.js server"
}
