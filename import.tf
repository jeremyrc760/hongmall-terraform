import {
  to = aws_cloudwatch_metric_alarm.sandbox_ec2_cpu
  id = "sandbox-ec2-cpu-high"
}

# Import existing CloudWatch Alarm into Terraform State
import {
  to = aws_cloudwatch_metric_alarm.import_demo
  id = "hongmall-tf-lab-import-demo"
}
# Case Study 02 — Brownfield adoption
import {
  to = aws_cloudwatch_metric_alarm.service_cpu_medium
  id = "hongmall-tf-lab-service-cpu-medium"
}