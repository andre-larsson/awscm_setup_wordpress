#!/bin/bash -x

FSID="$1" # file system id
WSDIR="/var/www/" # root webserver directory

WPDIR="$WSDIR/html" # Wordpress directory

### Mount the EFS drive
# install aws-efs-utils, mount efs drive in folder $WSDIR
yum update -y
yum install -y amazon-efs-utils
mkdir -p "$WSDIR"
mount -t efs -o tls $FSID:/ $WSDIR
mkdir -p "$WPDIR"

## install php, apache, php-gd
amazon-linux-extras install php8.0 -y # php
yum install httpd php-gd -y # apache, php-gd
# new config file with 'AllowOverride All'
cp httpd.conf /etc/httpd/conf/httpd.conf
systemctl restart httpd
systemctl enable httpd
systemctl status httpd