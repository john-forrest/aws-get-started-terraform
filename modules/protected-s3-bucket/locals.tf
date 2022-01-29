
locals {
  bucket_name = var.bucket_name # local here just to make it easier to change names used if required
  
  common_tags = merge(var.common_tags,
                  {module = "protected-s3-bucket"
			    })
}
