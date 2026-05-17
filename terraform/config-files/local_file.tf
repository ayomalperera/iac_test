resource "local_file" "pet" {
  filename= "/root/pets.txt"
  content= "we love pets"
}
