# Data source for latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Key Pair for EC2 instances
resource "aws_key_pair" "main" {
  key_name   = "${var.project_name}-keypair"
  public_key = var.public_key

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-keypair"
  })
}

# Bastion Host in Public Subnet
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name              = aws_key_pair.main.key_name
  vpc_security_group_ids = [var.bastion_security_group_id]
  subnet_id             = var.public_subnet_ids[0]

  user_data = base64encode(templatefile("${path.module}/user_data/bastion.sh", {}))

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-bastion"
    Tier = "Web"
    Type = "Bastion"
  })
}

# Web Servers in Private Subnets
resource "aws_instance" "web" {
  count = length(var.private_subnet_ids)

  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name              = aws_key_pair.main.key_name
  vpc_security_group_ids = [var.web_security_group_id]
  subnet_id             = var.private_subnet_ids[count.index]

  user_data = base64encode(templatefile("${path.module}/user_data/web.sh", {
    db_endpoint = var.db_endpoint
  }))

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-web-${count.index + 1}"
    Tier = "Application"
    Type = "WebServer"
  })

  depends_on = [aws_instance.bastion]
}
