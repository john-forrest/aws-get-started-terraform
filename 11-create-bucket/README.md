
## 11-create-bucket

This covers the "Creating an S3 Bucket" demo in Module 5 of the AWS Developer:
Getting Started Course. 

The manual instructions for this are:
- Go to "S3", "Buckets", "Create Bucket":
    - Enter a unique name:
	    - pizza-luvrs + a unique string (has to be globally unique)
	- Select region
	    - Use the region we've been generally using
	- Uncheck box "Block all public access" (we want to give this bucket public access)
	    - Tick the checkbox to acknowledge
	- At botton "Create Bucket"
- Select bucket and "Permissions". Fomd "Bucket policy", "Edit" and "Policy Generator"
    - Select "S3 Bucket Policy" as Type of Policy
	- Under Add Statements
	    - Effect "Allow"
		- Principle "*" (who is allowed to access)
		- Actions: select "GetObject" from dropdown
		- For ARN we need to build ourselves following the pattern:
		    - arn:aws:s3:::${BucketName}/*
			    - The "*" means it applies to all objects in the bucket
		Click "Add Statement"
	- Click "Generate Policy"
	- Copy JSON
- Back at the S3 Edit Policy (change tab?), paste the JSON
- Click "Save Change"

Note that the bucket does not have versioning nor encryption enabled - for real you
might want to do the former, but there is no need for the latter.

We've obviously been using buckets up to this point for backend and configuration holding,
and have been using a common module. For this usecase, however, it seems worth rolling
from basic resources - apart from there being buckets, the configuration is somewhat
different.

To support this we again need:

    export TF_VAR_network_remote_state=NETWORK_S3_BUCKET
    export TF_VAR_applications_remote_state=APPLICATIONS_S3_BUCKET
    export TF_VAR_remote_state_region=REMOTE_STATE_REGION

(where S3_NETWORK_BUCKET was the related output from pizza-networking-remote-state,
APPLICATIONS_S3_BUCKET that from pizza-apps-remote-state, and REMOTE_STATE_REGION
the region that module was built with)

To initialise:

    terraform init -backend-config="profile=app" -backend-config="bucket=${TF_VAR_applications_remote_state}" -backend-config="region=${TF_VAR_remote_state_region}" -backend-config="dynamodb_table=pizza-app-tfstatelock-${TF_VAR_applications_remote_state#pizza-app-tfstate-}"

Note: seems that the  "public-read" acl setting confusingly just sets the bucket
access rights and not the content - thus why the extra policy is still required.
