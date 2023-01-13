#!/bin/bash

#================#
# For CentOS 7.0 #
#================#

######## CONFIG ##########

user="user"
password="Password"

##########################

# Adding user
/usr/sbin/useradd "$user" -s "/usr/bin/bash" -m -d "/home/$user"

# Adding user & password
echo "$user:$password" | /usr/sbin/chpasswd
usermod -a -G wheel $user
mkdir /home/$user/web /home/$user/.ssh

# Add SSH Authorized KEY
cat << EOF >/home/$user/.ssh/authorized_keys
ssh-rsa AAAAB_RSA_KEYS_PUB
EOF

# Add user SSH Authorized KEY
cat << EOF >/etc/sudoers.d/Init-users
# User SSH Authorized KEY
$user ALL=(ALL)	NOPASSWD: ALL
EOF

# Permissions
chown $user:$user /home/$user/web /home/$user/.ssh
chmod -R o+x /home/$user/
chmod -R 700 /home/$user/
#gpasswd -a nginx $user
chmod -R 700 /home/$user/.ssh
chmod 600 /home/$user/.ssh/authorized_keys