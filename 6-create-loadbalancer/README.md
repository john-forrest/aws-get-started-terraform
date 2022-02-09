
## 6-create-load-balancer

This covers a the "Creating a Load Balancer" demo in Module 4 of the AWS Developer:
Getting Started Course. Note in the course this is part of a series of demos for
creating the Load Balancer and the subsequent Auto Scaling Group. We are going
to split them and then extend in a following section.

The manual instructions for this in the original (quite long) are as follows
- Go to EC2 and "Load Balancers" (under Resources on the Dashboard)
    - Select "Create Load Balancer"
	    - Choose "Application Load Balancer"
	    - Name this "pizza-loader"
		- Leave as "Internet facing" and "ipv4"
		- Under "Listeners", leave as listening on port 80
		- Select "pizza-vpc", both availability zones and the subnets in each zones
		- Ignore warning about not using https
	- In next screen, create a new security group
	    - Name this "pizza-lb-sg"
		- Keep default rule of accepting port 80 from anywhere
	- In next screen, select "New Target Group"
	    - Name "pizza-tg"
		- Type (leave) Instances
		- Protocol "HTTP"
		- Port "3000" (not 80)
		- Protocol version (leave) HTTP1
		- On Health checks, leave as HTTP and path "/"
	- In next screen "Register Targets"
		- Select "pizza-og" and "Add to registered" (on port 3000)
	- Next etc to reach "Review" and "Create"
- Go to "Target Groups" and select "pizza-tg"
    - Select "Attributes" and "Edit"
	    - Select "Stickiness" for the algorithm.
		- Leave duration as 1 day
		- Save

The basic requirements are:
- An application load balancer named "pizza-loader", 
- This listens on port 80 (http only)
- Accept port 80 from anywhere (add security group if needs for this)
- Associate with our pizza-vpc and all its subnets
- Add target group (pizza-tg?)
- Forward to port 3000 on that target group
- Add existing pizza-og instance to the target group
- Add health check to http "/" (if we can/need)
- Target group to use "stickiness" algorithm for 1 day (not that we need with 1 instance)

To implement this in terraform we have some basic options:
1. Try and reproduce the above as closely as possible
2. Copy a standard terraform example, possibly one from one of the referenced courses.
3. Use a standard module, as one probably would for real unless you have specific requirements.

Given this is expected to be of practical use, it would seem to be better to take approach (3)
and use the [semi-official alb module](https://registry.terraform.io/modules/terraform-aws-modules/alb/aws/latest).
Similarly rather than build the security group(s) up from scratch, it might bee seen to use
the [semi-official security group module](https://registry.terraform.io/modules/terraform-aws-modules/security-group/aws/latest),
whose usage seems to be closer to that of the web pages then the resources themselves.
The documentation for the alb module is not totally clear in parts, but it seems that
the target_groups field reflects [aws_lb_target_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group)
objects, and the targets options within that represents [aws_lb_target_group_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group_attachment).

To support this we again need:

    export TF_VAR_network_remote_state=NETWORK_S3_BUCKET
	export TF_VAR_applications_remote_state=APPLICATIONS_S3_BUCKET
	export TF_VAR_remote_state_region=REMOTE_STATE_REGION

(where S3_NETWORK_BUCKET was the related output from pizza-networking-remote-state,
APPLICATIONS_S3_BUCKET that from pizza-apps-remote-state, and REMOTE_STATE_REGION
the region that module was built with)

To initialise:

    terraform init -backend-config="profile=app" -backend-config="bucket=${TF_VAR_applications_remote_state}" -backend-config="region=${TF_VAR_remote_state_region}" -backend-config="dynamodb_table=pizza-app-tfstatelock-${TF_VAR_applications_remote_state#pizza-app-tfstate-}"

Note that we get an extra demo stage for this, not shown in the original video, where
this load balancer will run talking to "pizza-og" as the sole EC2 instance. Copy and
paste the "pizza-loader-dns-name" output (from the end of terraform apply) to your
browser. Providing "npm start" is running on pizza-og, you should see the app.
