
## 16-autoscale-V3

This is the final part of the "Having All the Things in S3 : Accessing S3 with EC2" demo in Module 5 of
AWS Developer: Getting Started Course.

The remaining manual instructions are:
- Go to EC2 and "Launch Templates"
    - Select pizza-lt
	    - Select Actions > Modify Template
		- Select drop down under "AMI"
		    - Type "pizza-plus" and select "pizza-plus-s3"
		- Under "Advanced Settings", look for "IAM Instance Profile"
		    - under dropdown find pizza-ec2-role
	- Click "Create template version"
- Select "pizza-lt" as before
    - Select Actions > Set Default Version
	    - Select latest (if following the video exactly, will be "2")
		- Click "Set as default version"
- Force update - go to EC2 and Instances and select those instances from autoscaling group
    - Select Actions > Terminate

Our existing terraform for the autoscaler is setup to update the default version and use that,
anyway, so the only update we need to do is to add the role.

Note: if you have destroyed the previous autoscaler in the meantime, you may want to go
back to 10-autoscale-V2, and re-apply it, to reproduce the effect - to do so properly,
you should use the original "pizza-image", overriding the ami-id variable as documented
in that module's readme.

Bonus feature of this terraform config is that it should trigger updates with the new
launch template - you should not have to do so manually, although feel free if you want to.

To support this we again need:

    export TF_VAR_network_remote_state=NETWORK_S3_BUCKET
    export TF_VAR_applications_remote_state=APPLICATIONS_S3_BUCKET
    export TF_VAR_remote_state_region=REMOTE_STATE_REGION

(where S3_NETWORK_BUCKET was the related output from pizza-networking-remote-state,
APPLICATIONS_S3_BUCKET that from pizza-apps-remote-state, and REMOTE_STATE_REGION
the region that module was built with)

To initialise:

    terraform init -backend-config="profile=app" -backend-config="bucket=${TF_VAR_applications_remote_state}" -backend-config="region=${TF_VAR_remote_state_region}" -backend-config="dynamodb_table=pizza-app-tfstatelock-${TF_VAR_applications_remote_state#pizza-app-tfstate-}"

**Tip**: If you need to debug the instances it is sometimes better to force just
having one instance. Also it is sometimes better to use t3 instances instead of t2,
even though they are not free - it is easier to connect to t3. To achieve this, the
following plan command helps:

    terraform plan -out temp.tfplan -var min_size=1 -var max_size=1 -var desired_capacity=1 -var instance_type=t3.micro

