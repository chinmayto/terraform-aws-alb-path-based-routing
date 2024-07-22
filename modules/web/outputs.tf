output "instance_ids" {
  value = aws_instance.web.*.id
}

output "instance_ids_other" {
  value = aws_instance.web_other.*.id
}