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
