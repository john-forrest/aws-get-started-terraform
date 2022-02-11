
## 3b-create-ec2-instance

This equates part 2 of "Creating EC2 Instance" demo in Module 4 of the AWS Developer: Getting Started Course,
the part that actually creates the instance. 

See section 3a for the manual instructions. Remember that we already created the security groups
in that section, so this section just creates the instance - the natural creation order in the
terraform is often different to the way you might do it manually via the web.

The terraform seeks to do this to a reasonable extent. As with the last vpc setup, much of
the stuff comes from the config files, and the vpc and subnet ids come from the vpc backend
state on S3. For this reason, we need to both network and application remote state:

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

Warning: if you allocate a public IP to this instance going forward (e.g. see next config
"4-create-elastic-ip"), then the natural tendency of terraform rerunning this config is
to destroy the instance and recreate - it sees the image as changed. The special lifecycle
clause is to stop this happening. Similarly if there is a new version of the AMI - we
could take it, but it would throw away the mods we've made and is generally not the thing
to do without thought we've saved anything. If you do want to recreate this, use:

    terraform taint aws_instance.pizza-og
