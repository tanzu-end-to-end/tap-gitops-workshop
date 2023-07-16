# Stage 3: Add Namespace Provisioner

Now that we have a running platform that can be accessed in a browser, it's time to start using it! As a platform engineer, you will want to create dedicated namespaces where developers can perform work, or where workloads can be onboarded into the environment. These namespaces will need to be configured with access to the correct credentials to operate. In Stage 3, we will configure the **Namespace Provisioner** component that automates the lifecycle of these namespaces.

### Create a list of managed namespaces.

First, we will go through the process of configuring developer namespaces, which is an activity the platform engineer would typically perform on an ![Iterate Cluster](https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.5/tap-reference-architecture/GUID-reference-designs-tap-architecture-planning.html#iterate-cluster-requirements-10). These are namespaces that application developers would use directly for day-to-day activities.

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
   $ kubectl get ns developer-ns
   NAME            STATUS   AGE
   developer-ns    Active   45s
   ```

Already, some default configuration has been provisioned into our environment. Our TanzuNet credentials are loaded into a secret in the namespace:
   ```bash
   kubectl get secret registries-credentials -n developer-ns
   ```

Also, the namespace provisioner added this secret as an `imagePullSecret` to our default service account.
   ```bash
   kubectl get secret registries-credentials -n developer-ns
   ```


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
      additional_sources:
      gitops_install:
        ref: origin/main
        subPath: clusters/workshop/cluster-config/namespace-provisioner
        url: https://github.com/<MY-REPO>/workshop-clusters.git
```
