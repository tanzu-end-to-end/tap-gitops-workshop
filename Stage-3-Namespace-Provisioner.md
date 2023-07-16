# Stage 3: Add Namespace Provisioner

Now that we have a running platform that can be accessed in a browser, it's time to start using it! As a platform engineer, you will want to create dedicated namespaces where developers can perform work, or where workloads can be onboarded into the environment. These namespaces will need to be configured with access to the correct credentials to operate. In Stage 3, we will configure the **Namespace Provisioner** component that automates the lifecycle of these namespaces.

### Create a list of managed namespaces.

First, we will go through the process of configuring developer namespaces, which is an activity the platform engineer would typically perform on an [Iterate Cluster](https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.5/tap-reference-architecture/GUID-reference-designs-tap-architecture-planning.html#iterate-cluster-requirements-10). These are namespaces that application developers would use directly for day-to-day activities.

Copy the following files into your cluster's GitOps repo:
   ```bash
   cd $WORKSHOP_ROOT
   mkdir workshop-clusters/clusters/workshop/cluster-config/namespace-provisioner
   cp -R tap-gitops-workshop/templates/namespace-provisioner/namespaces workshop-clusters/clusters/workshop/cluster-config/namespace-provisioner
   ```

The [Desired Namespaces](templates/namespace-provisioner/namespaces/desired-namespaces.yaml) document contains the list of namespaces to be provisioned on your TAP cluster. You can add or remove namespaces from this list to create or delete the namespaces on your cluster. There is currently one namespace, `developer-ns`, listed in the document.

### Configure Namespace Provisioner in tap-values.yaml

Add the following section to your `$WORKSHOP_ROOT/workshop-clusters/clusters/workshop/cluster-config/values/tap-values.yaml`. **NOTE:** You **must** substitute the Github URL here, with the URL of your GitOps repo.

   ```yaml
       namespace_provisioner:
         controller: false
         sync_period: 30s
         gitops_install:
           ref: origin/main
           subPath: clusters/workshop/cluster-config/namespace-provisioner/namespaces
           url: https://github.com/<MY-REPO>/workshop-clusters.git
   ```
This points the namespace provisioner at your desired namespaces document, so that it will begin syncing against your namespace list.

Let's commit the changes to our GitOps repo, causing them to sync to our cluster.
   ```bash
   cd $WORKSHOP_ROOT/workshop-clusters
   git add . && git commit -m "Add dev namespace"
   git push -u origin main
   ```

In a minute or so, we will see the namespace provisioner create the namespace in our desired namespaces document.
   ```bash
   kubectl get ns developer-ns
   ```

Already, some default configuration has been provisioned into our environment. Our TanzuNet credentials are loaded into a secret in the namespace:
   ```bash
   kubectl get secret registries-credentials -n developer-ns
   ```

Also, the namespace provisioner added this secret as an `imagePullSecret` to our default service account.
   ```bash
   kubectl get sa default -n developer-ns -o yaml
   ```

### Adding credentials to the namespace

We've got a process for spinning up new developer namespaces, but we still don't have everything in the namespaces that our developers will need. Specifically, we'll need to add credentials for accessing our Git provider and our container registry. We'll handle this in a two-step process. First we will deploy the credentials into a central namespace, `tap-install`. Then, we will tell Namespace Provisioner to import the credentials into the namespaces it creates.

These credentials are sensitive, so we'll need to SOPS-encrypt them before adding them to our repo:

```bash
cd $WORKSHOP_ROOT/enc
cp ../tap-gitops-workshop/templates/namespace-provisioner/workshop-cluster-secrets.yaml .
```

Edit the file `$WORKSHOP_ROOT/enc/workshop-cluster-secrets.yaml`, and fill it out with your credentials. You will enter your Github username and developer token in plain text. You will also add the base64-encoded string for your registry credentials.

Here is a command that will generate the base64 encoding that you can input for `.dockerconfigjson`
```bash
kubectl create secret docker-registry registry-credentials --docker-server=[My Registry Server] --docker-username=[Registry Username] --docker-password=[Registry Password] --dry-run=client -o jsonpath='{.data.\.dockerconfigjson}'
```

Once you have input these values, we can SOPS-encrypt them:
```bash
sops --encrypt workshop-cluster-secrets.yaml > workshop-cluster-secrets.sops.yaml
```

Let's create a general folder in our GitOps repo for Kubernetes resources that we want to sync to our workshop cluster, and copy our SOPS-encrypted resources there.
```bash
cd $WORKSHOP_ROOT
mkdir workshop-clusters/clusters/workshop/cluster-config/config/general
mv enc/workshop-cluster-secrets.sops.yaml workshop-clusters/clusters/workshop/cluster-config/config/general
```

Also, in this general folder we will add a `SecretExport` resource in the `tap-install namespace that will authorize our secrets to be imported into the developer namespaces:
```bash
cd $WORKSHOP_ROOT
cp tap-gitops-workshop/templates/namespace-provisioner/secretexport.yaml workshop-clusters/clusters/workshop/cluster-config/config/general
```

Now, we will create a folder for resources that we want Namespace Provisioner to deploy in every developer namespace. This folder contains a `SecretImport` resource that will copy the secrets we added from the `tap-install` namespace to the developer namespace:
```bash
cd $WORKSHOP_ROOT
cp -R tap-gitops-workshop/templates/namespace-provisioner/namespace-resources workshop-clusters/clusters/workshop/cluster-config/namespace-provisioner
```

Update your `$WORKSHOP_ROOT/workshop-clusters/clusters/workshop/cluster-config/values/tap-values.yaml` file again, and configure the namespace provisioner to look for the new `namespace-resources` directory we just created, and to add the Git secret we imported to the namespace's default service account. **NOTE:** You **must** substitute the Github URL here, with the URL of your GitOps repo.

   ```yaml
       namespace_provisioner:
         controller: false
         sync_period: 30s
         gitops_install:
           ref: origin/main
           subPath: clusters/workshop/cluster-config/namespace-provisioner/namespaces
           url: https://github.com/<MY-REPO>/workshop-clusters.git
         additional_sources:
           - git:
               ref: origin/main
               subPath: clusters/workshop/cluster-config/namespace-provisioner/namespace-resources
               url: https://github.com/<MY-REPO>/workshop-clusters.git
         default_parameters:
           supply_chain_service_account:
             secrets:
               - git-https
   ```

Let's commit the changes to our GitOps repo, causing them to sync to our cluster.
   ```bash
   cd $WORKSHOP_ROOT/workshop-clusters
   git add . && git commit -m "Add dev namespace credentials"
   git push -u origin main
   ```

### Use the developer namespace

## Hints

After completing the above instructions, your resulting `tap-values.yaml` should look similar to this:

```yaml
---
tap_install:
  values:
    profile: full

    shared:
      ingress_domain: <MY-INGRESS-DOMAIN>.com # Wildcard DNS Domain (e.g. tap.myexample.com)
      image_registry:
        project_path: tapgitopsxxxxx.azurecr.io/tap/tap-images # Image registry project path (e.g. harbor.myexample.com/tap/tap-images)
        username: tapgitopsxxxxx # Registry username

      kubernetes_version: 1.25.6 # Kubernetes version (e.g. 1.25.9)

    ceip_policy_disclosed: true

    # These packages will be deprecated in future versions of TAP, so we will exclude them to free up space on the cluster
    excluded_packages:
      - learningcenter.tanzu.vmware.com
      - workshops.learningcenter.tanzu.vmware.com
      - eventing.tanzu.vmware.com

    namespace_provisioner:
      controller: false
      sync_period: 30s
      gitops_install:
        ref: origin/main
        subPath: clusters/workshop/cluster-config/namespace-provisioner
        url: https://github.com/<MY-REPO>/workshop-clusters.git
      additional_sources:
        - git:
            ref: origin/main
            subPath: clusters/workshop/cluster-config/namespace-provisioner/namespace-resources
            url: https://github.com/cpage-pivotal/workshop-clusters.git
      default_parameters:
        supply_chain_service_account:
          secrets:
            - git-https
```
