data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

variable "sg_name" {
  type    = string
  default = "runners-sg"
}

locals {
  manager_instance_type = "t3.micro"
}

resource "aws_security_group" "manager" {

  name   = var.sg_name
  vpc_id = module.vpc.vpc_id

  # SSH
  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 2376
    to_port     = 2376
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "runners-vm-sg"
    Group     = "gitlab-runners"
    Terraform = "true"
  }
}

# Define the IAM role for EC2 instance
resource "aws_iam_role" "manager_iam_role" {
  name = "runners_manager_vm_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Define the IAM policy for EC2 instance
resource "aws_iam_policy" "manager_s3_policy" {
  name = "runners_manager_role_s3policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:*",
          "s3:*"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Attach the IAM policy to the IAM role
resource "aws_iam_role_policy_attachment" "manager_s3_policy_attachment" {
  policy_arn = aws_iam_policy.manager_s3_policy.arn
  role       = aws_iam_role.manager_iam_role.name
}

resource "aws_iam_instance_profile" "manager_instance_profile" {
  name = "runners_manager_instance_profile"
  role = aws_iam_role.manager_iam_role.name
}

resource "aws_instance" "manager" {

  ami                  = data.aws_ami.ubuntu.id
  instance_type        = local.manager_instance_type
  key_name             = var.key_pair
  user_data            = data.template_file.cloud-init.rendered
  iam_instance_profile = aws_iam_instance_profile.manager_instance_profile.name

  vpc_security_group_ids = [aws_security_group.manager.id]
  subnet_id              = module.vpc.public_subnets[0]

  tags = {
    Name      = "runners-vm-manager"
    Group     = "gitlab-runners"
    Terraform = "true"
  }
}
