#!/bin/bash
apt-get update
# docker installation
curl -sL https://get.docker.com | bash
service docker start
service enable docker
usermod -aG docker docker
# kops installation
curl -Lo kops https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)/kops-linux-amd64
chmod +x ./kops
sudo mv ./kops /usr/local/bin/
# Kubectl installation
curl -Lo kubectl https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl

# installing aws cli
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
apt-get install wget unzip -y
unzip awscliv2.zip
sudo ./aws/install
# cluster configuration
export NAME=ssvkart5-cluster.k8s.local
aws ec2 describe-availability-zones --region us-east-1
kops create cluster \
    --zones=us-east-1a,us-east-1b,us-east-1c \
    ${NAME}

kops create secret --name ssvkart5-cluster.k8s.local sshpublickey admin -i ~/.ssh/id_rsa.pub`


