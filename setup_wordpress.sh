#!/bin/bash -x

FSID="$1" # File system ID
WSDIR="efs_mnt" # mount point for webbserver
DBHOST="$2" # endpoint of RDS database 
DBPASSWORD="${3:-12345678}" # password for database (corresponding to username)
DBUSER="${4:-admin}" # username for database
DBNAME="${5:-WordpressDatabase}" # name of schema in the database

WPDIR="$WSDIR/www/html" # Wordpress directory

### Mount the EFS drive
# install aws-efs-utils, mount efs drive in folder $WSDIR
sudo yum update -y
sudo yum install -y amazon-efs-utils
sudo mkdir -p "$WSDIR"
sudo mount -t efs -o tls $FSID:/ $WSDIR
sudo mkdir -p "$WPDIR"

### Install WordPress on the EFS-drive
wget https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz

### Generate config file for WordPress
cat > wordpress/wp-config.php <<EOF
<?php
define( 'DB_NAME', '$DBNAME' );
define( 'DB_USER', '$DBUSER' );
define( 'DB_PASSWORD', '$DBPASSWORD' );
define( 'DB_HOST', '$DBHOST' );
define( 'DB_CHARSET', 'utf8' );
define( 'DB_COLLATE', '' );

$(curl https://api.wordpress.org/secret-key/1.1/salt/)

\$table_prefix = 'wp_';

define( 'WP_DEBUG', false );

if ( ! defined( 'ABSPATH' ) ) {
	define( 'ABSPATH', __DIR__ . '/' );
}

require_once ABSPATH . 'wp-settings.php';
EOF

sudo cp -r wordpress/* $WPDIR

### Create apache user group and set file permissions
# set file permissions such that Wordpress/apache can read/write to the directory
# see https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-lamp-amazon-linux-2.html
# create group apache
sudo groupadd apache
# add user to group apache
sudo usermod -a -G apache ec2-user
# change owner of $WSDIR to user=ec2-user, group=apache
sudo chown -R ec2-user:apache $WPDIR/
# set directory permissions of $WSDIR and all subdirs (if any)
sudo chmod 2775 $WPDIR/ && find $WPDIR/ -type d -exec sudo chmod 2775 {} \;
# set file permissions in $WSDIR for all files (if any)
find $WPDIR/ -type f -exec sudo chmod 0664 {} \;

# unmount drive
sudo umount efs_mnt/