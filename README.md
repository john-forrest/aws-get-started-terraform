# aws-get-started-terraform
Redo some of the examples from pluralsight course "AWS Developer:Getting Started" using terraform

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
it can be mined for "how to" approaches, but no warranty as to suitability is given.

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
- pizza-networking-remote-state - add S3 resources to allow the terraform state data
for network modulesto be held in AWS, so removing the problems of local data accidentally
being wiped.
- pizza-networking-config - add S3 bucket to allow some settings to be held centrally.
Again for network/infrastructure.
- pizza-app-remote-state - similar for pizza-networking-remote-state but for
application related stuff.

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
build and replaced. 

Also note the various demos use a trick - rather than modify the original
files, you can have a new version of a configuration in a second directory
providing they use the same configuration in the backend. You'd not do this
for a real project, where it makes more sense to save changes "in situ".
However, for this case, where we want to track the buildup, it makes perfect
sense.

The demos:
- 1-
