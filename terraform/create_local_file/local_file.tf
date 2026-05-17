resource "local_file" "pet" {
  filename = "/root/pets.txt"
  file_permission = "0700"  
  content = "we love pets"
}

resource "random_password" "password" {
  length           = 5 
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}
