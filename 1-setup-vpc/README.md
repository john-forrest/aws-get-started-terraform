
## 1-Setup-VPC

This equates to the "Creating a VPC" demo in Module 4 of the AWS Developer: Getting Started Course.

The summary of the manual instructions in the original:
- Ensure in correct region
- Create a new VPC with a single subnet
    - CIDR Block: 10.0.0.0/16
    - VPC Name: pizza-vpc
    - Subnet CIDR: 10.0.0.0/24
    - Availability zone: first in the list
    - Subnet name: pizza-subnet-a
	- Enable DNS hostnames: yes
- Add a route table to the created vpc
    - In addition to the default (10.0.0.0/16 to local) add:
	    - 0.0.0.0/16 -> Internet Gateway
		- Select default gateway for the vpc when prompted
- Create second subnet for our vpc:
    - Name: pizza-subnet-b
	- Availability zone: second in the list
	- CIDR Block: 10.0.1.0/24

The instructions make a play of not using a NAT block for cost purposes but
to enable public IP addresses for subnets instead.

To replicate the able in terraform, we could do it from scratch, as described
in the Getting Started in Terraform course. However, as mentioned in this course,
it is probably more useful to run with the semi-official aws vpc module. The
flip side of that, naturally, is less control as to what is created - for the
terraform we will tell it to provide two public subnets. The fact that the module
can (and probably will) default to using subnets is ignored. "Semi-official"
refers to the fact the the modules themselves are community controlled, but
the resources they sit on are official.

This (initial) version is fairly straight forward, using few terraform tricks.
To use, run the following:

    terraform init -backend-config="profile=infra" -backend-config="bucket=S3_BUCKET" -backend-config="region=eu-west-2" -backend-config="dynamodb_table=DYNAMODB_STATELOCK"

(substituting S3_BUCKET and DYNAMODB_STATELOCK with the outputs from pizza-networking-remote-state).

