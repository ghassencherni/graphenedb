#----mykveks/main.tf----

provider "aws" {
  region = "${var.aws_region}"
}

# Create our key pair, to allow Ansible to connect to Jenkins instance
resource "aws_key_pair" "my_auth" {
  key_name   = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
}

# Allow to get My Public IP 
data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

# Create the Security Group for our Jenkins Server
resource "aws_security_group" "jenkins_ssh_http_sg" {
  name        = "jenkins_ssh_http_sg"
  description = "Used for Jenkins SSH and HTTP connexion"

  #SSH 
  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    # Allow only our public IP to connect to the instance
    #cidr_blocks = ["${var.my_admin_ip}"]
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
  }

  #HTTP 8080 (jenkins)
  ingress {
    from_port = 8080
    to_port   = 8080
    protocol  = "tcp"
    # Allow only our IP to connect to the instance
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# Create the jenkins instance
resource "aws_instance" "jenkins_instance" {
  instance_type = "${var.instance_type}"
  
  # Amazon Linux 2 AMI
  ami           = "ami-06ce3edf0cff21f07"

  tags {
    Name = "mykveks_jenkins"
  }

  key_name  = "${aws_key_pair.my_auth.id}"
  vpc_security_group_ids = ["${aws_security_group.jenkins_ssh_http_sg.id}"]
}

