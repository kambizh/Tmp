Title

Create Standalone Terraform Plan AAP Playbook

Description

Develop a standalone AAP playbook and Job Template that enables the IDE team to execute a Terraform Plan independently of the APIGW provisioning workflow.

The playbook should reuse the existing tfe_provisioning role and execute Terraform in Plan mode only.

The playbook shall:

Accept a minimal set of survey inputs (e.g., Technical Asset Tag and Workspace Name/Target ID).
Reuse the existing workflow input retrieval mechanism to obtain the approved Terraform input.
Populate the required variables expected by the tfe_provisioning role.
Execute Terraform Plan only.
Generate and display the Terraform Plan output.
Save the plan output to a file and email it to the configured workflow_alert_contacts.
Acceptance Criteria
Standalone AAP Job Template is created.
Required Terraform inputs are derived using the existing workflow input retrieval mechanism.
Existing tfe_provisioning role is reused.
Terraform executes in Plan mode only.
Terraform Apply is not executed.
Terraform Plan output is generated, displayed, and emailed to the configured recipients.
