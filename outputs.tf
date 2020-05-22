#----deploy_jenkins/outputs.tf----

# Create the hosts.ini used by ansible to configure the jenkins instance
resource "local_file" "ansible_hosts" {
  content = <<HOSTS
[nodes]
${aws_instance.jenkins_instance.public_dns} ansible_ssh_private_key_file=${var.private_key_path}
HOSTS

filename = "hosts.ini"
file_permission = "600"

}


# Credential file containing AWS Access key, pushed by jenkins-cli binary on the jenkins instance
resource "local_file" "aws_credentials" {
  content = <<GITLABREG
<com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl >
  <scope>GLOBAL OR SYSTEM</scope>
  <id>aws_credentials</id>
  <username>${var.aws_access_key_id}</username>
  <password>${var.aws_secret_access_key}</password>
  <description>AWS user that allows to build and destroy the infrastructure</description>
</com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
GITLABREG

filename = "jenkins_files/aws_credentials.xml"
file_permission = "600"
}


