# 9-Pizza-App-Config-v2

This is v2 of the Pizza App Config and is in prepearation for V2 of the auto-scaler - where the
auto-scaler parameters come from the config file rather than being hardwired.

The settings have been added to the main config.json file. That is partly for convenience.
Alternatives would be to use yet another configuration file, or perhaps even clearer yet
another bucket. The advantage of the latter is, for real, different teams could control these
files, but for this exercise it is not worth the hassle.

This config is purely to setup a bucket to hold central config values for the applications
side of this project.

To support this we again need:

    export TF_VAR_network_remote_state=NETWORK_S3_BUCKET
    export TF_VAR_applications_remote_state=APPLICATIONS_S3_BUCKET
    export TF_VAR_remote_state_region=REMOTE_STATE_REGION

(where S3_NETWORK_BUCKET was the related output from pizza-networking-remote-state,
APPLICATIONS_S3_BUCKET that from pizza-apps-remote-state, and REMOTE_STATE_REGION
the region that module was built with)

To initialise:

    terraform init -backend-config="profile=app" -backend-config="bucket=${TF_VAR_applications_remote_state}" -backend-config="region=${TF_VAR_remote_state_region}" -backend-config="dynamodb_table=pizza-app-tfstatelock-${TF_VAR_applications_remote_state#pizza-app-tfstate-}"
