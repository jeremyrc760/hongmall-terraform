
# Existing alarm — imported into Terraform
resource "aws_cloudwatch_metric_alarm" "sandbox_ec2_cpu" {
  alarm_name        = "sandbox-ec2-cpu-high"
  alarm_description = "Sandbox EC2 CPU alarm for Terraform import practice."

  namespace   = "AWS/EC2"
  metric_name = "CPUUtilization"
  statistic   = "Average"
  period      = 300

  comparison_operator = "GreaterThanThreshold"
  threshold           = 80
  evaluation_periods  = 1
  datapoints_to_alarm = 1

  dimensions = {
    InstanceId = "i-0bcfd92925343105e"
  }

  treat_missing_data = "missing"
  actions_enabled    = true
}

# New alarm — managed through Terraform CD
resource "aws_cloudwatch_metric_alarm" "lab_ec2_status_check" {
  alarm_name        = "hongmall-tf-lab-ec2-status-check"
  alarm_description = "Lab alarm based on HongMall EC2 monitoring inventory."

  namespace   = "AWS/EC2"
  metric_name = "StatusCheckFailed"
  statistic   = "Maximum"
  period      = 60

  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 1
  evaluation_periods  = 2
  datapoints_to_alarm = 2

  dimensions = {
    InstanceId = "i-0bcfd92925343105e"
  }

  treat_missing_data = "missing"
  actions_enabled    = false

  tags = {
    Environment = "lab"
    ManagedBy   = "terraform"
    Project     = "hongmall"
  }
}
