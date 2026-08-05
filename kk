# Standalone Terraform Plan Playbook

## Objective

Develop a standalone AAP playbook that allows IDE users to execute a **Terraform Plan** independently of the full APIGW provisioning workflow.

The purpose is to allow users to review the Terraform execution plan before deciding whether to proceed with infrastructure provisioning.

---

# Proposed Solution

Instead of modifying the existing provisioning workflow to support a "Plan Only" mode, implement a dedicated standalone playbook that:

- Executes only the Terraform Plan.
- Reuses the existing `tfe_provisioning` role.
- Does not execute Terraform Apply.
- Does not continue to any Ansible configuration.
- Does not require workflow state management.

---

# Survey Inputs

The playbook should expose only a minimal number of survey fields.

Expected inputs:

- Workspace Name
- Technical Asset Tag

These inputs should be sufficient for the automation to locate the approved infrastructure configuration.

---

# Input Retrieval

Users should **not** manually provide Terraform provisioning variables.

Instead, the workflow should:

1. Accept the survey inputs.
2. Locate the approved infrastructure input file.
3. Download the input file.
4. Parse the file.
5. Populate the variables required by the Terraform provisioning role.

The input file is expected to have already gone through the normal review and approval process before being consumed by the automation.

---

# Required Inputs for `tfe_provisioning`

The existing Terraform provisioning role expects the following variables.

| Variable | Source |
|----------|--------|
| `tfe_provisioning_workspace_name` | Survey |
| `tfe_provisioning_technical_asset_tag` | Survey |
| `tfe_provisioning_technical_asset_uuid` | Retrieved from input file |
| `tfe_provisioning_configuration_hcl` | Retrieved from input file |
| `tfe_provisioning_workspace_vars` | Retrieved from input file |
| `tfe_provisioning_action` | Hardcoded to `plan` |
| `tfe_provisioning_plan_poll_retries` | Configuration |
| `tfe_provisioning_plan_poll_delay_seconds` | Configuration |
| `tfe_provisioning_apply_poll_retries` | Configuration |
| `tfe_provisioning_apply_poll_delay_seconds` | Configuration |
| `tfe_provisioning_run_vars` | Default / Existing configuration |
| `tfe_provisioning_env` | **TBD** |

---

# Terraform Execution

After all required variables have been prepared, invoke the existing:

- `tfe_provisioning` role

The playbook should execute:

- Terraform Plan

The playbook should **not** execute:

- Terraform Apply
- Infrastructure provisioning
- Ansible configuration

---

# Terraform Plan Output

The main deliverable of the playbook is the Terraform Plan output.

The output should:

- Be visible in the AAP Job Output.
- Generate a plan output file.
- Be available for distribution (email integration discussed separately).

The Terraform Run ID may also be useful to capture.

---

# Existing Playbook

The existing `tfe_provisioning` playbook should remain unchanged and continue to be used for internal testing.

The new playbook should become the IDE-facing Terraform Plan interface.

---

# Development Approach

Reuse as much of the existing implementation as possible.

The new playbook should primarily focus on:

- Preparing the required inputs.
- Invoking the existing Terraform provisioning role.

The Terraform execution logic should **not** be reimplemented.

---

# Open Items / Investigation Required

## 1. Environment Resolution (TBD)

It is currently unclear how the following variable should be determined:

- `tfe_provisioning_env`

Possible options discussed:

- Derived from the input file.
- Derived from another source.
- Supplied separately.

This requires clarification.

---

## 2. Input File Lookup

The mechanism used to locate and retrieve the approved input file should follow the workflow implementation currently under development.

Review the existing implementation and reuse the same lookup mechanism where possible.

---

## 3. Survey Interface

Confirm whether the survey should use:

- Workspace Name
- Technical Asset Tag

or align with the interface currently being introduced in the provisioning workflow.

---

## 4. Terraform Plan Output Distribution

The Terraform Plan output should be generated.

Confirm whether the initial implementation should also:

- Write the output to a file.
- Email the file to the configured recipients.

This capability has been proposed but should be confirmed before implementation.
