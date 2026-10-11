Terraform has provisioned our virtual machines. The Chef branch now brings those machines into our configuration-management process.

There are two parts to this: registering which machines we want to manage, and defining the configuration they should receive. These are handled through two separate pull requests in two different repositories.

[Show the Chef registry PR.]

The first PR goes to the Chef object registry.

It uses the hostnames produced by Terraform to register the cluster’s nodes and its Chef environment. It also associates those objects with the application team’s Chef definitions repository and the appropriate server tier.

In this example, we have two nodes and one cluster environment.

You can see two files being updated here. The nodes file adds the two server hostnames, and the environments file adds the cluster environment. These entries are registered against the non-production Chef server.

This PR provides the first review point. The responsible reviewers can check which objects are being registered and their repository association before approving and merging the change.

The workflow monitors whether the PR has been merged before proceeding to the next Chef step. So, creating the PR does not immediately move the branch forward; the merge is the gate.

[Return to AAP, then open the Chef definitions PR.]

The second PR goes to the application team’s Chef definitions repository.

This is where we describe how those machines should be configured.

For this cluster, the PR creates one environment definition and two node definitions, one for each server provisioned by Terraform.

The environment definition contains shared settings for the cluster, including cookbook version constraints and common configuration attributes.

Each node definition links a particular server to that environment and includes its node-level configuration.

The workflow prepares these files by combining the supplied templates with the actual cluster details from provisioning. This avoids manually recreating the definitions for each new cluster.

This is a separate review and approval point. Reviewers can inspect the proposed configuration in the application repository before approving and merging it.

The distinction between the two PRs is straightforward: the first registers the objects and their repository association; the second defines their configuration.

Both follow their respective repository review processes. AAP prepares the changes and monitors the merges, while those approval controls remain in place.

[Show the Chef convergence validation output.]

After the definition PR is merged, we move to Chef validation.

A merged PR confirms that the repository change has been accepted. We also need to check that the objects have been published and that Chef has applied the configuration to the nodes.

That is what this validation step checks.

For this delivery, the validation results record the cluster environment as registered, published, and validated. The two nodes are also recorded as registered and published, and both are shown as converged.

Here, converged means Chef successfully applied its configuration. Application-level testing remains a separate activity.

So, this branch takes us through registration, configuration definition, and validation, with two clear PR review points along the way.

That gives us a traceable path from the hosts provisioned by Terraform to their configuration being applied through Chef.
