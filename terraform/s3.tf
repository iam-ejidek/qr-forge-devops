# S3 Bucket for backups
resource "aws_s3_bucket" "qr_forge_backups" {
  bucket = "qr-forge-backups-${random_string.bucket_suffix.result}"

  tags = {
    Name = "QR Forge Backups"
    App  = "QR-Forge"
  }
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket_versioning" "qr_forge_backups" {
  bucket = aws_s3_bucket.qr_forge_backups.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "qr_forge_backups" {
  bucket = aws_s3_bucket.qr_forge_backups.id

  rule {
    id     = "delete-old-backups"
    status = "Enabled"

    expiration {
      days = 30
    }
  }
}
