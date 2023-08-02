# Stage 4: Enable the Scanning and Testing Supply Chain

## Replace the developer namespace with a workload namespace

In the previous exercise, we managed the environment like an Iterate cluster, and provisioned namespaces for application developers. Now, we'll see what it is like to manage a [Build Cluster](https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.5/tap-reference-architecture/GUID-reference-designs-tap-architecture-planning.html#build-cluster-requirements-1). We will replace our developer namespace with a namespace that can host workloads, and run them through a secure software supply chain to create compliant deployments.

**IMPORTANT**: Due to a current limitation in Carvel, we must delete our workloads from a namespace before deleting the namespace. Otherwise, the deletion process get stuck and it's a hassle. Remove the workloads from your developer namespace:
```bash
kubectl delete workloads --all -n developer-ns
```

Now, we can open `$WORKSHOP_ROOT/workshop-clusters/clusters/workshop/cluster-config/namespace-provisioner/namespaces/desired-namespaces.yaml` and replace the developer namespace with a workload namespace:

```yaml
#@data/values
---
namespaces:
  - name: workload-ns
```

## Add resources to the workload namespace

The workload namespace is going to require additional resources beyond what we installed in the developer namespace. We'll need a Tekton Pipeline that knows how to execute unit tests for our workloads, and we'll need a `ScanPolicy` resource that determines what our threshold is for security vulnerabilities in the supply chain. Let's copy these resources into our namespace provisioner, so that they will be installed with each workload namespace:

```bash
cd $WORKSHOP_ROOT
cp tap-gitops-workshop/templates/supply-chain/namespace-resources/* workshop-clusters/clusters/workshop/cluster-config/namespace-provisioner/namespace-resources
```

## Configure scanning and testing supply chain in tap-values.yaml

Now we will set up a supply chain appropriate for our build cluster. The default supply chain that gets installed is `basic`, which is appropriate for iterate clusters, but we will replace it with `testing_scanning`. We will also configure some of the additional packages, `grype` and `metadata_store`, that are used for scanning and recording vulnerabilities in your artifacts. Add these declarations to `$WORKSHOP_ROOT/workshop-clusters/clusters/workshop/cluster-config/values/tap-values.yaml`:
```yaml
    supply_chain: testing_scanning
    
    metadata_store:
      app_service_type: ClusterIP
      ns_for_export_app_cert: "*"

    scanning:
      metadataStore:
        url: ""

    grype:
      targetImagePullSecret: registry-credentials
```

Next, let's configure the supply chain itself. Create an empty repo in your Github org called `tap-deliveries`. You can do this with:

```bash
cd $WORKSHOP_ROOT
gh repo create tap-deliveries --private
```

This repo does not need to be private, but it's good hygiene.

Add this declaration to your `tap-values.yaml`, but customize it for your environment:
```yaml
    ootb_supply_chain_testing_scanning:
      gitops:
        ssh_secret: git-https
        branch: main
        commit_message: "Update from TAP Supply Chain Choreographer"
        server_address: https://github.com/
        repository_owner: # github-account
        repository_name: tap-deliveries
```

This will tell the supply chain to upload deployable artifacts to your registry at the repository you specify, and output a GitOps delivery in the `tap-deliverables` repo you created. The supply chain will use the registry and Git credentials you defined earlier in the workshop. (It is an oddity of tap that the git credentials field is called `ssh_secret` even though we are supplying a developer token in that field).

Finally, add this field to the `tap_gui` stanza of your `tap-values.yaml` file so that TAP GUI will be able to display data from the Metadata Store.

```yaml
    tap_gui:
      metadataStoreAutoconfiguration: true
```

Now, we will add a workload to the Build cluster to run through the supply chain. As platform engineers, we will schedule all of our workloads through GitOps. This gives us visibility and auditability of every build that runs on the server. Let's create a workloads folder that contains all of our workloads for this build cluster, and add a workload that is scheduled for our `workload-ns` namespace.

```bash
cd $WORKSHOP_ROOT
cp -R tap-gitops-workshop/templates/supply-chain/workloads workshop-clusters/clusters/workshop/cluster-config/config
```

Let's commit the changes to our GitOps repo, causing them to sync to our cluster.

```bash
cd $WORKSHOP_ROOT/workshop-clusters
git add . && git commit -m "Added scanning and testing supply chain"
git push -u origin main
```

Once the workload has been created, you can either view it in The Tanzu Developer Portal (formerly known as TAP GUI) or by running the following command:

```bash
tanzu apps workload tail tanzu-java-web-app --namespace workload-ns --timestamp --since 1h
```

## [Next Stage: Customize TAP Developer Portal>>](Stage-5-Customize-TDP.md)
