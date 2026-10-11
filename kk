Here’s a **three-minute talk at a steady pace**, with room for pauses.

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
