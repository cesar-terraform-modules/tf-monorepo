variable "cluster_name" {
  description = "Name of the ECS cluster. If create_cluster is true, this will be the name of the new cluster. Otherwise, it's the name of an existing cluster"
  type        = string
}

variable "create_cluster" {
  description = "Whether to create a new ECS cluster"
  type        = bool
  default     = true
}

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights for the cluster"
  type        = bool
  default     = true
}

variable "task_family" {
  description = "Family name for the task definition"
  type        = string
}

variable "task_cpu" {
  description = "The number of CPU units used by the task"
  type        = string
  default     = "256"
}

variable "task_memory" {
  description = "The amount of memory (in MiB) used by the task"
  type        = string
  default     = "512"
}

variable "container_definitions" {
  description = "A list of container definitions in JSON format"
  type        = any
}

variable "volumes" {
  description = "A list of volume definitions in JSON format"
  type        = list(any)
  default     = []
}

variable "create_execution_role" {
  description = "Whether to create an execution role for the task"
  type        = bool
  default     = true
}

variable "execution_role_arn" {
  description = "ARN of the task execution role. Required if create_execution_role is false"
  type        = string
  default     = null
}

variable "create_task_role" {
  description = "Whether to create a task role"
  type        = bool
  default     = true
}

variable "task_role_arn" {
  description = "ARN of the task role. Required if create_task_role is false"
  type        = string
  default     = null
}

variable "task_role_additional_policies" {
  description = "List of additional IAM policy ARNs to attach to the task role"
  type        = list(string)
  default     = []
}

variable "service_name" {
  description = "Name of the ECS service"
  type        = string
}

variable "desired_count" {
  description = "Number of instances of the task definition to place and keep running"
  type        = number
  default     = 1
}

variable "platform_version" {
  description = "Platform version on which to run your service"
  type        = string
  default     = "LATEST"
}

variable "deployment_maximum_percent" {
  description = "Upper limit (as a percentage of the service's desiredCount) of the number of running tasks"
  type        = number
  default     = 200
}

variable "deployment_minimum_healthy_percent" {
  description = "Lower limit (as a percentage of the service's desiredCount) of the number of running tasks"
  type        = number
  default     = 100
}

variable "health_check_grace_period_seconds" {
  description = "Seconds to ignore failing load balancer health checks on newly instantiated tasks"
  type        = number
  default     = null
}

variable "subnet_ids" {
  description = "List of subnet IDs for the service"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs for the service"
  type        = list(string)
}

variable "assign_public_ip" {
  description = "Assign a public IP address to the ENI"
  type        = bool
  default     = false
}

variable "load_balancers" {
  description = "List of load balancer configurations"
  type = list(object({
    target_group_arn = string
    container_name   = string
    container_port   = number
  }))
  default = []
}

variable "service_registries" {
  description = "Service discovery registries for the service"
  type = list(object({
    registry_arn   = string
    container_name = optional(string)
    container_port = optional(number)
  }))
  default = []
}

variable "enable_execute_command" {
  description = "Enable Amazon ECS Exec for the service"
  type        = bool
  default     = false
}

variable "enable_blue_green_deployment" {
  description = "Enable CodeDeploy blue/green deployment"
  type        = bool
  default     = true
}

variable "create_codedeploy_role" {
  description = "Whether to create an IAM role for CodeDeploy"
  type        = bool
  default     = true
}

variable "codedeploy_role_arn" {
  description = "ARN of the CodeDeploy role. Required if create_codedeploy_role is false and enable_blue_green_deployment is true"
  type        = string
  default     = null
}

variable "codedeploy_deployment_config" {
  description = "Deployment configuration name for CodeDeploy"
  type        = string
  default     = "CodeDeployDefault.ECSAllAtOnce"
}

variable "codedeploy_auto_rollback_enabled" {
  description = "Enable automatic rollback on deployment failure"
  type        = bool
  default     = true
}

variable "codedeploy_auto_rollback_events" {
  description = "List of events that can trigger automatic rollback"
  type        = list(string)
  default     = ["DEPLOYMENT_FAILURE", "DEPLOYMENT_STOP_ON_ALARM"]
}

variable "codedeploy_deployment_ready_action" {
  description = "Action to take when deployment is ready. Valid values: CONTINUE_DEPLOYMENT, STOP_DEPLOYMENT"
  type        = string
  default     = "CONTINUE_DEPLOYMENT"
}

variable "codedeploy_deployment_ready_wait_time" {
  description = "Wait time in minutes before continuing deployment if action is STOP_DEPLOYMENT"
  type        = number
  default     = 0
}

variable "codedeploy_terminate_blue_action" {
  description = "Action to take on blue instances after deployment. Valid values: TERMINATE, KEEP_ALIVE"
  type        = string
  default     = "TERMINATE"
}

variable "codedeploy_terminate_blue_wait_time" {
  description = "Wait time in minutes before terminating blue instances"
  type        = number
  default     = 5
}

variable "codedeploy_listener_arns" {
  description = "List of ALB/NLB listener ARNs for production traffic"
  type        = list(string)
  default     = []
}

variable "codedeploy_test_listener_arns" {
  description = "List of ALB/NLB listener ARNs for test traffic"
  type        = list(string)
  default     = null
}

variable "codedeploy_blue_target_group_name" {
  description = "Name of the blue target group"
  type        = string
  default     = null
}

variable "codedeploy_green_target_group_name" {
  description = "Name of the green target group"
  type        = string
  default     = null
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
