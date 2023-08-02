# Stage 6: Blow it away! Reinstall!

The power of GitOps comes from its portability and reproducibility. You can design and validate a customer pilot environment on your own Kubernetes, then take the GitOps repo to the customer and reproduce it there, with just minor changes to configuration and credentials. We can delete our TAP installs, and then restore them to a known good state in minutes. Let's try it out!

## Isolate Dependent Resources

Wait a minute, small problem. Our game plan is to take the `workshop` cluster config that we have built in this workshop, point it at a fresh Kubernetes, and have it reinstall our environment. But if we do that right now, it will actually fail. 

Here's why: When we tell kapp-controller to look at our repo, it will balk at some of our resources like [TLSCertificateDelegation](templates/ingress/tls-certificate-delegation.yaml). It won't recognize the CRD for this resource, which is part of the Contour package. But Contour won't be installed until we kick off the TAP install, so the CRDs don't exist on the cluster yet. Chicken or the egg.

We will call resources like TLSCertificateDelegation, which depend on CRDs that won't be available until after we kick off the install, **Dependent Resources**. What we need is a mechanism to install everything else first, and then install the dependent resources after the CRDs are available. Fortunately, kapp-controller provides a mechanism for sequencing our GitOps installs.

First, let's move all of our dependent resources into their own directory, outside of the `cluster-config/config` folder that automatically syncs to our cluster.

```bash
cd $WORKSHOP_ROOT
mkdir workshop-clusters/clusters/workshop/cluster-config/dependent-resources
mv workshop-clusters/clusters/workshop/cluster-config/config/general/tls-certificate-delegation.yaml workshop-clusters/clusters/workshop/cluster-config/dependent-resources
mv workshop-clusters/clusters/workshop/cluster-config/config/workloads workshop-clusters/clusters/workshop/cluster-config/dependent-resources
```

Now, we will install the kapp that will sync the dependent-resources folder to our cluster. We will put it in the `tanzu-sync` namespace to sit alongside our GitOps installer kapp.

```bash
cp tap-gitops-workshop/templates/reinstall/kapp-dependent-resources.yaml workshop-clusters/clusters/workshop/cluster-config/config/general
```

**NOTE:** You **must** edit this resource and replace the placeholder text with your own Github Org name. This will point our new kapp at your repo, and sync your dependent-resources to the cluster:

```yaml
        url: https://github.com/<GITHUB-ACCOUNT>/workshop-clusters
```

```bash
vim workshop-clusters/clusters/workshop/cluster-config/config/general/kapp-dependent-resources.yaml
```

If you inspect the kapp, you will notice this annotation:
```yaml
kapp.k14s.io/change-rule.0: "upsert after upserting pkgi"
```

This tells kapp-controller not to sync the dependent-resources until after the kapp with label `pkgi` has finished installing. `pkgi` is the arbitrary label associated with the GitOps installer app. We've also added configuration to the kapp that allows you to add SOPS-encrypted resources to the `dependent-resources` subdirectory, if you so desire.

Let's commit the changes to our GitOps repo, causing them to sync to our cluster.

```bash
cd $WORKSHOP_ROOT/workshop-clusters
git add . && git commit -m "Create dependent resources that wait for pkgi"
git push -u origin main
```

## Blow it Away!

Now, we have a cluster configuration that is idempotent and can be safely deleted. So, let's uninstall TAP:

```bash
kapp delete -a tanzu-sync -n default
```

Using a tool like k9s, you can monitor the progress of the `pkgi` resources in the `tap-install` directory, as the TAP components are sequentially uninstalled.

## Reinstall!

Once the uninstall process is complete, you have a clean cluster, and you can reinstall everything in a single operation:

```bash
cd $WORKSHOP_ROOT/workshop-clusters/clusters/workshop
export SOPS_AGE_KEY=$(cat ../../../enc/key.txt)
./tanzu-sync/scripts/deploy.sh
```

Again, you can track the progress of the `pkgi` installations in the `tap-install` directory as it reinstalls the platform, and restores everything to a known good state, including all of your scheduled workloads!
