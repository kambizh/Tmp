Our existing RBAC model assigns permissions based on Tech Asset IDs. Each technical asset has its own teams and access permissions in TFE.

In RSA, one cluster contains four different Tech Asset IDs: ZooKeeper, Broker, Manager and CPUI.

If we provision all four through one TFE workspace, they share the same workspace-level access controls.

The problem is that TFE RBAC cannot independently restrict access to individual Terraform resources within that shared workspace.

For example, if the ZooKeeper team has permission to apply Terraform changes in that workspace, they could potentially modify Broker or Manager resources as well.

This breaks the access isolation we're trying to maintain between technical assets.
n Option 2, we provision each technical asset separately to preserve the existing RBAC boundaries.

However, all these assets are part of the same RSA cluster, so we still need NaaS to establish connectivity between them.

My proposal is to manage that at the parent workflow level. Once the individual components are provisioned, we collect their network information and invoke NaaS to configure the connectivity.

This allows us to keep Terraform permissions separate while managing network connectivity at the cluster level.

The remaining point to confirm is whether NaaS can provision connectivity across multiple Tech Asset IDs using its own authorized workspace and token.
