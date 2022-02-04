
## 3-create-elastic-ip

This equates to the "Connecting to an EC2 Instance" demo in Module 4 of the AWS Developer: Getting Started Course.

The summary of the manual instructions in the original:
- Go to EC2 and "Elastic IPs"
    - Select "Allocate Elastic IP Address"
        - (Keep default "Amazon's pool of IPv4 addresses")
	    - Select "Allocate"
	- Select new Elastic IP address and "Actions"
	    - Select Associate Elastic IP Address
		    - Select Instance and "pizza-og" instance
			- Select Private IP dropdown and the single available address
			- "Associate"

The terraform pulls in the id of the pizza-og instance from the backend state and then
just creates the Elastic IP to go with it. Note it might have been tempting to add this
to the pizza-og config, but that means that if we destroy pizza-og we also destroy the EIP.

To support this we again need:

	export TF_VAR_applications_remote_state=APPLICATIONS_S3_BUCKET
	export TF_VAR_remote_state_region=REMOTE_STATE_REGION

(where APPLICATIONS_S3_BUCKET that from pizza-apps-remote-state, and REMOTE_STATE_REGION
the region that module was built with)

To initialise:

    terraform init -backend-config="profile=app" -backend-config="bucket=${TF_VAR_applications_remote_state}" -backend-config="region=${TF_VAR_remote_state_region}" -backend-config="dynamodb_table=pizza-app-tfstatelock-${TF_VAR_applications_remote_state#pizza-app-tfstate-}"

