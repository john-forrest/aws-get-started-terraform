
## 8-autoscale

This covers a the "Creating an Auto Scaling Group" demo in Module 4 of the AWS Developer:
Getting Started Course. It follows on from "Creating a Load Balancer". In the original
this is broken up partly because otherwise the demo would be far too long. Here it
seems makes sense anyway to split, to the autoscale is layered on the load balancer,
and for this config to use what is now an existing load balancer.

The manual instructions for this are:
- Go to EC2 and "Auto Scaling Groups"
    - Create "Auto Scaling Group"
        - Name: pizza-asg
        - Create launch template
            - Name: "pizza-lt"
            - Under the AMI section, type "pizza-image" and select the image you have already corrected
            - Select instance type "t2.micro"
            - Add pizza-keys as the key pair (so can troubleshoot during development)
            - Under "Network settings", leave "VPC" selected
            - For Security groups, select "pizza-ec2-sg" (any instance created will be given this security group)
            - Expand advanced data and under User Data:

                \#!/bin/bash
                echo "starting pizza-luvrs"
                cd /home/ec2-user/pizza-luvrs
                npm start

            - "Create Launch Template"
        - Back on Auto Scaling Group creation, refresh the list next to "Launch Template" and
        select "pizza-lt"
        - Next. Under network select "pizza-vpc" and both subsets
        - Select "Attach to existing load balancer" and then, in target group, select "pizza-tg".
        - Next. Group Size, Select Desired=2, Min=2, Max=4.
        - Select Target tracking scaling policy. Name "Target Tracking Policy". Metric type
        "Average network out (bytes). Target value "5000".
        - Several Nexts. Get to Review. "Create Auto Scaling Group".


It is tempting to use the [semi-official autoscaling module](https://registry.terraform.io/modules/terraform-aws-modules/autoscaling/aws/latest)
similar to what we've done elsewhere. However, it is fair to say that the use of this
module is not so obvious as the others - the documentation is less clear, there are
multiple not-so-obvious arguments, and generally it feels less well structrured.

Instead it is probably better to do this from screatch - at least the launch template.
Having said that, with terraform, it is not obviously so clear if for launch template
is the correct thing to use rather than a "launch configuration", but we will persist
with the original demo as much as possible. Note that the setting of the scaling policy,
which on the Web interface is an integral part of creating an Auto Scaling Group, in
terraform involves yet another resource - and the parameters are somewhat more complex
to setup.

To support this we again need:

    export TF_VAR_network_remote_state=NETWORK_S3_BUCKET
    export TF_VAR_applications_remote_state=APPLICATIONS_S3_BUCKET
    export TF_VAR_remote_state_region=REMOTE_STATE_REGION

(where S3_NETWORK_BUCKET was the related output from pizza-networking-remote-state,
APPLICATIONS_S3_BUCKET that from pizza-apps-remote-state, and REMOTE_STATE_REGION
the region that module was built with)

To initialise:

    terraform init -backend-config="profile=app" -backend-config="bucket=${TF_VAR_applications_remote_state}" -backend-config="region=${TF_VAR_remote_state_region}" -backend-config="dynamodb_table=pizza-app-tfstatelock-${TF_VAR_applications_remote_state#pizza-app-tfstate-}"

Note: aws_launch_template is a strange resource in that it adds a new version
rather than create a new template. Without "update_default_version=true", the
default is unchanged. If we don't set this, it is important to quote the version
we want.