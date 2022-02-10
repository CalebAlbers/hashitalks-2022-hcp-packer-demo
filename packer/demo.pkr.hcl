data "amazon-ami" "base_image" {
  region = "us-west-2"
  filters = {
    name                = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-arm64-server-*"
    root-device-type    = "ebs"
  }
  most_recent = true
  owners      = ["099720109477"]
}

source "amazon-ebs" "example" {
  region         = "us-west-2"
  source_ami     = data.amazon-ami.base_image.id
  instance_type  = "t4g.micro"
  ssh_username   = "ubuntu"
  ssh_agent_auth = false
  ami_name       = "hcp_packer_demo_app_{{timestamp}}"
}

build {
  hcp_packer_registry {
    bucket_name = "hcp-packer-demo"
    description = "Super simple static website"

    bucket_labels = {
      "hashitalks" = "2022"
      "author" = "Caleb Albers"
    }

    build_labels = {
      "foo-version" = "1.4.2",
    }
  }

  sources = ["source.amazon-ebs.example"]

  // Create directories
  provisioner "shell" {
    inline = ["sudo mkdir /opt/webapp/"]
  }

  // Copy binary to tmp
  provisioner "file" {
    source      = "../bin/server"
    destination = "/tmp/"
  }

  // move binary to desired directory
  provisioner "shell" {
    inline = ["sudo mv /tmp/server /opt/webapp/"]
  }

  post-processor "manifest" {
    output     = "packer_manifest.json"
    strip_path = true
    custom_data = {
      iteration_id = packer.iterationID
    }
  }
}
