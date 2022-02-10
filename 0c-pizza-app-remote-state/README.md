# Pizza Applications Remote State

Like the network remote state module, this config is purely to setup a bucket and
dynamodb table to hold the central state, so the config can be changed from different
machines and does not depend on local state. However this table is for application
support, and is separated so that a different userset has write access.

To avoid the bootstrap actions associated with the network remote state table, the
state for this module is itself added to the network table remote state table rather
than being "self hosted". That means that it can be added to a remote state table
"out-of-the-box".

To initialise:
- terraform init -backend-config="profile=admin" -backend-config="bucket=S3_BUCKET" -backend-config="region=eu-west-2" -backend-config="dynamodb_table=DYNAMODB_STATELOCK" (substituting S3_BUCKET and DYNAMODB_STATELOCK with the outputs
from the pizza-app-remote-state module).
- Save the outputs - they will be needed to setup the remote init on any subsequent application config.

As with the network remote state table, these resources and in particular the S3 bucket,
should not be destroyed. Thus "force_destroy" is set to false.
