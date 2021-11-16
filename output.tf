output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "default_sg_id" {
  value = aws_security_group.private.id
}

output "private_security_group_id" {
  value = aws_security_group.private.id
}
output "public_security_group_id" {
  value = aws_security_group.public.id
}

output "private_route_table_ids" {
  value = aws_route_table.private.*.id
}
output "public_route_table_id" {
  value = aws_route_table.public.id
}
output "private_subnet_ids" {
  value = aws_subnet.private_subnet.*.id
}
output "public_subnet_ids" {
  value = aws_subnet.public_subnet.*.id
}
output "route_table_ids" {
  value = concat(aws_route_table.private.*.id, aws_route_table.public.*.id)
}

output "availability_zones" {
  value = data.aws_availability_zones.zones.names
}
