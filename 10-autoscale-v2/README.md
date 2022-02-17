
## 10-autoscale-V2

This is V2 following on from 8-autoscale, which in turn reflects the "Creating an Auto 
Scaling Group" demo in Module 4 of the AWS Developer: Getting Started Course. 

This is a more terraform-friendly version of the config, where the parameters for
the autoscaler come from the application config (as updated in 9-pizza-app-config-v2)
instead of being hardwired. Otherwise no change.

To support this we again need:

    export TF_VAR_network_remote_state=NETWORK_S3_BUCKET
    export TF_VAR_applications_remote_state=APPLICATIONS_S3_BUCKET
    export TF_VAR_remote_state_region=REMOTE_STATE_REGION

(where S3_NETWORK_BUCKET was the related output from pizza-networking-remote-state,
APPLICATIONS_S3_BUCKET that from pizza-apps-remote-state, and REMOTE_STATE_REGION
the region that module was built with)

To initialise:

    terraform init -backend-config="profile=app" -backend-config="bucket=${TF_VAR_applications_remote_state}" -backend-config="region=${TF_VAR_remote_state_region}" -backend-config="dynamodb_table=pizza-app-tfstatelock-${TF_VAR_applications_remote_state#pizza-app-tfstate-}"
