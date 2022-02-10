variable "iteration_id" {
  description = "HCP Packer Iteration ID"
}

data "hcp_packer_image" "ubuntu" {
  bucket_name    = "hcp-packer-demo"
  cloud_provider = "aws"
  iteration_id   = var.iteration_id
  region         = "us-west-2"
}

resource "aws_security_group" "allow_8080" {
  description = "Allow inbound TCP traffic to port 8080"

  ingress {
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"

  name = "basic-webapp"

  ami           = data.hcp_packer_image.ubuntu.cloud_image_id
  instance_type = "t4g.micro"
  user_data     = file("${path.module}/userdata.sh")

  vpc_security_group_ids = [aws_security_group.allow_8080.id]

  associate_public_ip_address = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

output "health_endpoint" {
  description = "URL of the health check endpoint"
  value = "http://${module.ec2_instance.public_ip}:8080/healthz"
}
