Once Terraform has provisioned the API Gateway virtual machines, we need to register those servers in the configuration used by our deployment automation.

This step brings three related changes together: the cluster-specific inventory, the shared API Gateway deployment inventory, and the cluster-to-BIG-IP map.

The main improvement is that we prepare all three changes together and include them in one pull request. This makes them easier to review, approve, and merge as one complete onboarding update.

Let me show you each change.

First, we create or update the cluster-specific inventory file.

As you can see here, the file is organised by environment and region. In this example, we are wHere’s a **three-minute talk at a steady pace**, with room for pauses.

Next, let me walk you through the inventory onboarding part of our AAP workflow, and how we bring several related changes together into one pull request.

Once Terraform has provisioned the API Gateway virtual machines, we need to make those servers available to the automation that configures and manages them.

This involves updating the relevant Ansible inventory files, along with the BIG-IP mapping used for API Gateway onboarding.

Previously, these updates could result in separate pull requests. Although they belonged to the same onboarding request, each PR needed to be reviewed and merged. This added coordination and created the possibility that one change would be merged while another was still waiting.

Our improvement brings these related updates into a single PR.

Let me explain how that works.

First, the workflow takes the cluster information and prepares the required inventory changes. A cluster may need to appear in more than one inventory file, so we extended the existing inventory update role to support a list of files.

The workflow also prepares the corresponding BIG-IP map changes using the same cluster information.

After preparing and validating these changes, it commits them together and creates one pull request.

The reviewer can now see the related changes in one place and review them as a complete onboarding update. Once approved, they are merged together.

We also reuse the existing inventory update framework, which keeps the implementation consistent and avoids duplicating the same Git and PR handling logic.

The next important step is inventory synchronization.

Merging the PR updates the files in Git, but AAP still needs to import those changes into its inventory. Until that happens, the new servers may not be available to subsequent jobs.

So, the workflow waits for the relevant inventory sources to synchronize successfully before continuing with validation and the remaining onboarding activities.

The main benefit is simpler coordination: one PR for the related inventory and BIG-IP map changes, a clearer review, and an explicit synchronization step before moving forward.

This makes the onboarding process more consistent and reduces the manual effort needed to move from newly provisioned VMs to servers that AAP can manage.
orking with a stage cluster in North America.

The file contains the hostnames belonging to that cluster. For this demonstration, we have two hosts.

This gives us a dedicated inventory file for the cluster, with its servers listed in one place.

Second, we update the shared API Gateway deployment inventory.

In this file, each cluster is represented by a group. We add the cluster’s group name and list its hosts underneath it.

This allows the deployment automation to identify the cluster and target its servers together.

One point I want to highlight here is that this also supports existing clusters.

The automation checks the existing groups and nodes and updates the relevant entries. So, if nodes are added, removed, or changed, the inventory is updated to reflect the requested configuration.

For example, if a cluster already exists and its host list changes, we update that existing group. We do not simply keep appending another copy of the same information.

This means the same workflow supports both the initial onboarding and later changes to the cluster.

Third, we update the cluster-to-BIG-IP map.

This file records the mapping between a cluster and its BIG-IP devices.

In the example on screen, we add the new cluster with an empty list. So, at this point, we have created the mapping entry, but we have not assigned a BIG-IP device to it.

That distinction is useful: this change prepares the cluster’s entry in the configuration. It does not, by itself, configure a load balancer.

Now, all three file changes are part of the same onboarding request.

The workflow prepares the changes, validates them, and creates one commit and one pull request.

Previously, handling these updates separately could mean several PRs to track and coordinate. One might be merged while another was still waiting for review.

By bringing them together, the reviewer can see the complete set of related changes in one place.

They can check the cluster’s host list, confirm the group in the shared deployment inventory, and review the BIG-IP map entry within the same PR.

Once approved, those file changes are merged together.

We also build on the existing inventory update role. We extended it to handle multiple inventory files and included the BIG-IP map update in the same process. This lets us reuse the existing Git and pull request handling.

After the merge, we move to the next important step: AAP inventory synchronization.

Merging the PR updates the repository, but AAP still needs to import the updated inventory.

Until that synchronization completes, subsequent jobs may not see the new hosts or the changes to an existing cluster.

So, the workflow waits for the relevant inventory sources to synchronize successfully before continuing with validation and the remaining onboarding activities.

This connects the repository update to the next stage of automation: the configuration is reviewed and merged, and then the updated inventory becomes available in AAP.

The overall flow is straightforward. We prepare the three related changes, bring them together in one PR, merge them after approval, and wait for inventory synchronization before moving forward.

The benefit is less manual coordination, a clearer review, and consistent handling of both new clusters and updates to existing ones.
