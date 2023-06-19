# Tanzu Application Platform GitOps Workshop

Welcome! In this hands-on workshop, participants will learn GitOps benefits and best practices. They will bring their own Kubernetes cluster and perform a fresh deployment of TAP using the GitOps installer. They will experiment with incrementally adding new features, in-place upgrades, and uninstall-restore. We will discuss how to preconfigure working environments for pilots, so that customers are spending time getting value from TAP, not learning the install process.

### Prerequisites

Participants need to set up the following prerequisites before attending the workshop:
* A public-cloud Kubernetes environment, version 1.25 or higher
* [Cluster Essentials](https://docs.vmware.com/en/Cluster-Essentials-for-VMware-Tanzu/1.5/cluster-essentials/deploy.html) must be installed on the Kubernetes cluster.
* A container registry (GCR, ACR, or Harbor) with read/write access
* A wildcard domain (e.g. *.tap.mydomain.com) that the workshop participant owns
* A [Github Developer Token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens#creating-a-personal-access-token-classic) with permissions to read and write to your repos
* Account credentials on [Tanzu Network](https://network.tanzu.vmware.com/)
* Current CLI tools for working with the environment: kubectl, [k9s](https://k9scli.io/topics/install/), git, [SOPS](https://github.com/mozilla/sops/releases) and [age](https://github.com/FiloSottile/age#installation) for encrypting secrets, and [Carvel](https://carvel.dev/#install).

Pre Bhakta has authored a [complete automation](infrastructure/) for setting up all of the prerequisites on Azure. If participants do not have the prereqs readily available, they are encouraged to use this setup with their Azure account.

Participants can track their progrss on the prerequisites with a local copy of [this Excel worksheet](/Prereqs.xlsx).

### Workshop Stages

Participants will run the workshop in stages, where they perform a base install of TAP 1.6, and then incrementally add features and capabilities to ehe environment. The GitOps repo produced in this workshop can be re-used for further activities, such as customer demos and pilots.


