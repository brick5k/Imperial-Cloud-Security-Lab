
# Provider


provider "aws" {
  region = "us-east-1"
}



# IAM Test User


resource "aws_iam_user" "test_user" {
  name = "stormtrooper-user"
}



# S3 Bucket for CloudTrail Logs


resource "aws_s3_bucket" "imperial_logs_bucket" {
  bucket = "imperial-cloud-logs-brock-wagar-2026"
  acl    = "private"
}



# CloudTrail Configuration


resource "aws_cloudtrail" "imperial_cloudtrail" {
  name                          = "imperial-cloudtrail"
  s3_bucket_name                = aws_s3_bucket.imperial_logs_bucket.bucket
  include_global_service_events = true
  is_multi_region_trail         = true
}



# CloudTrail S3 Bucket Policy


data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_policy" "cloudtrail_policy" {
  bucket = aws_s3_bucket.imperial_logs_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = "s3:PutObject"
        Resource = "${aws_s3_bucket.imperial_logs_bucket.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.imperial_logs_bucket.arn
      }
    ]
  })
}



# GuardDuty


 resource "aws_guardduty_detector" "main" {
   enable = true
 }



# Amazon Linux AMI


data "aws_ami" "amazon_linux" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}



# Security Group (SSH Access)


resource "aws_security_group" "imperial_ssh" {
  name        = "imperial-ssh-access"
  description = "Allow SSH from my IP"

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["24.35.154.127/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



# EC2 Instance


resource "aws_instance" "death_star_ec2" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  key_name               = "terraform-ec2"   # Keep unless you create a new key
  vpc_security_group_ids = [aws_security_group.imperial_ssh.id]

  tags = {
    Name = "death-star-instance"
  }
}



# Over Privileged User


resource "aws_iam_user" "rogue_admin" {
  name = "rogue-moff"
}



# Over Privileged Login Profile


resource "aws_iam_user_login_profile" "rogue_admin_login" {
  user = aws_iam_user.rogue_admin.name
}



# Over Privileged Policy Attachment

resource "aws_iam_policy_attachment" "rogue_admin_attach" {
  name       = "rogue-moff-admin-attach"
  users      = [aws_iam_user.rogue_admin.name]
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}