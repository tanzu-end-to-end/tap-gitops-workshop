# Tanzu Application Platform GitOps Workshop

Welcome! In this hands-on workshop, participants will learn GitOps benefits and best practices. They will bring their own Kubernetes cluster and perform a fresh deployment of TAP using the GitOps installer. They will experiment with incrementally adding new features, in-place upgrades, and uninstall-restore. We will discuss how to preconfigure working environments for pilots, so that customers are spending time getting value from TAP, not learning the install process.

### Prerequisites

Participants need to set up the following prerequisites before attending the workshop:
* A public-cloud Kubernetes environment, version 1.25 or higher
* [Cluster Essentials](https://docs.vmware.com/en/Cluster-Essentials-for-VMware-Tanzu/1.6/cluster-essentials/deploy.html) must be installed on the Kubernetes cluster.
* A container registry (GCR, ACR, or Harbor) with read/write access
* A wildcard domain (e.g. *.tap.mydomain.com) that the workshop participant owns. If you don't have one, it will be provided during the workshop.
* A [Github Developer Token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens#creating-a-personal-access-token-classic) with permissions to read and write to your repos
* Account credentials on [Tanzu Network](https://network.tanzu.vmware.com/)
* Current CLI tools for working with the environment: kubectl, [k9s](https://k9scli.io/topics/install/), git, [github](https://cli.github.com/manual/installation), [SOPS](https://github.com/mozilla/sops/releases) and [age](https://github.com/FiloSottile/age#installation) for encrypting secrets, [Carvel](https://carvel.dev/#install) and Tanzu CLI with plugins.

The workshop team has provided a [complete automation](infrastructure/) for setting up all of the prerequisites on Azure. If participants do not have the prereqs readily available, they are encouraged to use this setup with their Azure account.

Participants can track their progress on the prerequisites with a local copy of [this Excel worksheet](https://github.com/tanzu-end-to-end/tap-gitops-workshop/raw/main/Prereqs.xlsx).

### Verify Your Enviroment

Run the following commands to check to see if a few CLIs are functioning properly.

```bash
 # Tanzu Network auth check
pivnet eulas

# GitHub auth check
gh auth status

# Tanzu CLI installed check
tanzu version # should be v0.90 at least

# Tanzu CLI plugins check; reinstall via "tanzu plugin install --group vmware-tap/default:v1.6.1"
tanzu plugin list
```

### Workshop Stages

Participants will run the workshop in stages, where they perform a base install of TAP 1.6, and then incrementally add features and capabilities to the environment. The GitOps repo produced in this workshop can be re-used for further activities, such as customer demos and pilots.

[**Stage 1: Perform a base install of Tanzu Application Platform**](Stage-1-Base-Install.md)

[**Stage 2: Enable Ingress to Tanzu Application Platform**](Stage-2-Ingress.md)

[**Stage 3: Add Namespace Provisioner to Tanzu Application Platform**](Stage-3-Namespace-Provisioner.md)

[**Stage 4: Configure Scanning-Testing Supply Chain**](Stage-4-Scanning-Testing.md)

[**Stage 5: Customize TAP Developer Portal**](Stage-5-Customize-TDP.md)

[**Stage 6: Blow it Away! Reinstall!**](Stage-6-reinstall.md)


