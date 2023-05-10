output "vpc_id" {
  value = aws_vpc.tf-vpc.id

}

output "public_subnets" {
  value = aws_subnet.public_subnets[*].id

}

output "private_subnets" {
  value = aws_subnet.private_subnets[*].id

}
output "public_route_table" {
  value = aws_route_table.public_route_table.id

}
output "private_route_table" {
  value = aws_route_table.private_route_table.id

}
output "aws_internet_gateway" {
  value = aws_internet_gateway.myigw.id
}
output "aws_nat_gateway" {
  value = aws_nat_gateway.tf-nat.id

}