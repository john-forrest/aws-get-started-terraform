
# Bucket name

variable "bucket_name" {
  type        = string
  description = "Name of S3 bucket to create"
}

# Full access users - users will be added to usergroup with read/write access

variable "full_access_users" {
  type    = list(string)
  default = []
}

# Read only users - users will be added to usergroup with read/write access

variable "read_only_users" {
  type    = list(string)
  default = []
}

# Common tags

variable "common_tags" {
  type        = map(string)
  description = "Map of tags to be applied to all resources"
  default     = {}
}
