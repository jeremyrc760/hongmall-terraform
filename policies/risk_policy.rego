
package terraform.risk

import rego.v1

# Extract actual resource changes from Terraform Plan
resource_changes := [
    {
        "address": rc.address,
        "actions": rc.change.actions,
        "before": rc.change.before,
        "after": rc.change.after,
    }
    |
    some rc in input.resource_changes
    rc.change.actions != ["no-op"]
]

# Attach resource criticality to each change
classified_changes := [
    object.union(rc, {
        "criticality": object.get(
            data.resources,
            rc.address,
            "unknown"
        )
    })
    |
    some rc in resource_changes
]

# Detect threshold changes in CloudWatch Alarms
threshold_changes contains rc.address if {
    some rc in resource_changes
    startswith(rc.address, "aws_cloudwatch_metric_alarm.")
    "update" in rc.actions
    rc.before.threshold != rc.after.threshold
}

# Classify threshold changes as medium severity
change_severity[address] := "medium" if {
    some address in threshold_changes
}

# Classify deletion as high severity
change_severity[address] := "high" if {
    some address in delete_changes
}


# Resources requiring classification
unknown_resources contains msg if {
    some rc in classified_changes
    rc.criticality == "unknown"
    msg := sprintf("Unclassified resource: %s", [rc.address])
}

# Detect resource deletion
delete_changes contains rc.address if {
    some rc in resource_changes
    rc.actions == ["delete"]
}

# Block unsafe S3 Public Access Block configurations
deny contains msg if {
    some rc in resource_changes
    rc.actions != ["delete"]
    rc.actions != ["create", "delete"]
    rc.actions != ["delete", "create"]
    rc.address != ""

    startswith(rc.address, "aws_s3_bucket_public_access_block.")

    some field in [
        "block_public_acls",
        "ignore_public_acls",
        "block_public_policy",
        "restrict_public_buckets"
    ]

    rc.after[field] == false

    msg := sprintf(
        "S3 public access protection disabled: %s (%s)",
        [rc.address, field]
    )
}

# Protect Terraform Apply Role OIDC trust policy
deny contains msg if {
    some rc in resource_changes

    rc.address == "aws_iam_role.terraform_apply"
    rc.actions != ["delete"]

    trust := json.unmarshal(rc.after.assume_role_policy)

    some statement in trust.Statement
    statement.Effect == "Allow"
    statement.Action == "sts:AssumeRoleWithWebIdentity"

    expected_sub := "repo:jeremyrc760@202478535/hongmall-terraform@1423675661:environment:production"

    actual_sub := object.get(
        object.get(statement.Condition, "StringEquals", {}),
        "token.actions.githubusercontent.com:sub",
        ""
    )

    actual_sub != expected_sub

    msg := sprintf(
        "IAM OIDC trust policy violation: %s",
        [rc.address]
    )
}


# Risk Decision Matrix V2
risk_matrix := {
    "low": {
        "low": "low",
        "medium": "low",
        "high": "medium"
    },
    "medium": {
        "low": "low",
        "medium": "medium",
        "high": "high"
    },
    "high": {
        "low": "low",
        "medium": "high",
        "high": "high"
    }
}

# Calculate final risk for classified changes
final_risk[address] := risk if {
    some rc in classified_changes
    rc.criticality != "unknown"

    severity := change_severity[rc.address]
    risk := risk_matrix[rc.criticality][severity]
    address := rc.address
}


# Detect changes without a final risk assessment
unassessed_changes contains rc.address if {
    some rc in classified_changes
    not final_risk[rc.address]
}

# Unified policy gate
default policy_pass := false

policy_pass if {
    count(unknown_resources) == 0
    count(deny) == 0
    count(unassessed_changes) == 0
}
