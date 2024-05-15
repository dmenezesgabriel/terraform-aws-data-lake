variable "region" {
  description = "AWS region"
  type        = string
}

variable "glue_job_name" {
  description = "Glue job name"
  type        = string
}

variable "glue_job_version" {
  description = "Glue job version"
  type        = string
  default     = "4.0"
}

variable "glue_job_max_retries" {
  description = "Glue job max retries"
  type        = number
  default     = 0
}

variable "glue_job_number_of_workers" {
  description = "Glue job number of workers"
  type        = number
  default     = 2
}

variable "glue_job_worker_type" {
  description = "Glue job worker type"
  type        = string
  default     = "G.1X"
}

variable "glue_job_worker_timeout" {
  description = "Glue job worker timeout"
  type        = string
  default     = "60"
}

variable "glue_job_worker_execution_class" {
  description = "Glue job worker execution class"
  type        = string
  default     = "FLEX"
}


variable "glue_job_source_file_path" {
  description = "Glue job source file path"
  type        = string
}

variable "glue_job_bucket" {
  description = "Glue job bucket id"
  type        = string
}

