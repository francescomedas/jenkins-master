#!/bin/bash

EFS_DNS_NAME="${efs_dns_name}"

sudo yum -y update
sudo yum -y install java-1.8.0-openjdk-devel
curl --silent --location http://pkg.jenkins-ci.org/redhat-stable/jenkins.repo | sudo tee /etc/yum.repos.d/jenkins.repo
sudo rpm --import https://jenkins-ci.org/redhat/jenkins-ci.org.key
sudo mkdir -p /var/lib/jenkins
sudo mount -t nfs -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport $EFS_DNS_NAME:/ /var/lib/jenkins/
sudo chmod go+rw /var/lib/jenkins
sudo yum -y install jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins