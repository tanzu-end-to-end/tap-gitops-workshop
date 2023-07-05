# Stage 3: Add Namespace Provisioner

1. Create a directory to manage the namespaces.

   ```bash
   mkdir $WORKSHOP_ROOT/workshop-clusters/clusters/workshop/cluster-config/namespace-provisioner
   ```

1. Create the following `$WORKSHOP_ROOT/workshop-clusters/clusters/workshop/cluster-config/namespace-provisioner/desired-namespaces.yaml` file: 

   ```yaml
   #@data/values
   ---
   namespaces:
   - name: dev
   ```

1. Create the following `$WORKSHOP_ROOT/workshop-clusters/clusters/workshop/cluster-config/namespace-provisioner/namespaces.yaml` file: 

   ```yaml
   #@ load("@ytt:data", "data")
   #! This loop will now loop over the namespace list in
   #! in ns.yaml and will create those namespaces.
   #@ for ns in data.values.namespaces:
   ---
   apiVersion: v1
   kind: Namespace
   metadata:
     name: #@ ns.name
     #@ end
   ```

1. Add the following section to your `$WORKSHOP_ROOT/workshop-clusters/clusters/workshop/cluster-config/values/tap-values.yaml`, substituting the URL of your github repo.

   ```yaml
       namespace_provisioner:
         controller: false
         sync_period: 30s
         gitops_install:
           ref: origin/main
           subPath: clusters/workshop/cluster-config/namespace-provisioner
           url: https://github.com/<MY-REPO>/workshop-clusters.git
   ```

1. Commit the changes.
   ```bash
   git add . && git commit -m "Add dev namespace"
   git push -u origin main
   ```

1. Verify the `dev` namespace has been created, eg.

   ```bash
   $ kubectl get ns dev
   NAME   STATUS   AGE
   dev    Active   45s
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
