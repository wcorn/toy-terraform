# Transit Gateway (TGW) 생성
resource "aws_ec2_transit_gateway" "tgw" {
  description                     = "Central Transit Gateway for Hub-and-Spoke model"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  tags = {
    Name = "central-tgw"
  }
}

# Shared VPC Attachment (허브 역할)
resource "aws_ec2_transit_gateway_vpc_attachment" "shared_attachment" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnet_ids
  tags = {
    Name = "shared-tgw-attachment"
  }
}

# Dev VPC Attachment (스포크 역할)
resource "aws_ec2_transit_gateway_vpc_attachment" "dev_attachment" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = data.terraform_remote_state.dev.outputs.vpc_id
  subnet_ids         = data.terraform_remote_state.dev.outputs.private_subnet_ids
  tags = {
    Name = "dev-tgw-attachment"
  }
}

# PROD VPC Attachment (스포크 역할)
resource "aws_ec2_transit_gateway_vpc_attachment" "prod_attachment" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = data.terraform_remote_state.prod.outputs.vpc_id
  subnet_ids         = data.terraform_remote_state.prod.outputs.private_subnet_ids
  tags = {
    Name = "prod-tgw-attachment"
  }
}

# 허브용 라우트 테이블 (Shared VPC)
resource "aws_ec2_transit_gateway_route_table" "hub_rt" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  tags = {
    Name = "hub-rt"
  }
}

# 스포크용 라우트 테이블 (Dev 및 Prod VPC)
resource "aws_ec2_transit_gateway_route_table" "spoke_rt" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  tags = {
    Name = "spoke-rt"
  }
}

# Association: 각 Attachment를 해당 라우트 테이블에 연결
resource "aws_ec2_transit_gateway_route_table_association" "shared_assoc" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.shared_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub_rt.id
}

resource "aws_ec2_transit_gateway_route_table_association" "dev_assoc" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.dev_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke_rt.id
}
resource "aws_ec2_transit_gateway_route_table_association" "prod_assoc" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.prod_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke_rt.id
}
# Propagation: 스포크의 경로 정보를 허브로 전파 및 허브의 경로 정보를 스포크로 전파
# (Dev/Prod → Shared)
resource "aws_ec2_transit_gateway_route_table_propagation" "dev_to_hub" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.dev_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub_rt.id
}
resource "aws_ec2_transit_gateway_route_table_propagation" "prod_to_hub" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.prod_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub_rt.id
}


# (Shared → Dev/Prod)
resource "aws_ec2_transit_gateway_route_table_propagation" "shared_to_spoke" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.shared_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke_rt.id
}

# [허브 라우트 테이블]: Shared VPC에서 Dev와 Prod로 향하는 경로 추가
resource "aws_ec2_transit_gateway_route" "hub_to_dev" {
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub_rt.id
  destination_cidr_block         = data.terraform_remote_state.dev.outputs.vpc_cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.dev_attachment.id
}

resource "aws_ec2_transit_gateway_route" "hub_to_prod" {
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub_rt.id
  destination_cidr_block         = data.terraform_remote_state.prod.outputs.vpc_cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.prod_attachment.id
}

# [스포크 라우트 테이블]: Dev와 Prod는 오직 Shared VPC로의 경로만 가지도록 설정
resource "aws_ec2_transit_gateway_route" "spoke_to_shared_from_dev_prod" {
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke_rt.id
  destination_cidr_block         = module.vpc.vpc_cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.shared_attachment.id
}

resource "aws_route" "dev_private_to_shared" {
  route_table_id         = data.terraform_remote_state.dev.outputs.private_route_table_id
  destination_cidr_block = module.vpc.vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
}

resource "aws_route" "dev_public_to_shared" {
  route_table_id         = data.terraform_remote_state.dev.outputs.public_route_table_id
  destination_cidr_block = module.vpc.vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
}

resource "aws_route" "shared_private_to_dev" {
  route_table_id         = module.vpc.private_route_table_id
  destination_cidr_block = data.terraform_remote_state.dev.outputs.vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
}

resource "aws_route" "shared_public_to_dev" {
  route_table_id         = module.vpc.public_route_table_id
  destination_cidr_block = data.terraform_remote_state.dev.outputs.vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
}

resource "aws_route" "prod_private_to_shared" {
  route_table_id         = data.terraform_remote_state.prod.outputs.private_route_table_id
  destination_cidr_block = module.vpc.vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
}

resource "aws_route" "prod_public_to_shared" {
  route_table_id         = data.terraform_remote_state.prod.outputs.public_route_table_id
  destination_cidr_block = module.vpc.vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
}

resource "aws_route" "shared_private_to_prod" {
  route_table_id         = module.vpc.private_route_table_id
  destination_cidr_block = data.terraform_remote_state.prod.outputs.vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
}

resource "aws_route" "shared_public_to_prod" {
  route_table_id         = module.vpc.public_route_table_id
  destination_cidr_block = data.terraform_remote_state.prod.outputs.vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
}