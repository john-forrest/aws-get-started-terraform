# aws-get-started-terraform

Redo some of the examples from pluralsight course
[AWS Developer Getting Started](https://app.pluralsight.com/library/courses/aws-developer-getting-started/table-of-contents)
but using terraform. It is not designed to be used on its own - the assumption is that
you will have subscribed to this course.

As an exercise, this repeats some of the demo material from the course mentioned, using
techniques described in "Implementing Terraform with AWS" plus, to a lesser extent,
"Terraform - Getting Started" and "Terraform Deep Dive".

The demos for these courses are all on github, variously:
- https://github.com/ryanmurakami/pizza-luvrs
- https://github.com/ned1313/Implementing-Terraform-on-AWS.git
- https://github.com/ned1313/Getting-Started-Terraform
- https://github.com/ned1313/Deep-Dive-Terraform

Disclaimer: This stuff is a personal exercise to try and use the various techniques. No more.
Both sets of examples are distributed under the MIT license - see disclaimer under
https://opensource.org/licenses/MIT. The code in this repo is similar - assumption is that
it can be mined for "how to" approaches, but no warranty as to suitability is given nor
to the material in the comments.

Having said that, the comments include summaries of the verbal instuctions from the
[AWS Developer Getting Started]
(https://app.pluralsight.com/library/courses/aws-developer-getting-started/table-of-contents)
course itself. The original material will be under copyright as such,
but the assumption that this amounts to fair use. Whatever, I would encourage you
to subscribe to the course.

## Word about users

The configs generally work with aws profiles (i.e. setup using aws configure with
keys and secrets from IAM). The following profiles are expected:
- Developer - supposed to represent typical developer
- Infra - infrastructure/cloud network engineer
- Admin - infra plus the ability to create usergroups

These could all be the same user. Note that some of the configs contain potential lists
of users, e.g. to set S3 access. These need to be real users. Either edit the lists
or edit the usergroups that are selected afterwards - generally any access will be
given to a usergroup and not an individual user, as that makes things easier to update
if users are added or deleted subsequently.

## Terraform infrastructure modules

The following modules support terraform (in that they would probably not be needed
if were not using terraform as such). They are needed before the work proper, and
must be "built" in the given order:
- 0a-pizza-networking-remote-state - add S3 resources to allow the terraform state data
for network modulesto be held in AWS, so removing the problems of local data accidentally
being wiped.
- 0b-pizza-networking-config - add S3 bucket to allow some settings to be held centrally.
Again for network/infrastructure.
- 0c-pizza-app-remote-state - similar for pizza-networking-remote-state but for
application related stuff.
- 0d-pizza-app-config - configurations for application related stuff.

Note: the distinction between intrastructure and applications can be a bit mute
when it comes to things like security groups. Take taken here is that the vpc,
subnets etc will be infrastruture. Instances, load balancers, autoscale groups,
supporting databases and filestores etc are application. For when in doubt,
things like security groups added to support the vpc/firewall etc would be
infrastructure. One added related to application instances would typically
be added as part of the main application config. In real life, different
organisations might do things differently.

Also note that if we start to use workspace, that none of these configs should
have separate workspaces - they are all in the category where to support
workspaces, in other configs, multiple files of the correct name are added
to the single, default environment.

## Replacement for Pizza Demos

The following are designed to replace the various Pizza demos to as reasonably
near in terraform. They don't aim to be exact, just near enough. They use what
the author of the Terraform courses, mentioned above, refers to as a "layered
approach" - rather than a single project that build everything, several
Terraform configs generate the various resources on AWS, so can be separately
built and replaced.

Also note the various demos use a trick - rather than modify the original
files, you can have a new version of a configuration in a second directory
providing they use the same configuration in the backend. You'd not do this
for a real project, where it makes more sense to save changes "in situ".
However, for this case, where we want to track the buildup, it makes perfect
sense.

The terraform is not a complete replacement for manual intervention. The
course itself is designed on the basis of deploying the app by creating a
"gold image" that can be deployed. Those steps will still be manual.

The demos:
- 1-setup-vpc - setup vpc (Module 4, creating VPC demo equivalent)
- 2-setup-vpc-v2 - Update to 1-setup-vpc with better terraform
- 3-create-ec2-instance - create first EC2 VM (pizza-og). (Module 4, Creating EC2 Instance)
- 4-create-elastic-ip - creating EIP to talk to pizza-og instance.
(Module 4, Connecting to an EC2 Instance)
- "Module 4, Updating and Deploying to an EC2 Instance", is still as the course -
i.e. done manually.
- 5-create-ami - create AMI based on manually updated pizza-og instance.
- 6-create-loadbalancer - Follow the demo to create the autobalancer that uses
pizza-og as the backend (no autoscaler)
- 7-create-loadbalancer-v2 - Update without using pizza-og - setup to allow
for autoscaler to be plugged in.
- 8-autoscale - Autoscaler demo
- 9-pizza-app-config-v2 - updated application config with autoscaler parameters added.
- 10-autoscale-v2 - updated autoscale config that users application config.json
- 11-create-bucket - Create bucket for pizza-luvrs
- 12-bucket-content - add assets to bucket using tensorflow (alternative to video)
- 13-ec2-role - first part of "Having All the Things in S3"
- 14-create-ec2-instance-v2 - bonus step: add role to pizza-og for testing
- 15-create-ami-v2 - create "pizza-plus-s3" ami
- 16-autoscale-v3 - final part of "Having All the Things in S3"

## Notes

- During the development of this, the latest version of the AWS resources
went from v3.x to v4.x with somewhat different parameters in places. I have kept this
so far on v3.x. The following is useful in trying to look at the appropriate
[documentation](https://registry.terraform.io/providers/hashicorp/aws/3.74.2/docs)
- by default, the terraform documentation just shows the latest.
