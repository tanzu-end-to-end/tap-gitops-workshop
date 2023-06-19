# Stage 1: Base Install of Tanzu Application Platform

In stage 1, we will perform a minimal install of a single-cluster TAP environment using the [full profile](https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.5/tap/install-online-profile.html#full-profile-3). This initial configuration won't be especially useful by itself, but it will provide a baseline that allows us to easily add the capabilities we want to the platform.

### Base working directory

Create a base working directory on your local machine for these workshop activities. We will refer to this directory going forward as $WORKSHOP_ROOT

### Initialize your platform GitOps repo

Here we will create the GitOps repo that records the configuration of your TAP install. All updates to the platform will be made to this repo, which will then propagate out to your installed environment.

First, download the base template for your repo from TanzuNet. Go the latest release page for Tanzu Application Platform, and download `tanzu-gitops-ri-0.2.0.tgz` to your local machine. Copy the tgz file to $WORKSHOP_ROOT.

From the $WORKSHOP_ROOT working directory, initialize the Git repo on your local machine:
```
mkdir -p workshop-clusters
tar xvf tanzu-gitops-ri-0.2.0.tgz -C workshop-clusters
cd workshop-clusters
git init -b main
git add . && git commit -m "Initialize Tanzu GitOps RI"
```

Now push the local repo to Github, where your cluster can access it. If you have the Github CLI installed, you can do this with:

```
gh repo create
```

The repo we have created can store the configuration for **all** of your TAP clusters. Each cluster will have its own subfolder in the GitOps repo where its configuration is stored. Let's create the cluster subfolder for `workshop`, which will be the name of our workshop cluster.

```
./setup-repo.sh workshop sops
```

The `sops` argument indicates that we will be using SOPS Secret Management (with Age encryption) to securely store the secrets that are needed to configure our cluster.

:bulb: **TIP:** We're going to be spending a lot of time adding, editng, and commiting files in this repo. It's recommended that you bring up the `workshop-clusters` directory as a project in a Git-aware, YAML-aware editor such as Visual Studio Code or IntelliJ. This will make it easy to navigate, edit, and commit.

### Create a starter configuration for your cluster

Navigate back to the $WORKSHOP_ROOT DIRECTORY. Clone this repo into this directory. It won't be part of your GitOps install, but it contains some template files we can copy into your repo to get you started quickly:
```
git clone https://github.com/tanzu-end-to-end/tap-gitops-workshop
cp tap-gitops-workshop/workshop/templates/tap-values.yaml workshop-clusters/clusters/workshop/cluster-config/values
cp tap-gitops-workshop/workshop/templates/tap-install-values.yaml workshop-clusters/clusters/workshop/cluster-config/values
```

Familiarize yourself with the two files you copied into yout GitOps repo. The first one provides the `tap-values` configuration for your cluster, which you will recognize if you've installed TAP before. The format is slightly different, so don't just copy an existing `tap-values.yaml` as-is here. 

Open this file ($WORKSHOP_ROOT/workshop-clusters/clusters/workshop/cluster-config/values/tap-values.yaml) in an editor, and fill our the placeholder values: your wildcard DNS domain, the project path for your container registry, the username for your registry credentials, and the Kubernetes version your cluster is running.

The second file `tap-install-values.yaml` is what we will use to control the version of TAP we are installing. In-place upgrades of the platform can be performed by simply editing this file and committing.

### Add secrets to your configuration

We're almost ready to install TAP, but we're still missing some key configuration values needed by the platform: our Github developer token, our registry password, and our TanzuNet credentials.

Hmmm. These are all sensitive pieces of information, and we have no interest in committing them as plain text to our GitOps repo. So we'll be using our secrets management tooling to encrypt these secrets before committing them, and we'll supply the decryption key to our cluster so that it knows how to decode them.

Go back to $WORKSHOP_ROOT. We are going to create a dedicated subdirectory `enc` to store this sensitive encryption stuff, and keep it out of our GitOps repo:
```
mkdir enc
cd enc
age-keygen -o key.txt
export SOPS_AGE_RECIPIENTS=$(cat key.txt | grep "# public key: " | sed 's/# public key: //')
export SOPS_AGE_KEY=$(cat key.txt)

cp ../tap-gitops/workshop/templates/tanzu-sync-values.yaml .
cp ../tap-gitops/workshop/templates/tap-sensitive-values.yaml .
```

We used `age` to generate an encryption key for our repo (don't lose this!), and set environment variables to reference that key when we encrypt. Then we copied templates for unencrypted secrets into this sensitive `enc` directory.

Open these two files, `tanzu-sync-values.yaml` and `tap-sensitive-values.yaml`, in an editor. Fill out these files as described with your Github developer token, registry credentials, and TanzuNet credentials in plain text.

Now we will encrypt the files:
```
sops --encrypt tanzu-sync-values.yaml > tanzu-sync-values.sops.yaml
sops --encrypt tap-sensitive-values.yaml > tap-sensitive-values.sops.yaml
```

The encrypted files, with the `.sops.yaml` suffix, are safe to store in your GitOps repo, so let's move them there:
```
mv tanzu-sync-values.sops.yaml ../tap-gitops-workshop/clusters/workshop/tanzu-sync/app/sensitive-values
mv tap-sensitive-values.sops.yaml ../tap-gitops-workshop/clusters/workshop/cluster-config/values
```

:bulb: **TIP:** Updating these secrets going forward follows the same flow. Edit the secrets file in your `enc` directory, use the `sops` CLI to encrypt them, and then move them into your GitOps repo. But there's an easier way! If you use a SOPS-aware IDE plugin like [VSCode SOPS](https://marketplace.visualstudio.com/items?itemName=signageos.signageos-vscode-sops), you can directly edit the `.sops.yaml` file in your GitOps repo as unencrypted plaintext, but the plugin will re-encrypt the file before writing to disk so that unencrypted secrets can't be committed to your GitOps repo.

### Install TAP

OK, we've got our cluster configuration the way we want it. Let's commit to Git, then we will run a configuration script to point our cluster at its associated GitOps repo.

```
cd $WORKSHOP_ROOT/workshop-clusters
git add . && git commit -m "Add workshop cluster"
git push -u origin main

cd clusters/workshop
./tanzu-sync/scripts/configure.sh
```

Now, let's commit again to pick up the assets that were created by the configuration script.
```
git add cluster-config/ tanzu-sync/
git commit -m "Configure install of TAP 1.6"
git push
```

We're ready to install! Please make sure that your kubeconfig is pointed at the cluster where you want to install TAP. Now, we can run the deployment script, which will sync the cluster to the GitOps repo, and kick off the install.
```
./tanzu-sync/scripts/deploy.sh
```
