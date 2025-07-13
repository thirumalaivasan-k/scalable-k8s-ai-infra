# modules/control-plane-secondary/main.tf

resource "null_resource" "join_secondary_master" {
  connection {
    type        = "ssh"
    user        = var.ssh_user
    private_key = var.ssh_private_key
    host        = var.ip_address
  }

  provisioner "file" {
    source      = var.join_command_script_path
    destination = "/tmp/join-command.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/join-command.sh",
      "sudo /tmp/join-command.sh"
    ]
  }

  triggers = {
    always_run = timestamp()
  }
}
