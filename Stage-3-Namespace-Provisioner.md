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
