# 12-Bucket-Content

This covers the "Uploading objects to S3" demo in Module 5 of the AWS Developer:
Getting Started Course.

The basic instructions here are to copy assets/js, assets/css and assets/pizza to
js, css and pizza directories at the top of the bucket. In the video, this is done
using the aws cli. Also assets/toppings and some extra files are uploaded via the
web UI. Those options always available. However this config loads the content via
terraform instead.

To use this, create a directory "content" in this directory and then copy all the
content of "assets" in the original source to that directory (so we have content/js,
content/css etc).

If you are working on Windows, since the target is Linux, you might want to change
the line endings for the *.js and *.css files to be newline - Linux-style. Not as
such required - we've already used those files "as is" up to this point, but it
would be more consistent.

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
