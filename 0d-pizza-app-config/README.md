# Pizza Network Config

This config is purely to setup a bucket to hold central config values for the applications
side of this project.

This module is expected be built with aws app profile. Just to be clear this is set in the config, but normally
different people would do this and they would use their own config, something like:

export AWS_PROFILE=app

The assumption is that the pizza-networking-remote-state has already been setup, so the
init can be set as:

    terraform init -backend-config="profile=app" -backend-config="bucket=S3_BUCKET" -backend-config="region=eu-west-2" -backend-config="dynamodb_table=DYNAMODB_STATELOCK" (substituting S3_BUCKET and DYNAMODB_STATELOCK with the outputs
from pizza-app-remote-state).

