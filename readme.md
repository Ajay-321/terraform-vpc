In this article, we will be creating AWS VPC, Public and Private Subnets, Internet Gateway, Nat Gateway, and Route Tables for Public and Private Subnets using Terraform.

What is VPC?

AWS VPC (Virtual Private Cloud) is a networking service provided by Amazon Web Services (AWS) that allows users to create a virtual private network in the AWS cloud. It supports Ipv4 and ipv6 type CIDR blocks.

We can launch various AWS resources like Ec2 Instances, RDS, and Lambda Functions, ECS, EKS in VPC within private subnets as per best security practices.

What is Subnet?

A subnet is a subdivision of a Virtual Private Cloud (VPC). A subnet is essentially a range of IP addresses that are assigned to resources within a VPC. Each subnet is associated with a specific availability zone in the region where VPC is created. Subnets can be Public or Private based on routing configurations.

Public Subnets have a route to the internet gateway and allow both ingress and egress traffic.

Private Subnets are not connected to the internet and are used to launch resources that need to be kept private like databases.

What is Terraform?

Terraform is a very popular open-source Infrastructure as a code (IAC) tool developed by Hashicorp. It provides developers and operations teams to configure and manage their infrastructure as code and automate the creation and deployment of infrastructure in a repeatable and consistent manner with many cloud providers like AWS, GCP, Azure, and on-prem infrastructure.

Pre-requisites:

AWS Account and IAM Credentials with required Access.

Terraform Binary: link

AWS CLI: link

Basic knowledge of AWS VPC and Terraform

Terraform is written in Hashicorp Configuration Language (HCL), which is an immutable-based programming language.

![image](https://github.com/Ajay-321/terraform-vpc/assets/62708804/89e82b02-777e-436e-880e-e4d7c489945e)

Let's understand terraform configuration files that will be used for provisioning VPC and its components.

Provider Block:
In Terraform, a provider is a plugin that allows Terraform to interact with a specific infrastructure provider, such as AWS, Azure, or Google Cloud Platform. A provider typically includes API endpoints, authentication credentials, and other configuration details required to interact with a particular provider's resources.


Note: IAM Programmatic User with VPC Full access will be required.

provider.tf:
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}
provider "aws" {
  region     = "YOUR_REGION"
  access_key = "ACCESS_KEY_ID"
  secret_key = "SECRET_KEY_ID"
}

Note: Please don't share IAM credentials on Public platforms like GitHub. We can also configure AWS CLI locally and create an IAM profile and use it in the provider section below
provider "aws" {
  profile = "profile_name"
}

variables.tf :

variable.tf is used to declare input variables that will be referenced in terraform configuration file by referencing its name. Variables allow us to parameterize Terraform code and make it more flexible, reusable, and configurable.

variable "prefix" {
  default = "terraform-practice"

}

variable "region" {
  default = "us-east-1"

}

variable "vpc_cidr" {
  default = "10.0.0.0/16"

}

variable "azs" {
  type    = list(string)
  default = []

}
variable "private_subnets" {
  type    = list(string)
  default = []

}

variable "public_subnets" {
  type    = list(string)
  default = []
}

terraform.tfvars :

terraform.tfvars is used to set values for the input variables defined in variables.tf. This file is optional but highly recommended, as it allows you to easily specify input variable values when running terraform apply or terraform plan without having to specify them on the command line.

region          = "us-east-1"
prefix          = "terraform-practice"
azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

I have defined a list data type variable containing the subnet CIDRs and utilized the 'count' parameter along with 'count.index' to reference these CIDRs for each availability zone.

vpc.tf:

vpc.tf file is used to create a VPC resource in AWS with the specified properties, such as the CIDR block, instance tenancy, DNS hostnames, and tags.
resource "aws_vpc" "tf-vpc" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_hostnames = true

  tags = {
    Name = "${var.prefix}-VPC"
  }
}

Terraform Configuration File for Private Subnet:

To create subnets for 3 Availability Zones with unique CIDR ranges, we can pass the availability zones and subnet CIDRs using a list or map data type. In this example, I have utilized a list data type that is indexed and starts with '0'. To create the subnets in each availability zone with unique CIDR ranges, we can use the 'count' meta-argument with the 'length' function to create subnets based on the number of elements in the list.

resource "aws_subnet" "private_subnets" {
  vpc_id            = aws_vpc.tf-vpc.id
  count             = length(var.private_subnets)
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name = "${var.prefix}-private-subnet-${var.azs[count.index]}"
  }
}

Terraform Configuration File for Public Subnet:

I have used a similar approach for creating public subnets.

resource "aws_subnet" "public_subnets" {
  vpc_id                  = aws_vpc.tf-vpc.id
  count                   = length(var.public_subnets)
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.prefix}-public-subnet-${var.azs[count.index]}"
  }
}

Internet Gateway can be used as a target for routing rules that enable instances in the VPC to communicate with the internet and vice versa. Below is the tf file for creating an internet gateway.

resource "aws_internet_gateway" "myigw" {
  vpc_id = aws_vpc.tf-vpc.id

  tags = {
    Name = "${var.prefix}-internet-gateway"
  }
}

Terraform Configuration File for NAT gateway :

The NAT Gateway provides Internet access to resources in private subnets by allowing egress traffic only. The below terraform configuration file will create a NAT gateway and allocate one EIP. The depends_on parameter creates an explicit dependency on the Internet Gateway resource, which ensures that the NAT Gateway is created after the Internet Gateway is created.

resource "aws_nat_gateway" "tf-nat" {
  allocation_id = aws_eip.tf-eip.id
  subnet_id     = aws_subnet.public_subnets[0].id

  tags = {
    Name = "${var.prefix}-nat-gateway"
  }
  depends_on = [aws_internet_gateway.myigw]
}

Terraform Configuration File for EIP:
resource "aws_eip" "tf-eip" {
  vpc = true
}

Terraform Configuration File for Route Table:

A route table contains a set of rules, called routes, that determine where network traffic from your subnet or gateway is directed. In the Terraform configuration file below, we are creating a Public route table with a route to the internet gateway.
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.tf-vpc.id
  tags = {
    Name = "${var.prefix}-public-route-table"
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myigw.id
  }
}

Terraform Configuration File for Private Route Table:

The gateway id in the route section will be changed to NAT Gateway for private route tables.
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.tf-vpc.id
  tags = {
    Name = "${var.prefix}-private-route-table"
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.tf-nat.id

  }
}

Terraform Configuration File for Route Table Association for Public Subnets in each AZs:

To associate the public and private subnets in the Route table, we can use the element function along with the count meta argument to retrieve each subnet ID based on the index number. The element function retrieves a single element from a list, allowing us to associate each subnet with its respective routing configuration.

resource "aws_route_table_association" "public_route_association" {
  count          = length(var.public_subnets)
  subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
  route_table_id = aws_route_table.public_route_table.id

}

Terraform Configuration File for Route Table association for Private subnets in each AZ:

For the private route table, we are also using the same approach of associating subnets using the element function with the count meta argument to fetch each subnet ID based on the index number.

resource "aws_route_table_association" "private_route_association" {
  count          = length(var.private_subnets)
  subnet_id      = element(aws_subnet.private_subnets[*].id, count.index)
  route_table_id = aws_route_table.private_route_table.id

}

In Terraform, outputs are used to display or retrieve certain information about the infrastructure that has been created or modified. The output command in Terraform is used to define what values are to be outputted, and these values can be displayed after running the terraform apply command.

output.tf:
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

After creating these files in the root folder run the below commands to provision Infra using Terraform.

For downloading provider plugins run:

terraform init

It will download plugins and initialize the working directory

![image](https://github.com/Ajay-321/terraform-vpc/assets/62708804/38b6a703-745f-4930-800c-3012ee0c958d)


For formatting the terraform configuration file run the below command:

terraform fmt

To check the configuration file if that is syntactically valid, run the below command

terraform validate

Now run terraform plan to check the resource configuration which will be provisioned

It will give you output for the resources list which will be created like below

![image](https://github.com/Ajay-321/terraform-vpc/assets/62708804/d8885561-6e11-465d-80d2-8aaba7dae1ce)

![image](https://github.com/Ajay-321/terraform-vpc/assets/62708804/7b53b5e1-fff1-4643-92e9-c5ba45f94df4)

Now run terraform apply and validate the changes and type "yes' to approve the request or run the below command
terraform apply --auto-approve

Now resources will be provisioned
![image](https://github.com/Ajay-321/terraform-vpc/assets/62708804/dede6d18-e5c5-4628-99b9-ecf8f437de4d)


Output for provisioned resources:

![image](https://github.com/Ajay-321/terraform-vpc/assets/62708804/dc6d470e-a816-4813-844e-70e2ee9f7487)

Now all resources have been successfully provisioned which were declared in terraform configuration files. To verify login into the AWS console and check.

For example:

