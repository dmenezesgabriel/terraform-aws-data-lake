variable "region" {
  type = string

}

variable "vpc_cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}

variable "ecs_task_desired_count" {
  type = number
}
