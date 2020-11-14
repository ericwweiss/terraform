provider "aws" {
  region = var.region
  access_key = var.access_key
  secret_key = var.secret_key
  token = var.token
  assume_role {
    role_arn = var.role_arn
  }
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "tf-state-gts"
  # Enable versioning so we can see the full revision history of our
  # state files
  versioning {
    enabled = true
  }
  # Enable server-side encryption by default
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "tf-state-gts-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}
###Optionally uncomment the below blocks to move the state file to s3.
# terraform {
# backend "s3" {
#    # Replace this with your bucket name!
#    bucket         = "tf-state-gts"
#    key            = "tf-gts/tf-state-setup/terraform.tfstate"
#    # Replace this with your DynamoDB table name!
#    dynamodb_table = "tf-state-gtx-locks"
#    encrypt        = true
#  }
#}
