terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"

  ## v Everything between the comments is localstack specific v
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  s3_force_path_style         = true
  skip_requesting_account_id  = true

  endpoints {
    s3 = "http://localhost:4566"
  }
  ## ^ Everything between the comments is localstack specific ^
}

locals {
  bucket_name = "bucket-new"
}

resource "aws_s3_bucket" "dev" {
  bucket = "${var.dev_prefix}-${local.bucket_name}"

  force_destroy = true
}

resource "aws_s3_bucket_website_configuration" "dev" {
  bucket = aws_s3_bucket.dev.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_acl" "dev" {
  bucket = aws_s3_bucket.dev.id

  acl = "public-read"
}

resource "aws_s3_bucket_policy" "dev" {
  bucket = aws_s3_bucket.dev.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "s3:GetObject"
            ],
            "Resource": [
                "arn:aws:s3:::${aws_s3_bucket.dev.id}/*"
            ]
        }
    ]
}
EOF
}

resource "aws_s3_object" "dev" {
  acl          = "public-read"
  key          = "index.html"
  bucket       = aws_s3_bucket.dev.id
  content      = file("${path.module}/../assets/index.html")
  content_type = "text/html"
}
