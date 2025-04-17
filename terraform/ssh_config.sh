#!/bin/bash

BASTION_IP=$(terraform output -raw bastion)
JENKINS_SLAVE_IP=$(terraform output -raw jenkins_slave)

SSH_CONFIG="$HOME/.ssh/config"

echo "
Host bastion
    HostName $BASTION_IP
    User ubuntu
    IdentityFile ~/.ssh/key1.pem
" > "$SSH_CONFIG"

echo "
Host jenkins-slave
    HostName $JENKINS_SLAVE_IP
    User ubuntu
    IdentityFile ~/.ssh/key1.pem
    ProxyJump bastion
" >> "$SSH_CONFIG"

chmod 600 "$SSH_CONFIG"

echo "done"
