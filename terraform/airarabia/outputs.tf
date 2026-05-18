
output "haproxy_public_ip" {
  value = aws_eip.haproxy_eip.public_ip
}


output "web01_private_ip" {
  value = aws_instance.app_servers["web01"].private_ip
}

output "web02_private_ip" {
  value = aws_instance.app_servers["web02"].private_ip
}
