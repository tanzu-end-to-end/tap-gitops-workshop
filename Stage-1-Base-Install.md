# Stage 1: Base Install of Tanzu Application Platform

In stage 1, we will perform a minimal install of a single-cluster TAP environment using the [full profile](https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.5/tap/install-online-profile.html#full-profile-3). This initial configuration won't be especially useful by itself, but it will provide a baseline that allows us to easily add the capabilities we want to the platform.

### Base working directory

Create a base working directory on your local machine for these workshop activities. Assign that directory path to the environment variable WORKSHOP_ROOT

```bash
export WORKSHOP_ROOT=/path/to/my/basedir
```

Because you will likely use multiple shells during this workshop, it is highly recommend to use `direnv` to set the `WORKSHOP_ROOT` variable. In the azure jump-server setup, the top-level `.envrc` file is in the home-directory.

```bash
# for azure jump-server users:
# append workshop root to the home direnv config
echo export WORKSHOP_ROOT=\"$WORKSHOP_ROOT\" >> ~/.envrc
direnv allow
```

Now all SSH sessions to the jump-server will properly set the variable.

### Initialize your platform GitOps repo

Here we will create the GitOps repo that records the configuration of your TAP install. All updates to the platform will be made to this repo, which will then propagate out to your installed environment.

First, download the base template for your repo from TanzuNet. Go the [latest release page for Tanzu Application Platform](https://network.tanzu.vmware.com/products/tanzu-application-platform/#/releases/1346010), and download `tanzu-gitops-ri-0.2.5.tgz` to your local machine. Copy the tgz file to $WORKSHOP_ROOT. An alternative is to use the pivnet CLI to download it with the following command:

```bash
cd $WORKSHOP_ROOT
pivnet download-product-files --product-slug='tanzu-application-platform' --release-version='1.6.1' --product-file-id=1549358
```

Initialize the Git repo on your local machine:

```bash
cd $WORKSHOP_ROOT
mkdir -p workshop-clusters
tar xvf tanzu-gitops-ri-0.2.5.tgz -C workshop-clusters
cd workshop-clusters
git init -b main
git add . && git commit -m "Initialize Tanzu GitOps RI"
```

It is important that we name this control repo "`workshop-clusters`" to simplify our YAML configurations and commands.

Now push the local repo to Github, where your cluster can access it. If you have the Github CLI installed, you can do this with:

```bash
gh repo create --source . --push --private
```

This repo does not need to be private, but it's good hygiene.

The repo we have created can store the configuration for **all** of your TAP clusters. Each cluster will have its own subfolder in the GitOps repo where its configuration is stored. Let's create the cluster subfolder for `workshop`, which will be the name of our workshop cluster.

```bash
# ignore the "Next steps" that are outputted
./setup-repo.sh workshop sops
```

The `sops` argument indicates that we will be using SOPS Secret Management (with Age encryption) to securely store the secrets that are needed to configure our cluster.

```bash
git add .
git status
```

```bash
git commit -m 'Generate workshop cluster'
```

:bulb: **TIP:** We're going to be spending a lot of time adding, editng, and commiting files in this repo. It's recommended that you bring up the `workshop-clusters` directory as a project in a Git-aware, YAML-aware editor such as Visual Studio Code or IntelliJ. This will make it easy to navigate, edit, and commit.

### Create a starter configuration for your cluster

Clone this repo into your workshop root directory. It won't be part of your GitOps install, but it contains some template files we can copy into your repo to get you started quickly:

```bash
cd $WORKSHOP_ROOT
git clone https://github.com/tanzu-end-to-end/tap-gitops-workshop
cp tap-gitops-workshop/templates/install/tap-values.yaml workshop-clusters/clusters/workshop/cluster-config/values
```

Familiarize yourself with the file you copied into your GitOps repo. It provides the `tap-values` configuration for your cluster, which you will recognize if you've installed TAP before. The format is slightly different, so don't just copy an existing `tap-values.yaml` as-is here. 

Open this file (`$WORKSHOP_ROOT/workshop-clusters/clusters/workshop/cluster-config/values/tap-values.yaml`) in an editor, and fill our the placeholder values:

* Wildcard DNS domain
* Project path for the container registry
* Username for the container registry
* Kubernetes version

### Add secrets to your configuration

We're almost ready to install TAP, but we're still missing some key configuration values needed by the platform: our Github developer token, our registry password, and our TanzuNet credentials.

Hmmm. These are all sensitive pieces of information, and we have no interest in committing them as plain text to our GitOps repo. So we'll be using our secrets management tooling to encrypt these secrets before committing them, and we'll supply the decryption key to our cluster so that it knows how to decode them.

Go back to $WORKSHOP_ROOT. We are going to create a dedicated subdirectory `enc` to store this sensitive encryption stuff, and keep it out of our GitOps repo:

```bash
cd $WORKSHOP_ROOT
mkdir enc
cd enc
age-keygen -o key.txt
export SOPS_AGE_RECIPIENTS=$(age-keygen -y key.txt)
export SOPS_AGE_KEY=$(cat key.txt)

cp ../tap-gitops-workshop/templates/install/tanzu-sync-values.yaml .
cp ../tap-gitops-workshop/templates/install/tap-sensitive-values.yaml .
```

We used `age` to generate an encryption key for our repo (it's `key.txt`, don't lose this!), and set environment variables to reference that key when we encrypt. Then we copied templates for unencrypted secrets into this sensitive `enc` directory.

Open these two files, `tanzu-sync-values.yaml` and `tap-sensitive-values.yaml`, in an editor. Fill out these files as described with your Github developer token, registry credentials, and TanzuNet credentials in plain text. You will also be adding your encryption key here, which you can get by typing `cat key.txt`.

Now we will encrypt the files:

```bash
sops --encrypt tanzu-sync-values.yaml > tanzu-sync-values.sops.yaml
sops --encrypt tap-sensitive-values.yaml > tap-sensitive-values.sops.yaml
```

The encrypted files, with the `.sops.yaml` suffix, are safe to store in your GitOps repo, so let's move them there:

```bash
mv tanzu-sync-values.sops.yaml ../workshop-clusters/clusters/workshop/tanzu-sync/app/sensitive-values
mv tap-sensitive-values.sops.yaml ../workshop-clusters/clusters/workshop/cluster-config/values
```

:bulb: **TIP:** Updating these secrets going forward follows the same flow. Edit the secrets file in your `enc` directory, use the `sops` CLI to encrypt them, and then move them into your GitOps repo. But there's an easier way! If you use a SOPS-aware IDE plugin like [VSCode SOPS](https://marketplace.visualstudio.com/items?itemName=signageos.signageos-vscode-sops), you can directly edit the `.sops.yaml` file in your GitOps repo as unencrypted plaintext, but the plugin will re-encrypt the file before writing to disk so that unencrypted secrets can't be committed to your GitOps repo.

### Install TAP

OK, we've got our cluster configuration the way we want it. Let's commit to Git, then we will run a configuration script to point our cluster at its associated GitOps repo.

```bash
cd $WORKSHOP_ROOT/workshop-clusters
git add . && git commit -m "Configure workshop cluster encryption, domain, and credentials"
git push -u origin main 

cd clusters/workshop
./tanzu-sync/scripts/configure.sh
```

Now, let's commit again to pick up the assets that were created by the configuration script.

```bash
git add cluster-config/ tanzu-sync/
git commit -m "Configure install of TAP 1.6"
git push
```

We're ready to install! Please make sure that your kubeconfig is pointed at the cluster where you want to install TAP. Now, we can run the deployment script, which will sync the cluster to the GitOps repo, and kick off the install.

```bash
./tanzu-sync/scripts/deploy.sh
```

## [Next Stage: Enable Ingress >>](Stage-2-Ingress.md)
