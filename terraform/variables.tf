# -----------------------------------------------------------------------
# General
# -----------------------------------------------------------------------
variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "employee-hub"
}

variable "environment" {
  description = "Deployment environment (dev, staging, production, demo)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "production", "demo"], var.environment)
    error_message = "Environment must be one of: dev, staging, production, demo."
  }
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-south-1"
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default = {
    Project     = "employee-hub"
    ManagedBy   = "terraform"
    Environment = "dev"
    Owner       = "bala.nagireddy"
  }
}

# -----------------------------------------------------------------------
# EC2
# -----------------------------------------------------------------------
variable "instance_type" {
  description = "EC2 instance type (t3.micro is Free Tier eligible)"
  type        = string
  default     = "t3.micro"
}

variable "key_pair_name" {
  description = "Optional EC2 key pair name for SSH access. If null, use SSM Session Manager."
  type        = string
  default     = null
}

variable "allowed_ssh_cidr" {
  description = "CIDR blocks allowed to SSH into the EC2 instance. Restrict to your IP in production."
  type        = list(string)
  default     = ["0.0.0.0/0"]

  # WARNING: 0.0.0.0/0 is for development only.
  # Restrict to your public IP in production (e.g., ["203.0.113.42/32"]).
}

variable "grafana_allowed_cidr" {
  description = "CIDR blocks allowed to access Grafana (port 3001). Restrict to trusted IPs in production."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "prometheus_allowed_cidr" {
  description = "CIDR blocks allowed to access Prometheus (port 9090). Restrict to trusted IPs in production."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# -----------------------------------------------------------------------
# RDS PostgreSQL
# -----------------------------------------------------------------------
variable "db_username" {
  description = "RDS PostgreSQL master username"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.db_username) >= 3 && can(regex("^[a-zA-Z][a-zA-Z0-9_]*$", var.db_username))
    error_message = "db_username must be at least 3 characters and start with a letter."
  }
}

variable "db_password" {
  description = "RDS PostgreSQL master password (8-128 chars)"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.db_password) >= 8 && length(var.db_password) <= 128
    error_message = "db_password must be between 8 and 128 characters long."
  }

  # validation {
  #   condition     = can(regex("[A-Z]", var.db_password))
  #   error_message = "db_password must contain at least one uppercase letter."
  # }

  # validation {
  #   condition     = can(regex("[a-z]", var.db_password))
  #   error_message = "db_password must contain at least one lowercase letter."
  # }

  # validation {
  #   condition     = can(regex("[0-9]", var.db_password))
  #   error_message = "db_password must contain at least one digit."
  # }

  # validation {
  #   condition     = can(regex("^\\S+$", var.db_password))
  #   error_message = "db_password must not contain spaces."
  # }
}

variable "db_name" {
  description = "RDS PostgreSQL database name"
  type        = string
  default     = "employee_db"

  validation {
    condition     = can(regex("^[a-zA-Z_][a-zA-Z0-9_]*$", var.db_name))
    error_message = "db_name must start with a letter or underscore and contain only alphanumeric characters or underscores."
  }
}

