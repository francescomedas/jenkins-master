// Output
output "lb_endpoint" {
  value = aws_lb.master.dns_name
}