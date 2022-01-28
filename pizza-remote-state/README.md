# Pizza Remote State

This config is purely to setup a bucket and dynamodb table to hold the central state, so the
config can be changed from different machines and does not depend on local state.

There is a certain amount of "chicken and egg" going on here. We want to store the state
centrally but we can only do so once the bucket and lock have been created, and can only
do that once this has run! The approach is thus:
- Run terraform init, plan and apply as normal.
- Record the output (need in further init commands that will use s3 backend)
- Rename/copy backend.tf.forlater to backend.tf
- Run: terraform init -backend-config="profile=admin" -backend-config="bucket=S3_BUCKET" -backend-config="region=eu-west-2" -backend-config="dynamodb_table=DYNAMODB_STATELOCK" (substituting S3_BUCKET and DYNAMODB_STATELOCK with the outputs recorded above.

From this point, the state data will be in S3. Note there is an argument for adding all those config variables to
backend.tf so they are consistent.

These resources, in particular the S3 bucket, should not be destroyed. Thus "force_destroy" is set to false.
