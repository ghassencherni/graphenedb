# AWS region where to run our Jenkins instance
aws_region = "eu-west-1"

# The name of the public ssh key stored in AWS
key_name = "graphenedb_key"

# The public key for ssh connection 
public_key_path = "~/.ssh/id_rsa.pub"

# The private SSH key, used by ansible to configure the Jenkins instance
private_key_path= "~/.ssh/id_rsa"

# The size of the Jenkins instance, micro is sufficient for our deployment
instance_type = "t2.micro"

# The AWS ACCESS KEY ID
aws_access_key_id = ""

# The AWS SECRET ACCESS KEY
aws_secret_access_key = ""

