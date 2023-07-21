# Stage 4: Enable the Scanning and Testing Supply Chain

## Replace the developer namespace with a build namespace

TODO Steps

1. Delete workload in "developer-ns"
2. Replace "developer-ns" with a build namespace in desired-namespaces.yaml
3. Commit

## Configure scanning and testing supply chain in tap-values.yaml

```yaml
    supply_chain: testing_scanning
    
    ootb_supply_chain_testing_scanning: {}

    tap_gui:
      metadataStoreAutoconfiguration: true

    metadata_store:
      app_service_type: ClusterIP
      ns_for_export_app_cert: "*"

    scanning:
      metadataStore:
        url: ""

    grype:
      targetImagePullSecret: registry-credentials
```

## Add a Java pipeline to the developer namespace

```bash
cd $WORKSHOP_ROOT/workshop-clusters
cp ../tap-gitops-workshop/templates/namespace-provisioner/java-pipeline.yaml ./clusters/workshop/cluster-config/namespace-provisioner/namespace-resources/
```

## Add a scan policy to the developer namespace

```bash
cd $WORKSHOP_ROOT/workshop-clusters
cp ../tap-gitops-workshop/templates/namespace-provisioner/scan-policy.yaml ./clusters/workshop/cluster-config/namespace-provisioner/namespace-resources/
```

Note: notAllowedSeverities is commented out to allow workloads to progess through the pipeline

```yaml
    # notAllowedSeverities := ["Critical", "High", "UnknownSeverity"]
    notAllowedSeverities := []
```

Let's commit the changes to our GitOps repo, causing them to sync to our cluster.

```bash
cd $WORKSHOP_ROOT/workshop-clusters
git add . && git commit -m "Added scanning and testing supply chain"
git push -u origin main
```

## Add a workload to the build namespace

```bash
cd $WORKSHOP_ROOT/workshop-clusters
cp ../tap-gitops-workshop/templates/namespace-provisioner/workload.yaml ./clusters/workshop/cluster-config/namespace-provisioner/namespace-resources/
```
