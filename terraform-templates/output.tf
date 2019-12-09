// Output
output "lb_endpoint" {
  value = aws_elb.master.dns_name
}