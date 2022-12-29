#!/bin/bash

# Get SSH configuration 
echo "Fetching Robpress Git details for ${ROBPRESS_USER}"
/wait-for-it.sh -t 120 gateway:9004 -- echo "Gateway is ready"
curl -kH 'Host: autoconfig.robpress.ecs.soton.ac.uk' "https://gateway:9004/?username=${ROBPRESS_USER}&password=${ROBPRESS_PASSWORD}" > ~/.ssh/robpress_rsa
chmod 700 ~/.ssh
chmod 600 ~/.ssh/robpress_rsa

# Remove old RobPress
/wait-for-it.sh -t 120 gateway:9005 -- echo "Gateway is ready"
echo "Removing old RobPress files that are not in git"
rm -rf /var/www/html/*
rm -rf /var/www/html/{,.[!.],..?}*

# Get new RobPress
echo "Fetching Robpress files for ${ROBPRESS_USER}"
export GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no -p 9005 -i ~/.ssh/robpress_rsa"
git clone ${ROBPRESS_USER}@gateway:./public_html /var/www/html;

# Setup git configuration
echo "Updating RobPress git configuration"
export GIT_WORK_TREE="/var/www/html"
git config core.sshCommand "ssh -o StrictHostKeyChecking=no -p 9005 -i ~/.ssh/robpress_rsa"
git config pull.rebase false
git config user.email "${ECS_USER}@soton.ac.uk"
git config user.name "${ECS_USER}"

# Make changes
echo "Updating RobPress files"
sed -ri -e 's!localhost!db!g' /var/www/html/config/db.cfg

# Install database
echo "Updating RobPress database"
/wait-for-it.sh -t 120 db:3306 -- echo "Database is ready"
mysql -h 'db' -u${ROBPRESS_USER} -p${ROBPRESS_PASSWORD} ${ROBPRESS_USER} < /var/www/html/install.sql

# Run RobPress
echo "Running RobPress"
exec apache2-foreground
