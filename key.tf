resource "aws_key_pair" "bastion_key" {
  key_name   = "bastion_key_name"
  public_key = tls_private_key.bastion-ssh.public_key_openssh
}
