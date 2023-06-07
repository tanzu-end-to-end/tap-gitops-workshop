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
```

Navigate back to the $WORKSHOP_ROOT DIRECTORY. Clone the workshop repo:
```
git clone https://github.com/tanzu-end-to-end/tap-gitops-workshop
cp tap-gitops-workshop/workshop/templates/tap-values.yaml workshop-clusters/clusters/workshop/cluster-config/values
cp tap-gitops-workshop/workshop/templates/tap-install-values.yaml workshop-clusters/clusters/workshop/cluster-config/values
```

Run these commands:
```
mkdir enc
cd enc
age-keygen -o key.txt
export SOPS_AGE_RECIPIENTS=$(cat key.txt | grep "# public key: " | sed 's/# public key: //')
export SOPS_AGE_KEY=$(cat key.txt)

cp ../tap-gitops/workshop/templates/tanzu-sync-values.yaml .
cp ../tap-gitops/workshop/templates/tap-sensitive-values.yaml .
```

Fill out tanzu-sync-values.yaml and tap-sensitive-values.yaml
```
sops --encrypt tanzu-sync-values.yaml > tanzu-sync-values.sops.yaml
sops --encrypt tap-sensitive-values.yaml > tap-sensitive-values.sops.yaml

mv tanzu-sync-values.sops.yaml ../tap-gitops-workshop/clusters/workshop/tanzu-sync/app/sensitive-values
mv tap-sensitive-values.sops.yaml ../tap-gitops-workshop/clusters/workshop/cluster-config/values
```

Fill out $WORKSHOP_ROOT/workshop-clusters/clusters/workshop/cluster-config/values/tap-values.yaml

```
cd $WORKSHOP_ROOT/workshop-clusters
git add . && git commit -m "Add workshop cluster"
git push -u origin main

cd clusters/workshop
./tanzu-sync/scripts/configure.sh

git add cluster-config/ tanzu-sync/
git commit -m "Configure install of TAP 1.6"
git push
```

Make sure your Kubernetes context is pointed to your workshop cluster
```
./tanzu-sync/scripts/deploy.sh
```


