#!/bin/bash
sudo yum install -y httpd
sudo sed -i 's/Listen 80/Listen 8080/' /etc/httpd/conf/httpd.conf
echo ${server_text} | sudo tee /var/www/html/index.html
sudo systemctl start httpd
sudo systemctl enable httpd