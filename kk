## A Run Provisions One Cluster – Original Design

In the original design, each generic workflow run provisions and configures an entire cluster, such as APIGW or RSA, including all associated components.

For RSA, a single cluster contains multiple technical assets, including ZooKeeper, Broker, Manager, and CPUI, each with its own Tech Asset ID.

The original workflow consists of:

1. Load customer profile and validate inputs.
2. Provision all cluster components through Terraform.
3. Perform Chef registration, definition, and convergence.
4. Validate the provisioned VMs.
5. Generate the deployment report.

### RBAC Limitation

Our existing Terraform Enterprise (TFE) RBAC model assigns teams and permissions based on individual Tech Asset IDs.

Provisioning all RSA components through a single TFE workspace would place multiple technical assets within the same workspace-level authorization boundary.

Since TFE RBAC does not independently restrict access to individual Terraform resources within a shared workspace, users authorized to manage one technical asset could potentially affect resources belonging to another.

For example, a ZooKeeper team member with Terraform apply permissions on the shared workspace could potentially modify Broker or Manager resources.

This creates an access-isolation concern and could require changes to the existing RBAC model.

## Proposed Solution – Option 2: Component-Level Provisioning with Cluster-Level Orchestration

To preserve the existing RBAC model, Option 2 separates technical asset provisioning while retaining a single coordinated RSA cluster deployment.

Each technical asset runs through the same reusable generic workflow using its own TFE workspace and corresponding RBAC permissions.

A parent workflow coordinates the component runs and manages the overall cluster deployment.

### Proposed Workflow

**1. Component Provisioning**

The parent workflow triggers a generic workflow run for each technical asset, such as ZooKeeper, Broker, Manager, and CPUI.

Each component workflow performs:

- Customer profile loading and input validation.
- Terraform VM provisioning and initial NaaS configuration (`observe = false`).
- Chef registration, definition, and convergence.

The initial NaaS configuration must provide the baseline network connectivity required for Chef and other platform services.

**2. Collect Component Results**

Once the component workflows complete successfully, the parent workflow collects their provisioning results, including VM information and network details, from the workflow state stored in S3.

**3. Cluster-Level NaaS Connectivity**

The parent workflow invokes Terraform NaaS connectivity policy enforcement (`observe = true`) to establish the required connectivity between RSA components.

This stage must preserve the baseline network access established during component provisioning.

**4. Post-NaaS Validation**

After network policy enforcement, the parent workflow performs:

- Chef convergence validation to confirm that required platform connectivity remains available.
- RSA cluster validation to verify connectivity and application readiness.
- Definition of Done (DoD) validation before completing the deployment.

### Benefits

- **RBAC isolation:** Each technical asset maintains its own TFE workspace and access permissions.
- **Reusable workflow:** The same generic workflow supports different technical asset types.
- **Cluster-level orchestration:** Multiple independently provisioned technical assets are delivered as one RSA cluster.
- **Reduced RBAC impact:** Avoids redesigning the existing tech-asset-based RBAC model.
- **Clear ownership:** Component provisioning and cluster-level connectivity are managed separately.

### Open Design Considerations

The following points require confirmation before implementation:

1. Whether NaaS supports connectivity policy enforcement across multiple Tech Asset IDs using an appropriately authorized TFE workspace and token.
2. Whether `observe = true` enforces the intended connectivity policies and preserves the baseline network access.
3. Whether the parent workflow can coordinate component dependencies, failures, retries, and recovery.
4. Whether Chef convergence requires any cross-component connectivity before the cluster-level NaaS stage.

### Recommendation

Proceed with **Option 2: Component-Level Provisioning with Cluster-Level Orchestration**, subject to confirming the NaaS authorization and connectivity requirements.

This approach preserves the existing TFE RBAC boundaries while supporting RSA clusters containing multiple technical assets.



### Proposed Solution – Option 2: Component-Level Provisioning with Cluster-Level Orchestration

To address the RBAC limitation, Option 2 proposes provisioning each technical asset separately using the same reusable generic workflow, with its own TFE workspace and RBAC permissions. A parent workflow coordinates all component runs to deliver a single RSA cluster. Each component workflow handles Terraform provisioning, initial NaaS configuration, and Chef convergence. Once all components are provisioned, the parent workflow collects their outputs, invokes NaaS to establish connectivity between the technical assets, and performs final Chef and cluster validation. This approach preserves the existing RBAC model while allowing multiple technical assets to operate together as one cluster, subject to confirming that NaaS supports cross-asset connectivity.
