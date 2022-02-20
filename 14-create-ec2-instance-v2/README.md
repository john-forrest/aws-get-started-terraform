
## 14-create-ec2-instance-v2

This is a "bonus" part of "Having All the Things in S3 : Accessing S3 with EC2". We
are going to add the role we've just created to instance pizza-og itself. That allows
us to test pizza-og properly - otherwise creating a new pizza won't work. The videos
skip doing this and just assume if it works OK locally it will work OK on the autoscaler.

To support this we again need:

    export TF_VAR_network_remote_state=NETWORKS3_BUCKET
	export TF_VAR_applications_remote_state=APPLICATIONS_S3_BUCKET
	export TF_VAR_remote_state_region=REMOTE_STATE_REGION

(where NETWORK_S3_BUCKET was the related output from pizza-networking-remote-state,
APPLICATIONS_S3_BUCKET that from pizza-apps-remote-state, and REMOTE_STATE_REGION
the region that module was built with)

Note we are exporting the main security group, even though we've imported it. This allows
other configs to just use the state of this for info if so needs.

To initialise:

    terraform init -backend-config="profile=app" -backend-config="bucket=${TF_VAR_applications_remote_state}" -backend-config="region=${TF_VAR_remote_state_region}" -backend-config="dynamodb_table=pizza-app-tfstatelock-${TF_VAR_applications_remote_state#pizza-app-tfstate-}"

When you do the plan stage, check that the instance is only being changed (it should not destroy
and add) before applying. After applying re-connect to the instance and call "npm start", and
check using EIP_ADDRESS:3000. Try and create a new pizza - it should work.

Warning (again): we deliberately try and keep the existing instance from being destroyed
in cases where the public IP or original AMI have changed. If you do want to recreate this, use:

    terraform taint aws_instance.pizza-og
