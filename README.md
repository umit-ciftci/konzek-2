# Mid Level Assignment: Kubernetes Deployment and Scaling

Prepare Development Server Manually on EC2 Instance
```
#! /bin/bash
sudo dnf update -y
sudo hostnamectl set-hostname petclinic-dev-server
sudo dnf install docker -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -a -G docker ec2-user
sudo curl -SL https://github.com/docker/compose/releases/download/v2.20.3/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo dnf install git -y
sudo dnf install java-11-amazon-corretto -y
newgrp docker
```
Prepare GitHub Repository for the Project

Connect to your Development Server via ssh and clone the petclinic app from the repository
```
git clone https://github.com/umit-ciftci/konzek-2.git
git init
git add .
git config --global user.email "you@example.com"
git config --global user.name "Your Name"
git commit -m "first commit"
git branch -M main
git remote add origin https://[github username]:[your-token]@github.com/[your-git-account]/[your-repo-name.git]
git push origin main
```

Prepare Dockerfiles for Microservices

backend-servis dosyası altında  Backend serverın Dockerfileını kaydedin

```
#Backend microservice Dockerfile
#Base image
FROM openjdk:11-jre

#Set working directory
WORKDIR /app

#Copy application JAR file
COPY target/*.jar app.jar

#Expose port (Port numarasını 8081 olarak değiştirin)
EXPOSE 8081

#Command to run the application
CMD ["java", "-jar", "app.jar"]
```

database-servis dosyası altında Database serverın Dockerfileını kaydedin

```
#Database microservice Dockerfile

#Base image
FROM mysql:latest

#Environment variables
ENV MYSQL_ROOT_PASSWORD=root_password
ENV MYSQL_DATABASE=konzek
ENV MYSQL_USER=konzek_user
ENV MYSQL_PASSWORD=konzek_password

#Expose port
EXPOSE 3306
```

frontend-servis dosyası altında Frontend serverın Dockerfileını kaydedin

```
#Frontend microservice Dockerfile
#Base image
FROM node:14-alpine

#Set working directory
WORKDIR /app

#Copy package.json and package-lock.json
COPY package*.json ./

#Install dependencies
RUN npm install

#Copy source code
COPY . .

#Expose port
EXPOSE 3000

#Command to run the application
CMD ["npm", "start"]
```

Prepare Script for Building Docker Images

Prepare a script to build the docker images and save it as build-docker-images.sh 
```
docker build --force-rm -t "backend-server" ./backend-server
docker build --force-rm -t "frontend-server" ./frontend-server
docker build --force-rm -t "database-server" ./database-server
```
Give execution permission and Build the images.
```
chmod +x build-docker-images.sh 
./build-docker-images.sh
```

Prepare Jenkins Server for CI/CD Pipeline
Set up a Jenkins Server and enable it with Git, Docker, Docker Compose, AWS CLI v2, Python, Ansible and Boto3. To do so, prepare a Terraform file for Jenkins Server with following scripts (jenkins_variables.tf, jenkins-server.tf, jenkins.auto.tf.vars, jenkinsdata.sh) and save them under infrastructure folder.

```
#! /bin/bash
#update os
dnf update -y
#set server hostname as jenkins-server
hostnamectl set-hostname jenkins-server
#install git
dnf install git -y
#install java 11
dnf install java-11-amazon-corretto -y
#install jenkins
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
dnf upgrade
dnf install jenkins -y
systemctl enable jenkins
systemctl start jenkins
#install docker
dnf install docker -y
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user
usermod -a -G docker jenkins
#configure docker as cloud agent for jenkins
cp /lib/systemd/system/docker.service /lib/systemd/system/docker.service.bak
sed -i 's/^ExecStart=.*/ExecStart=\/usr\/bin\/dockerd -H tcp:\/\/127.0.0.1:2376 -H unix:\/\/\/var\/run\/docker.sock/g' /lib/systemd/system/docker.service
systemctl daemon-reload
systemctl restart jenkins
#install docker compose
curl -SL https://github.com/docker/compose/releases/download/v2.17.3/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
#install python 3
dnf install -y python3-pip python3-devel
#install ansible
pip3 install ansible
#install boto3
pip3 install boto3 botocore
#install terraform
wget https://releases.hashicorp.com/terraform/1.4.6/terraform_1.4.6_linux_amd64.zip
unzip terraform_1.4.6_linux_amd64.zip -d /usr/local/bin
```

Get the initial administrative password.
```
sudo cat /var/lib/jenkins/secrets/initialAdminPasswor
```


Create Docker Registry

```yml
- job name: create-ecr-docker-registry-for-dev
- job type: Freestyle project
- Build:
      Add build step: Execute Shell
      Command:
```
```bash
PATH="$PATH:/usr/local/bin"
APP_REPO_NAME="konzek-repo/konzek-app"
AWS_REGION="us-east-1"

aws ecr describe-repositories --region ${AWS_REGION} --repository-name ${APP_REPO_NAME} || \
aws ecr create-repository \
--repository-name ${APP_REPO_NAME} \
--image-scanning-configuration scanOnPush=false \
--image-tag-mutability MUTABLE \
--region ${AWS_REGION}
```
save it as `create-ecr-docker-registry.sh` under `infrastructure` folder.



Create a folder for kubernetes infrastructure with the name of `k8s-terraform` under the `infrastructure` folder.

- Prepare a terraform file for kubernetes Infrastructure consisting of 1 master, 2 Worker Nodes and save it as `main.tf` under the `infrastructure/k8s-terraform`.

```
provider "aws" {
  region  = "us-east-1"
}

variable "sec-gr-mutual" {
  default = "konzek-k8s-mutual-sec-group"
}

variable "sec-gr-k8s-master" {
  default = "konzek-k8s-master-sec-group"
}

variable "sec-gr-k8s-worker" {
  default = "konzek-k8s-worker-sec-group"
}

data "aws_vpc" "name" {
  default = true
}

resource "aws_security_group" "konzek-mutual-sg" {
  name = var.sec-gr-mutual
  vpc_id = data.aws_vpc.name.id

  ingress {
    protocol = "tcp"
    from_port = 10250
    to_port = 10250
    self = true
  }

    ingress {
    protocol = "udp"
    from_port = 8472
    to_port = 8472
    self = true
  }

    ingress {
    protocol = "tcp"
    from_port = 2379
    to_port = 2380
    self = true
  }

}

resource "aws_security_group" "konzek-kube-worker-sg" {
  name = var.sec-gr-k8s-worker
  vpc_id = data.aws_vpc.name.id


  ingress {
    protocol = "tcp"
    from_port = 30000
    to_port = 32767
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol = "tcp"
    from_port = 22
    to_port = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress{
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "kube-worker-secgroup"
  }
}

resource "aws_security_group" "konzek-kube-master-sg" {
  name = var.sec-gr-k8s-master
  vpc_id = data.aws_vpc.name.id

  ingress {
    protocol = "tcp"
    from_port = 22
    to_port = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol = "tcp"
    from_port = 6443
    to_port = 6443
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol = "tcp"
    from_port = 10257
    to_port = 10257
    self = true
  }

  ingress {
    protocol = "tcp"
    from_port = 10259
    to_port = 10259
    self = true
  }

  ingress {
    protocol = "tcp"
    from_port = 30000
    to_port = 32767
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "kube-master-secgroup"
  }
}

resource "aws_iam_role" "konzek-master-server-s3-role" {
  name               = "konzek-master-server-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"]
}

resource "aws_iam_instance_profile" "konzek-master-server-profile" {
  name = "konzek-master-server-profile"
  role = aws_iam_role.konzek-master-server-s3-role.name
}

resource "aws_instance" "kube-master" {
    ami = "ami-053b0d53c279acc90"
    instance_type = "t3a.medium"
    iam_instance_profile = aws_iam_instance_profile.konzek-master-server-profile.name
    vpc_security_group_ids = [aws_security_group.konzek-kube-master-sg.id, aws_security_group.konzek-mutual-sg.id]
    key_name = "konzek"
    subnet_id = "subnet-044c8606449d46359"  # select own subnet_id of us-east-1a
    availability_zone = "us-east-1a"
    tags = {
        Name = "kube-master"
        Project = "tera-kube-ans"
        Role = "master"
        Id = "1"
        environment = "dev"
    }
}

resource "aws_instance" "worker-1" {
    ami = "ami-053b0d53c279acc90"
    instance_type = "t3a.medium"
    vpc_security_group_ids = [aws_security_group.konzek-kube-worker-sg.id, aws_security_group.konzek-mutual-sg.id]
    key_name = "konzek"
    subnet_id = "subnet-044c8606449d46359"  # select own subnet_id of us-east-1a
    availability_zone = "us-east-1a"
    tags = {
        Name = "worker-1"
        Project = "tera-kube-ans"
        Role = "worker"
        Id = "1"
        environment = "dev"
    }
}

resource "aws_instance" "worker-2" {
    ami = "ami-053b0d53c279acc90"
    instance_type = "t3a.medium"
    vpc_security_group_ids = [aws_security_group.konzek-kube-worker-sg.id, aws_security_group.konzek-mutual-sg.id]
    key_name = "konzek"
    subnet_id = "subnet-044c8606449d46359"  # select own subnet_id of us-east-1a
    availability_zone = "us-east-1a"
    tags = {
        Name = "worker-2"
        Project = "tera-kube-ans"
        Role = "worker"
        Id = "2"
        environment = "dev"
    }
}

output kube-master-ip {
  value       = aws_instance.kube-master.public_ip
  sensitive   = false
  description = "public ip of the kube-master"
}

output worker-1-ip {
  value       = aws_instance.worker-1.public_ip
  sensitive   = false
  description = "public ip of the worker-1"
}

output worker-2-ip {
  value       = aws_instance.worker-2.public_ip
  sensitive   = false
  description = "public ip of the worker-2"
}
```


 Commit the change, then push the terraform file (main.tf) to the remote repo.

# "CI/CD İş Akışı"

This script shouldn't be used in one time. It should be applied step by step
```
#Environment variables
PATH="$PATH:/usr/local/bin"
ANS_KEYPAIR="petclinic-ansible-test.key"
AWS_REGION="us-east-1"
export ANSIBLE_PRIVATE_KEY_FILE="${WORKSPACE}/${ANS_KEYPAIR}"
export ANSIBLE_HOST_KEY_CHECKING=False
#Create key pair for Ansible
aws ec2 create-key-pair --region ${AWS_REGION} --key-name ${ANS_KEYPAIR} --query "KeyMaterial" --output text > ${ANS_KEYPAIR}
chmod 400 ${ANS_KEYPAIR}
#Create infrastructure for kubernetes
cd infrastructure/k8s-terraform
terraform init
terraform apply -auto-approve -no-color
#Install k8s cluster on the infrastructure
ansible-playbook -i ./ansible/inventory/dev_stack_dynamic_inventory_aws_ec2.yaml ./ansible/playbooks/k8s_setup.yaml
#Build, Deploy, Test the application
#Tear down the k8s infrastructure
cd infrastructure/k8s-terraform
terraform destroy -auto-approve -no-color
#Delete key pair
aws ec2 delete-key-pair --region ${AWS_REGION} --key-name ${ANS_KEYPAIR}
rm -rf ${ANS_KEYPAIR}
```

```
mkdir -p ansible/inventory
```
- Prepare static inventory file with name of `hosts.ini` for Ansible under `ansible/inventory` folder using Docker machines private IP addresses.
```
<Nodeların Private IPlerini yazıyoruz>   ansible_user=ubuntu  
<Nodeların Private IPlerini yazıyoruz>   ansible_user=ubuntu
<Nodeların Private IPlerini yazıyoruz>   ansible_user=ubuntu
```

Prepare dynamic inventory file with name of `dev_stack_dynamic_inventory_aws_ec2.yaml` for Ansible under `ansible/inventory` folder using ec2 instances private IP addresses.

```
plugin: aws_ec2
regions:
  - "us-east-1"
filters:
  tag:Project: tera-kube-ans
  tag:environment: dev
  instance-state-name: running
keyed_groups:
  - key: tags['Project']
    prefix: 'all_instances'
  - key: tags['Role']
    prefix: 'role'
hostnames:
  - "ip-address"
compose:
  ansible_user: "'ubuntu'"
```


Create an ansible playbook to install kubernetes and save it as `k8s_setup.yaml` under `ansible/playbooks` folder.


```yaml
- hosts: all
  become: true
  tasks:

  - name: change hostnames
    shell: "hostnamectl set-hostname {{ hostvars[inventory_hostname]['private_dns_name'] }}"

  - name: Enable the nodes to see bridged traffic
    shell: |
      cat << EOF | sudo tee /etc/sysctl.d/k8s.conf
      net.bridge.bridge-nf-call-ip6tables = 1
      net.bridge.bridge-nf-call-iptables = 1
      net.ipv4.ip_forward                 = 1
      EOF
      sysctl --system

  - name: update apt-get
    shell: apt-get update

  - name: Install packages that allow apt to be used over HTTPS
    apt:
      name: "{{ packages }}"
      state: present
      update_cache: yes
    vars:
      packages:
      - apt-transport-https  
      - curl
      - ca-certificates

  - name: update apt-get and install kube packages
    shell: |
      curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg && \
      echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list && \
      apt-get update -q && \
      apt-get install -qy kubelet=1.28.2-1.1 kubeadm=1.28.2-1.1 kubectl=1.28.2-1.1 kubernetes-cni docker.io
      apt-mark hold kubelet kubeadm kubectl

  - name: Add ubuntu to docker group
    user:
      name: ubuntu
      group: docker

  - name: Restart docker and enable
    service:
      name: docker
      state: restarted
      enabled: yes

  # change the Docker cgroup driver by creating a configuration file `/etc/docker/daemon.json` 
  # and adding the following line then restart deamon, docker and kubelet

  - name: change the Docker cgroup
    shell: |
      mkdir /etc/containerd
      containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1
      sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml

  - name: Restart containerd and enable
    service:
      name: containerd
      state: restarted
      enabled: yes


- hosts: role_master
  tasks:
      
  - name: pull kubernetes images before installation
    become: yes
    shell: kubeadm config images pull

  - name: initialize the Kubernetes cluster using kubeadm
    become: true
    shell: |
      kubeadm init --pod-network-cidr=10.244.0.0/16 --ignore-preflight-errors=All
    
  - name: Setup kubeconfig for ubuntu user
    become: true
    command: "{{ item }}"
    with_items:
     - mkdir -p /home/ubuntu/.kube
     - cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
     - chown ubuntu:ubuntu /home/ubuntu/.kube/config

  - name: Install flannel pod network
    remote_user: ubuntu
    shell: kubectl apply -f https://github.com/coreos/flannel/raw/master/Documentation/kube-flannel.yml

  - name: Generate join command
    become: true
    command: kubeadm token create --print-join-command
    register: join_command_for_workers

  - debug: msg='{{ join_command_for_workers.stdout.strip() }}'

  - name: register join command for workers
    add_host:
      name: "kube_master"
      worker_join: "{{ join_command_for_workers.stdout.strip() }}"

  - name: install Helm 
    shell: |
      cd /home/ubuntu
      curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
      chmod 777 get_helm.sh
      ./get_helm.sh

- hosts: role_worker
  become: true
  tasks:

  - name: Join workers to cluster
    shell: "{{ hostvars['kube_master']['worker_join'] }}"
    register: result_of_joining

  - debug: msg='{{ result_of_joining.stdout }}'
```




  ### Prepare Kubernetes YAML Files

Create a `docker-compose.yml` under `k8s-helm` folder with the following content as to be used in conversion the k8s-helm files.

```
version: '3'
services:
  frontend-server:
    image: "{{ .Values.IMAGE_TAG_FONTEND_SERVER }}"
    ports:
     - 3000:3000
    labels:
      kompose.image-pull-secret: "regcred"
  backend-server:
    image: "{{ .Values.IMAGE_TAG_BACKEND_SERVER }}"
    ports:
     - 8081:8081
    labels:
      kompose.image-pull-secret: "regcred"
      kompose.service.expose: "{{ .Values.DNS_NAME }}"
      kompose.service.expose.ingress-class-name: "nginx"
      kompose.service.type: "nodeport"
      kompose.service.nodeport.port: "30001"
  database-server:
    image: mysql:5.7.8
    environment: 
      MYSQL_ROOT_PASSWORD: konzek
      MYSQL_DATABASE: konzek
    ports:
    - 3306:3306
```

* Install [conversion tool](https://kompose.io/installation/) named `Kompose` on your Jenkins Server. [User Guide](https://kompose.io/user-guide/#user-guide)
  
```
curl -L https://github.com/kubernetes/kompose/releases/download/v1.31.2/kompose-linux-amd64 -o kompose
chmod +x kompose
sudo mv ./kompose /usr/local/bin/kompose
kompose version
```

## Install Helm [version 3+](https://github.com/helm/helm/releases) on Jenkins Server. [Introduction to Helm](https://helm.sh/docs/intro/). [Helm Installation](https://helm.sh/docs/intro/install/).
```
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version
```
###Helm, Kubernetes için bir paket yöneticisi ve uygulama dağıtım platformudur. Kubernetes'e kurulum, yapılandırma ve yönetim işlemlerini kolaylaştırmak için kullanılır. Helm, "chart" adı verilen paketler aracılığıyla Kubernetes uygulamalarını tanımlar ve yönetir.
#Helm'in temel bileşenleri şunlardır:
#Charts: Bir Helm paketi olan "chart"lar, Kubernetes uygulamalarını tanımlar. Her bir chart, uygulamanın kurulumunu, yapılandırmasını ve yönetimini tanımlayan dosyaları içerir. Bu dosyalar genellikle YAML formatında olup, Kubernetes kaynaklarını (örneğin, Deployment'lar, Service'ler, ConfigMap'ler vb.) tanımlar.
#Helm CLI (Command Line Interface): Helm CLI, kullanıcıların Helm komutlarını kullanarak chartları yönetmelerini sağlar. Bu komutlar aracılığıyla chartları arama, yükleme, kurulum, güncelleme ve kaldırma gibi işlemler gerçekleştirilebilir.
#Helm Repositories: Helm repositories, Helm chartlarının depolandığı yerlerdir. Resmi Helm repositories'ler yanı sıra kullanıcılar kendi özel repositories'lerini oluşturabilirler.
#Release: Bir chart'ın bir Kubernetes kümesindeki bir örneğine "release" denir. Bir release, belirli bir chart'ın belirli bir Kubernetes ortamına kurulumunu temsil eder. Her release, chart'ın kurulumunu ve yapılandırmasını temsil eden bir dizi Kubernetes kaynağına karşılık gelir.
#Helm, karmaşık Kubernetes uygulamalarının dağıtımını kolaylaştırırken, yapılandırma yönetimini ve sürüm kontrolünü de sağlar. Bu da geliştiricilere ve sistem yöneticilerine uygulamalarını daha hızlı ve güvenilir bir şekilde dağıtmalarına yardımcı olur.


```
helm create konzek_chart
```
#k8s-helm içinde bu komutu çalıştırıp helm chartları oluşturacağız.

```
rm -r konzek_chart/templates/*
```
#konzek_chart/templates oluşunca altındaki tüm dosyaları sileceğiz.
```
kompose convert -f docker-compose.yml -o konzek_chart/templates
```
#docker-compose.yml'i dönüştürerek k8s-helm/konzek_chart/templates oluşturulacak.
#Bu adımlar sayesinde chartlar oluştu ve şimdi bu chartlar için AWS S3 de chart repo oluşturacağız.


#S3de bir bucket oluşturup  stable/myapp adında bir klasör oluşturun. Bu modeldeki örnek,
#s3://konzek-helm-charts-konzek/stable/myapp adresini hedef chart reposu olarak kullanır.
```
aws s3api create-bucket --bucket konzek-helm-charts-konzek --region us-east-1
aws s3api put-object --bucket konzek-helm-charts-konzek --key stable/myapp/
```

#Install the helm-s3 plugin for Amazon S3.
```
helm plugin install https://github.com/hypnoglow/helm-s3.git
```

#On some systems we need to install ``Helm S3 plugin`` as Jenkins user to be able to use S3 with pipeline script.
```

sudo su -s /bin/bash jenkins
export PATH=$PATH:/usr/local/bin
helm version
helm plugin install https://github.com/hypnoglow/helm-s3.git
exit
```
#``Initialize`` the Amazon S3 Helm repository.
```
AWS_REGION=us-east-1 helm s3 init s3://konzek-helm-charts-konzek/stable/myapp 
```

#Komut, belirtilen konumda saklanan tüm grafik bilgilerini izlemek için bir index.yaml dosyası oluşturur.
#Oluşturulan index.yaml dosyasının varlığını doğrulayın.
```
aws s3 ls s3://konzek-helm-charts-konzek/stable/myapp/
```

#Add the Amazon S3 repository to Helm on the client machine. 
```
helm repo ls
AWS_REGION=us-east-1 helm repo add stable-konzekapp s3://konzek-helm-charts-konzek/stable/myapp/
```

#Update `version` and `appVersion` field of `k8s/konzek_chart/Chart.yaml` file as below for testing.

```yaml
version: 0.0.1
appVersion: 0.1.0
```

#``Package`` the local Helm chart.
```
cd k8s-helm
helm package konzek_chart/ 
```
#Store the local package in the Amazon S3 Helm repository.
```
HELM_S3_MODE=3 AWS_REGION=us-east-1 helm s3 push ./konzek_chart-0.0.1.tgz stable-konzekapp
```
#Push the new version to the Helm repository in Amazon S3.
```
HELM_S3_MODE=3 AWS_REGION=us-east-1 helm s3 push ./konzek_chart-0.0.2.tgz stable-konzekapp
```

#Verify the updated Helm chart.
```
helm repo update
helm search repo stable-konzekapp

```

 ### CI/CD Pipeline
Jenkinse bağlanıp Pipeline seçtik. SCM de Git seçip github repo adresimizi , Branchımızı ve jenkinsfile pathini  ayarladık ve çalıştırdık.

```
pipeline {
    agent any
    
    environment {
        APP_NAME = "konzek"
        APP_REPO_NAME = "konzek-repo/${APP_NAME}-app"
        AWS_REGION = "us-east-1"
        AWS_ACCOUNT_ID = sh(script: 'aws sts get-caller-identity --query Account --output text', returnStdout: true).trim()
        ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        ANS_KEYPAIR = "konzek-${APP_NAME}-${BUILD_NUMBER}.key"
        ANSIBLE_PRIVATE_KEY_FILE = "${WORKSPACE}/${ANS_KEYPAIR}"
        ANSIBLE_HOST_KEY_CHECKING = "False"
    }
    
    stages {
        stage('Create ECR Repo') {
            steps {
                echo "Creating ECR Repo for ${APP_NAME} app"
                sh """
                aws ecr describe-repositories --region ${AWS_REGION} --repository-name ${APP_REPO_NAME} || \
                aws ecr create-repository \
                    --repository-name ${APP_REPO_NAME} \
                    --image-scanning-configuration scanOnPush=true \
                    --image-tag-mutability MUTABLE \
                    --region ${AWS_REGION}
                """
            }
        }
        
        stage('Prepare Tags for Docker Images') {
            steps {
                echo 'Preparing Tags for Docker Images'
                sh ". ./prepare-tags-ecr-for-docker-images.sh"
            }
        }
        
        stage('Build App Docker Images') {
            steps {
                echo 'Building App Dev Images'
                sh ". ./jenkins/build-docker-images-for-ecr.sh"
                sh 'docker image ls'
            }
        }
        
        stage('Push Images to ECR Repo') {
            steps {
                echo "Pushing ${APP_NAME} App Images to ECR Repo"
                sh ". ./jenkins/push-docker-images-to-ecr.sh"
            }
        }
        
        stage('Create Key Pair for Ansible') {
            steps {
                echo "Creating Key Pair for ${APP_NAME} App"
                sh "aws ec2 create-key-pair --region ${AWS_REGION} --key-name ${ANS_KEYPAIR} --query KeyMaterial --output text > ${ANS_KEYPAIR}"
                sh "chmod 400 ${ANS_KEYPAIR}"
            }
        }
        
        stage('Deploy App on Kubernetes Cluster') {
            steps {
                echo 'Deploying App on Kubernetes Cluster'
                sh '. ./k8s-manifestfiles.sh'
            }
        }
    }
    
    post {
        always {
            echo 'Deleting all local images'
            sh 'docker image prune -af'
        }
    }
}
```




