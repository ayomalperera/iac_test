#

# Ansible Infrastructure Setup

This project deploys:

- NGINX web servers
- Apache web servers
- HAProxy load balancer
- Common server configurations

## Structure

- inventories/ → inventory files
- playbooks/ → playbooks
- roles/ → reusable roles

## Run Playbooks

### Run Full Deployment

```bash
ansible-playbook site.yml



 Install apache:
 https://www.ansiblepilot.com/articles/deploy-a-web-server-apache-httpd-virtualhost-on-debian-like-systems-ansible-modules-apt-copy-service-and-ufw/

https://www.learnlinux.tv/getting-started-with-ansible-14-roles/
