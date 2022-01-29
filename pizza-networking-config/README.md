# Pizza Network Config

This config is purely to setup a bucket to hold central config values for the networking/infrastructure
side of this project.

This module is expected be built with aws infra profile. Just to be clear this is set in the config, but normally
different people would do this and they would use their own config, something like:

export AWS_PROFILE=infra

The assumption is that the pizza-networking-remote-state has already been setup, so the
init can be set as:
- terraform init -backend-config="profile=infra" -backend-config="bucket=S3_BUCKET" -backend-config="region=eu-west-2" -backend-config="dynamodb_table=DYNAMODB_STATELOCK" (substituting S3_BUCKET and DYNAMODB_STATELOCK with the outputs
from pizza-networking-remote-state).

Note this uses module protected-s3-bucket to minimise the differences between this and the equivalent
for applications.
