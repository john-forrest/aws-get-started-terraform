# 12-Bucket-Content

This covers the "Uploading objects to S3" demo in Module 5 of the AWS Developer:
Getting Started Course.

The basic instructions here are to copy assets/js, assets/css and assets/pizza to
js, css and pizza directories at the top of the bucket. In the video, this is done
using the aws cli. That option is always available. However this config loads the
content via terraform instead.

To use this, create a directory "content" in this directory and then copy the above
directories from pizza-luvrs to form content/js, content/css and content/pizza.

To support this we again need:

    export TF_VAR_network_remote_state=NETWORK_S3_BUCKET
    export TF_VAR_applications_remote_state=APPLICATIONS_S3_BUCKET
    export TF_VAR_remote_state_region=REMOTE_STATE_REGION

(where S3_NETWORK_BUCKET was the related output from pizza-networking-remote-state,
APPLICATIONS_S3_BUCKET that from pizza-apps-remote-state, and REMOTE_STATE_REGION
the region that module was built with)

To initialise:

    terraform init -backend-config="profile=app" -backend-config="bucket=${TF_VAR_applications_remote_state}" -backend-config="region=${TF_VAR_remote_state_region}" -backend-config="dynamodb_table=pizza-app-tfstatelock-${TF_VAR_applications_remote_state#pizza-app-tfstate-}"

The next few modules on the course are "as is" as they involve editing the code.
One extra thing to note is if you destroy and recreate the bucket in terraform
you should check the bucket name to see if it has changed - the bucket name
being semi-random. Best practice would be to supply this name as an environment
variable, but that is not the way the code in the course has been designed.
