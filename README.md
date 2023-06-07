# Tanzu GitOps Reference Implementation

Use this archive contains an opinionated approach to implementing GitOps workflows on Kubernetes clusters.

This reference implementation is pre-configured to install Tanzu Application Platform.

For detailed documentation, refer to [VMware Tanzu Application Platform Product Documentation](https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.5/tap/install-gitops-intro.html).

# Stage 1

Complete the Prerequisites worksheet for your environment

Create a base directory $WORKSHOP_ROOT. Copy tanzu-gitops-ri-0.2.0.tgz into this directory. From the root directory, run these commands:

```
mkdir -p workshop-clusters
tar xvf tanzu-gitops-ri-0.2.0.tgz -C workshop-clusters
cd workshop-clusters
git init -b main
git remote add origin git@github.com:my-organization/workshop-clusters.git 
git add . && git commit -m "Initialize Tanzu GitOps RI"
git push -u origin

./setup-repo.sh workshop sops
git add . && git commit -m "Add workshop cluster"
git push -u origin main
```

Navigate back to the $WORKSHOP_ROOT DIRECTORY. Clone the workshop repo:
```
git clone https://github.com/tanzu-end-to-end/tap-gitops-workshop

```

Run these commands:
```
mkdir enc
cd enc
age-keygen -o key.txt

```