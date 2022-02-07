
## 5-create-ami

This equates to the "Creating an Amazon Machine Image" demo in Module 4 of the AWS Developer: Getting Started Course.

The summary of the manual instructions in the original:
- Go to EC2 and "Instances"
    - Select the "pizza-og" instance and "Actions"
	    - Select "Image and Templates" and "Image"
        - Name image "pizza-image"
		- Leave image storage size set to default 8GB.
		- Click "Create"

The terraform pulls in the id of the pizza-og instance from the backend state and then
uses the aws_ami_from_instance resource to create the AMI, which is somewhat simplified
compared to the alternative aws_ami - the latter has got a lot more options.

To support this we again need:

	export TF_VAR_applications_remote_state=APPLICATIONS_S3_BUCKET
	export TF_VAR_remote_state_region=REMOTE_STATE_REGION

(where APPLICATIONS_S3_BUCKET that from pizza-apps-remote-state, and REMOTE_STATE_REGION
the region that module was built with)

To initialise:

    terraform init -backend-config="profile=app" -backend-config="bucket=${TF_VAR_applications_remote_state}" -backend-config="region=${TF_VAR_remote_state_region}" -backend-config="dynamodb_table=pizza-app-tfstatelock-${TF_VAR_applications_remote_state#pizza-app-tfstate-}"

Note possible gotcha from documentation:

> Note that the source instance is inspected only at the initial creation of this resource. Ongoing updates to the referenced instance will not be propagated into the generated AMI. Users may taint or otherwise recreate the resource in order to produce a fresh snapshot.

This would probably mean:

    terraform taint aws_ami_from_instance.pizza-image
