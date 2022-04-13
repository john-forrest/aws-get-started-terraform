
## 13-ec2-role

The following is first of several that relate to demo "Having All the Things in S3 : 
Accessing S3 with EC2". Reality is that this is a somewhat long demo and I count five
separate activities, not all of which quite relate to terraform - whatever, it would
probably have been cleaner to separate them out.

From a terraform viewpoint (and arguably anyway) the order in the video is not ideal.
I am going to thus do this differently. The first section being to create IAM role
"pizza-ec2-role", which gives instances access to (at first) S3.

The manual instructions for this are as follows:
- In IAM, Select Roles>Create Role.
    - Choose service: EC2
	- Next
	- Search for "s3" and select "AmazonS3FullAccess"
	- Next x 2
	- Give name: pizza-ec2-role

A key thing to realise about this is that "AmazonS3FullAccess" is basically an existing,
named policy.

To support this we again need:

    export TF_VAR_network_remote_state=NETWORK_S3_BUCKET
    export TF_VAR_applications_remote_state=APPLICATIONS_S3_BUCKET
    export TF_VAR_remote_state_region=REMOTE_STATE_REGION

(where S3_NETWORK_BUCKET was the related output from pizza-networking-remote-state,
APPLICATIONS_S3_BUCKET that from pizza-apps-remote-state, and REMOTE_STATE_REGION
the region that module was built with)

To initialise:

    terraform init -backend-config="profile=app" -backend-config="bucket=${TF_VAR_applications_remote_state}" -backend-config="region=${TF_VAR_remote_state_region}" -backend-config="dynamodb_table=pizza-app-tfstatelock-${TF_VAR_applications_remote_state#pizza-app-tfstate-}"

Note how to use the created role is not obvious. A useful note on how to do that given [here](https://skundunotes.com/2021/11/16/attach-iam-role-to-aws-ec2-instance-using-terraform)

