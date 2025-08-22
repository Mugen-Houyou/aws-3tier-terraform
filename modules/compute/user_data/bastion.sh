#!/bin/bash
dnf update -y
dnf install -y htop tree wget curl

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Configure SSH for better security
echo "PermitRootLogin no" >> /etc/ssh/sshd_config
echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
systemctl restart sshd

# Create a welcome message
cat > /etc/motd << 'EOF'
*****************************************************
*                                                   *
*  Welcome to 3-Tier Web App Bastion Host          *
*  Environment: Development                         *
*  Managed by: Terraform                            *
*                                                   *
*  This is a jump server for accessing private     *
*  resources in the VPC.                           *
*                                                   *
*****************************************************
EOF

echo "Bastion host setup completed" > /var/log/user-data.log
