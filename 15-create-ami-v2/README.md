
## 15-create-ami-v2

This is the next part of the "Having All the Things in S3 : Accessing S3 with EC2" demo in Module 5 of
AWS Developer: Getting Started Course.

The summary of the manual instructions in the video is virtually the same as the original
(the only difference being the name used):
- Go to EC2 and "Instances"
    - Select the "pizza-og" instance and "Actions"
	    - Select "Image and Templates" and "Image"
        - Name image "pizza-plus-s3"
		- Leave image storage size set to default 8GB.
		- Click "Create"

With terraform things are a little more complex. Indeed, apart from the fact it means
we save the ami to use in the backend, using terraform for this might not be the best
idea. The complexity is two fold:
- As mentioned in the previous version, running "terraform plan" after a successful apply stage,
but with the same parameters, does nothing even if you have changed pizza-og in the
meantime. (Although changing the name would be seen as an update). To get a new
AMI you need to use either "terraform taint" or "terraform destroy".
- Even using "terraform taint" will lead to the existing AMI being destroyed when we
create a new one. There is no inherrent versioning system for this in either aws, terraform
or the aws provider - there have been [proposals on the subject](https://github.com/hashicorp/terraform/issues/15672),
but not seemingly for the real requirement to create versioning.

The suggested approach is that, if the existing AMI is yet to be used or, for whatever
reason you don't want to keep it, you call:

    terraform taint aws_ami_from_instance.pizza-image

If you are using the existing AMI, or for whatever reason you want to keep it, you
call:

    terraform state rm aws_ami_from_instance.pizza-image

Both to be called before calling "terraform plan". Note that the latter is not ideal -
it orphans the AMIs so that they are no longer tidied up by "terraform destroy" - but
that seems the best thing to do in that circumstance.

To support this we again need:

	export TF_VAR_applications_remote_state=APPLICATIONS_S3_BUCKET
	export TF_VAR_remote_state_region=REMOTE_STATE_REGION

(where APPLICATIONS_S3_BUCKET that from pizza-apps-remote-state, and REMOTE_STATE_REGION
the region that module was built with)

To initialise:

    terraform init -backend-config="profile=app" -backend-config="bucket=${TF_VAR_applications_remote_state}" -backend-config="region=${TF_VAR_remote_state_region}" -backend-config="dynamodb_table=pizza-app-tfstatelock-${TF_VAR_applications_remote_state#pizza-app-tfstate-}"

