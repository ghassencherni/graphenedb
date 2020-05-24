#!/bin/bash 

################################################################################
#Script Name	:init.sh                                                       #                                       
#Description	:Allows to build and configure the jenkins instance on AWS     #
#Author       	:Ghassen CHARNI                                                # 
#Email         	:ghassen.cherni@gmail.com                                      #
#Client         :GRAPHENEDB (DevOps Assesment Test)                            #
################################################################################

###### Genrate certs for ETCD 

echo "Downlod and install cfssl tool"
curl -s -L -o ./binaries/cfssl https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
curl -s -L -o ./binaries/cfssljson https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
chmod +x ./binaries/{cfssl,cfssljson}

echo "Generate CA cert with defined options in ca-csr.json ..."
./binaries/cfssl gencert -initca ./etcd_tls_certs/ca-csr.json | ./binaries/cfssljson -bare ca -

echo "Generate crt from ca.csr"
openssl x509 -req -in ca.csr -signkey ca-key.pem -out ca.crt


echo "Generate server certificate and private key ..."
./binaries/cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=./etcd_tls_certs/ca-config.json -profile=server ./etcd_tls_certs/server.json | cfssljson -bare server

echo "Generate client certificate and private key ..."
./binaries/cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=./etcd_tls_certs/ca-config.json -profile=client ./etcd_tls_certs/client.json | cfssljson -bare client

echo "moving generated certs in their directories"

# Certs will be pushed by ansible to jenkins in order to activate etcd tls/ssl
cp server.pem server-key.pem ca.crt mykveks_jenkins/files/

# Client certs will be used to allow client requestes to etcd cluster
mv ca.csr ca-key.pem ca.pem ca.crt client.csr client-key.pem client.pem server.csr server-key.pem server.pem ./etcd_tls_certs/


###### Deploying the Jenkins EC2 instance

terraform init

terraform plan -out=tfplan -input=false

terraform apply -lock=false -input=false tfplan



###### Configuring Jenkins with Ansible

# Sleep until full starting the instance
sleep 30
echo "waiting for SSHD daemon"

# To avoid host key checking during running install
export ANSIBLE_HOST_KEY_CHECKING=False

# Install and configure the jenkins instance using "deploy_mykveks_jenkins.yml" playbook
ansible-playbook deploy_mykveks_jenkins.yml -i hosts.ini -v -u ec2-user

###### Adding AWS / Gitlab credentials and creating JOBS using jenkins-cli binary
source /tmp/jenkins.env

echo "#####################################################################################################################"
echo "#                                                                                                         "
echo "# Please follow these steps in order to finish the Jenkins deployment:                                    "
echo "#                                                                                                         "
echo "# 1- Open the web browser and connect to : ${JENKINS_URL}                 "   
echo "#                                                                                                         "
echo "# 2- Put the Initial Admin Password : ${INIT_PASSWORD} then click on "continue"                             "
echo "#												                  "
echo "# 3- Select “Install suggested plugins” and wait until plugins installation finished                        "
echo "#                                                                                                           "
echo "# 4- Continue with the “admin” without adding “First Admin User”                                            "
echo "#														  "
echo "# 5- Keep the Jenkins URL as the default one ( ${JENKINS_URL} ) then click on save and finish.              "
echo "#                                                                                                            "
echo "# 6- Click on “Start using Jenkins”                                                                          "
echo "#													           "
echo "# 7- Once Jenkins is ready, press “Yes” to continue                                                          "
echo "#######################################################################################################################"

while true;
do
    read -r -p "If you have activated the admin / the default plugins, tape 'Yes' to continue configuring Jenkins " response
    if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]
    then
	    source /tmp/jenkins.env

	    echo "let's restart Jenkins"
	    java -jar binaries/jenkins-cli.jar -auth admin:"${INIT_PASSWORD}" -s "${JENKINS_URL}" restart
	    sleep 40
	    echo "Jenkins Restarted"
            echo " "
	    
	    echo "Let's create the aws credentials"
	    java -jar binaries/jenkins-cli.jar -auth admin:"${INIT_PASSWORD}" -s "${JENKINS_URL}" create-credentials-by-xml system::system::jenkins _  < jenkins_files/aws_credentials.xml
	    echo " "

	    echo "Create 'mykveks_deploy_eks' job..."
	    java -jar binaries/jenkins-cli.jar -auth admin:"${INIT_PASSWORD}" -s "${JENKINS_URL}" -webSocket create-job mykveks_deploy_eks  < jenkins_files/mykveks_deploy_eks.xml

	    echo "Create 'mykveks_deploy_etcd' job..."
            java -jar binaries/jenkins-cli.jar -auth admin:"${INIT_PASSWORD}" -s "${JENKINS_URL}" -webSocket create-job mykveks_deploy_etcd < jenkins_files/mykveks_deploy_etcd.xml

	    echo "Create mykveks_deploy_monitoring job..."
	    java -jar binaries/jenkins-cli.jar -auth admin:"${INIT_PASSWORD}" -s "${JENKINS_URL}" -webSocket create-job mykveks_deploy_monitoring < jenkins_files/mykveks_deploy_monitoring.xml


            # Delete the Jenkins Env File and AWS Credentials
            rm /tmp/jenkins.env
	    rm jenkins_files/aws_credentials.xml

        exit 0
   fi 
done

