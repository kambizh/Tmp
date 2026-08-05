Here's a polished Jira story that captures the discussion between Jay and Keith, highlights the real implementation challenge, and is suitable for review.

---

# Story

**Title**

**Implement Standalone Terraform Plan Playbook for IDE**

---

## Description

Develop a standalone Ansible Automation Platform (AAP) playbook and Job Template that enables the IDE team to execute a **Terraform Plan** independently of the API Gateway provisioning workflow.

The playbook should provide a user experience similar to the provisioning workflow currently under development while remaining generic enough to support future infrastructure provisioning requests.

Rather than requiring users to provide all Terraform inputs manually, the playbook will retrieve the approved infrastructure input file from the Git repository, derive the required Terraform provisioning variables, execute the existing Terraform provisioning role in **Plan** mode, and present the Terraform Plan output for review prior to infrastructure provisioning.

The implementation should reuse the existing Terraform provisioning role and existing workflow components wherever possible.

---

# Business Objective

Provide IDE users with the ability to review the Terraform execution plan before infrastructure provisioning, enabling an approval process prior to running the full provisioning workflow.

---

# Functional Requirements

### Survey Interface

Create a standalone Job Template that exposes a minimal set of survey inputs, aligned with the provisioning workflow where possible.

Expected survey inputs include:

* Workspace Name / Target ID (subject to alignment with the provisioning workflow)
* Technical Asset Tag

---

### Input Retrieval

The playbook shall:

* Retrieve the approved infrastructure input file from the Git repository.
* Reuse the workflow input retrieval mechanism currently under development where possible.
* Parse the retrieved input file.
* Populate the required variables expected by the existing Terraform provisioning role.

These variables include, but are not limited to:

* Terraform Environment
* Technical Asset UUID
* Configuration HCL
* Workspace Variables

---

### Terraform Execution

Reuse the existing **tfe_provisioning** role.

Execute Terraform in **Plan** mode only.

Requirements:

* Hardcode the provisioning action to **plan**
* Do not execute Terraform Apply
* Do not provision infrastructure
* Do not invoke any downstream APIGW configuration

---

### Terraform Plan Output

The playbook shall:

* Display the Terraform Plan output in the AAP Job Output.
* Generate a file containing the Terraform Plan output.

---

### Email Notification

Extend the existing email role to support attachments.

Email the generated Terraform Plan output file to the recipients configured in:

`workflow_alert_contacts`

---

# Technical Challenge

The existing **tfe_provisioning** role already performs the Terraform execution and expects a complete set of provisioning variables.

The primary implementation challenge is **preparing and supplying these inputs automatically** from a minimal set of survey parameters.

The playbook must:

* Accept only the required survey inputs.
* Locate the approved infrastructure input file.
* Parse the input file.
* Populate all variables required by the existing Terraform provisioning role.
* Invoke the role without modifying its implementation.

The focus of this story is on **input preparation and orchestration**, rather than implementing Terraform execution logic.

---

# Out of Scope

* Terraform Apply
* Infrastructure provisioning
* APIGW workflow execution
* Inventory synchronization
* Ansible configuration
* Workflow state management

---

# Dependencies

* Jay's workflow implementation for Git input retrieval.
* Existing `tfe_provisioning` role.
* Existing email role.
* Approved infrastructure input repository.

---

# Acceptance Criteria

* [ ] A standalone AAP Job Template is created.
* [ ] The Job Template exposes only the required survey inputs.
* [ ] The approved infrastructure input file is retrieved from Git.
* [ ] Required Terraform provisioning variables are derived from the input file.
* [ ] The existing `tfe_provisioning` role is reused.
* [ ] Terraform executes in **Plan** mode only.
* [ ] Terraform Apply is not executed.
* [ ] Terraform Plan output is displayed in the AAP Job Output.
* [ ] Terraform Plan output is written to a file.
* [ ] The generated plan file is emailed to the configured `workflow_alert_contacts`.
* [ ] No downstream provisioning or APIGW workflow tasks are executed.

---

I think this version is suitable for both developers and reviewers because it clearly separates:

1. **What** is being built (Business Objective),
2. **How** it should behave (Functional Requirements),
3. **Where the engineering effort lies** (Technical Challenge), and
4. **How success will be verified** (Acceptance Criteria).

