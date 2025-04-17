# Create a VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name = "vpc"
  }
}

resource "aws_subnet" "subnets" {
  for_each                = { for subnet in var.subnets : subnet.name => subnet }
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr_block
  map_public_ip_on_launch = each.value.type == "public" ? true : false
  availability_zone       = "${var.region}${each.value.az}"
  tags                    = { "Name" = each.value.name }
}

resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

}

resource "aws_route_table" "private_route" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id
  }

}

resource "aws_route_table_association" "routes_association" {

  for_each       = { for subnet in aws_subnet.subnets : subnet.tags.Name => subnet }
  subnet_id      = each.value.id
  route_table_id = each.value.map_public_ip_on_launch ? aws_route_table.public_route.id : aws_route_table.private_route.id
}
