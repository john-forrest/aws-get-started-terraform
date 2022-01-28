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

##Word about users

The configs generally work with aws profiles (i.e. setup using aws configure with
keys and secrets from IAM). The following profiles are expected:
- Developer - supposed to represent typical developer
- Infra - infrastructure/cloud network engineer
- Admin - infra plus the ability to create usergroups

These could all be the same user.
