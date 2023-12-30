resource "tls_private_key" "bastion-ssh" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_file" "bastion_host_user_ssh_key" {
  filename = "${aws_key_pair.bastion_key.key_name}.pem"
  content = tls_private_key.bastion-ssh.private_key_pem
}