##This terraform file is for creating resources to store terraform remote state files/
This terraform file creates two resources s3 & dynamodb to store the tfstate files.

Steps to run the file.
---One time setup only-----
1.From your local machine ,run terraform init  &  then do terraform apply
2.This will create two resources s3 & dynamodb & stores the tfstate files in local backend.
3.To move these files to S3 :
Uncomment these line starting in main.tf
#terraform {
#  backend "s3" {
#    # Replace this with your bucket name!
#    bucket         = "tf-state-ref"
#    key            = "ref-env/tf-state-setup/terraform.tfstate"
#    # Replace this with your DynamoDB table name
#    dynamodb_table = "tf-state-ref-locks"
#    encrypt        = true
#  }
#}
4.save the file main.tf  & ensure proper access has been setup
terraform init -backend-config=../ref-env.tfvars &  then do terraform apply -var-file=../ref-env.tfvars
------------------------------
