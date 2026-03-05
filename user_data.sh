#!/bin/bash
set -euxo pipefail

yum update -y
amazon-linux-extras install -y nginx1

echo "MGN Lab Source Server" > /usr/share/nginx/html/index.html
echo "ok" > /usr/share/nginx/html/health

systemctl enable nginx
systemctl start nginx
