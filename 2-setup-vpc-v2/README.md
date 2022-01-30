
## 2-setup-vpc-v2

This is an improved version of 1-Setup-VPC - improved from a terraform viewpoint,
with no real change to the AWS resources added.

The differences are as follows:
- The vpc CIDR should come from the pizza-networking-config module, as the number
of subnets and the number of bits to use for the subnets.
- The CIDRs for the subnets should be calculated.
- The tags to use should (again) come from the pizza-networking-config.

We are going to need to get at the config bucket. We could pass this as another parameter,
but it makes more sense to tell the config where the bucket is which holds the state data
for pizza-networking-config, i.e. the bucket for pizza-networking-remote-state, and it 
can then go and find the rest out. On face value, this seems to be setting about the same
amount of data, but longer term we can/will use this one setting multiple times:

    export TF_VAR_network_remote_state=S3_BUCKET
	export TF_VAR_remote_state_region=REMOTE_STATE_REGION)

(where S3_BUCKET was the related output from pizza-networking-remote-state and REMOTE_STATE_REGION
the region that module was built with)

With this in mind we can (assume bash is being used) update the terraform init line
to use this data rather than (as has happened to date) edit the line each time:

    terraform init -backend-config="profile=infra" -backend-config="bucket=${TF_VAR_network_remote_state}" -backend-config="region=${TF_VAR_remote_state_region}" -backend-config="dynamodb_table=pizza-tfstatelock-${TF_VAR_network_remote_state#pizza-tfstate-}"
