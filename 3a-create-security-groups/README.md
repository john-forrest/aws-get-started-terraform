
## 3a-create-security-groups

This is the first part of the "Creating EC2 Instance" demo in Module 4 of the AWS Developer: Getting Started Course.

The summary of the manual instructions in the original (all steps):
- Go to EC2
- Select "Launch Instance"
    - Select Amazon 2 HVM image - 64bit x86. (In video, only Kernel 4.14 version was available,
    but at time of writing this included 5.10 too)
    - Select t2.micro (so free tier)
    - Select 1 instance
    - Select pizza-vpc and either of its subnets
    - Disable auto-assign public ip address
    - (Otherwise leave defaults, including for associated storage and the IAM role)
    - Name "pizza-og"
    - Create a new security group for the instance
        - Name "pizza-ec2-sg"
        - Set Description "Security group for pizza-luvrs EC2 instances"
        - Keep the default rule given:
            - Type: SSH, Protocol: TCP, Port Range: 22, Source: Custom: 0.0.0.0/0
            - Notes for now OK but in protoduction either remove or set so only a single IP can access
        - Add new rule:
            - Type: Custom TCP, Protocol: TCP, Port Range: 3000, Source: "Anywhere"
    - Select "Launch"
        - Will be prompted for key pair to be used for access
		- Create a new key/pair
		    - Name "pizza-keys"
		- Select "Launch Instances"
		
In terraform, I am splitting this up into separate configs for a simple reason - the security
groups (including pizza-ec2-sg) are potentially used later on, in other modules. If we have both
security groups and instance in the same config, we cannot use "terraform destroy" to destroy
the instance without the security groups too.

The terraform seeks to do this to a reasonable extent. Note the use of two security groups - it does not seem to be possible to create terraform aws_security_group resources with more than one ingress rule.
Also note the the "pizza" basename for the various entities comes from the application
configuration.

As with the last vpc setup, much of the stuff comes from the config files, and the vpc
and subnet ids come from the vpc backend state on S3. For this reason, we need to both
network and application remote state:

    export TF_VAR_network_remote_state=NETWORKS3_BUCKET
	export TF_VAR_applications_remote_state=APPLICATIONS_S3_BUCKET
	export TF_VAR_remote_state_region=REMOTE_STATE_REGION

(where NETWORK_S3_BUCKET was the related output from pizza-networking-remote-state,
APPLICATIONS_S3_BUCKET that from pizza-apps-remote-state, and REMOTE_STATE_REGION
the region that module was built with)

To initialise:

    terraform init -backend-config="profile=app" -backend-config="bucket=${TF_VAR_applications_remote_state}" -backend-config="region=${TF_VAR_remote_state_region}" -backend-config="dynamodb_table=pizza-app-tfstatelock-${TF_VAR_applications_remote_state#pizza-app-tfstate-}"
