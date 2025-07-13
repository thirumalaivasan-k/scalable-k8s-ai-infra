# ----------------------------
# modules/master-node/outputs.tf
# ----------------------------
output "join_command" {
  value = data.local_file.join_command.content
}

