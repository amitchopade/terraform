#! /bin/bash
sudo mkdir -p /var/www/html/
sudo yum update -y
sudo yum install -y httpd docker
sudo service httpd start
sudo yum install docker start
sudo docker run -d -p 3000:3000 --name grafana grafana/grafana:6.5.0
sudo usermod -a -G apache ec2-user
sudo chown -R ec2-user:apache /var/www
sudo yum install -y mysql php php-mysql
sudo yum update -y
sudo yum-config-manager --enable epel
sudo yum install ansible -y
sudo git clone https://github.com/amitchopade/terraform/
echo "<h1>Deployed via Terraform</h1>" | sudo tee /var/www/html/index.html
sudo ansible-playbook main.yml
