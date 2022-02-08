
## 7-create-load-balancer-v2

In reality, although the "Create Load Balancer" demo added pizza-og to the target
group, we don't want it to. Instead we want to create an autoscaling group and use
the image we generated previously from pizza-og. This module removes the references
to pizza-og and leaves the target group empty.

To support this we again need:

    export TF_VAR_network_remote_state=NETWORK_S3_BUCKET
	export TF_VAR_applications_remote_state=APPLICATIONS_S3_BUCKET
	export TF_VAR_remote_state_region=REMOTE_STATE_REGION

(where S3_NETWORK_BUCKET was the related output from pizza-networking-remote-state,
APPLICATIONS_S3_BUCKET that from pizza-apps-remote-state, and REMOTE_STATE_REGION
the region that module was built with)

To initialise:

    terraform init -backend-config="profile=app" -backend-config="bucket=${TF_VAR_applications_remote_state}" -backend-config="region=${TF_VAR_remote_state_region}" -backend-config="dynamodb_table=pizza-app-tfstatelock-${TF_VAR_applications_remote_state#pizza-app-tfstate-}"

