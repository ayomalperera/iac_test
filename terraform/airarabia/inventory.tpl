[loadbalancer]
lb01 ansible_host=${haproxy_public_ip}

[apache]
web01 ansible_host=${web01_private_ip}

[nginx]
web02 ansible_host=${web02_private_ip}

[webservers:children]
apache
nginx

[all:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/id_ed25519
ansible_python_interpreter=/usr/bin/python3

[webservers:vars]
ansible_ssh_common_args='-o ProxyJump=ubuntu@${haproxy_public_ip}'
