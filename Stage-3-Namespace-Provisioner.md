# Stage 3: Add Namespace Provisioner

Now that we have a running platform that can be accessed in a browser, it's time to start using it! As a platform engineer, you will want to create dedicated namespaces where developers can perform work, or where workloads can be onboarded into the environment. These namespaces will need to be configured with access to the correct credentials to operate. In Stage 3, we will configure the **Namespace Provisioner** component that automates the lifecycle of these namespaces.

## Create a list of managed namespaces.

First, we will go through the process of configuring developer namespaces, which is an activity the platform engineer would typically perform on an [Iterate Cluster](https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.5/tap-reference-architecture/GUID-reference-designs-tap-architecture-planning.html#iterate-cluster-requirements-10). These are namespaces that application developers would use directly for day-to-day activities.

Copy the following files into your cluster's GitOps repo:

```bash
cd $WORKSHOP_ROOT
mkdir workshop-clusters/clusters/workshop/cluster-config/namespace-provisioner
cp -R tap-gitops-workshop/templates/namespace-provisioner/namespaces workshop-clusters/clusters/workshop/cluster-config/namespace-provisioner
```

The [Desired Namespaces](templates/namespace-provisioner/namespaces/desired-namespaces.yaml) document contains the list of namespaces to be provisioned on your TAP cluster. You can add or remove namespaces from this list to create or delete the namespaces on your cluster. There is currently one namespace, `developer-ns`, listed in the document.

## Configure Namespace Provisioner in tap-values.yaml

Add the following section to your `$WORKSHOP_ROOT/workshop-clusters/clusters/workshop/cluster-config/values/tap-values.yaml`. **NOTE:** You **must** substitute the Github URL here, with the URL of your GitOps repo.

```yaml
    namespace_provisioner:
      controller: false
      sync_period: 30s
      # configure a repo that defines which namespaces should exist
      # for simplicity, it's the same one we have been using
      gitops_install:
        ref: origin/main
        subPath: clusters/workshop/cluster-config/namespace-provisioner/namespaces
        url: https://github.com/<GITHUB-ACCOUNT>/workshop-clusters.git
        secretRef:
          name: sync-git
          namespace: tanzu-sync
          create_export: true
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

## Adding credentials to the namespace

We've got a process for spinning up new developer namespaces, but we still don't have everything in the namespaces that our developers will need. Specifically, we'll need to add credentials for accessing our Git provider and our container registry. We'll handle this in a two-step process. First we will deploy the credentials into a central namespace, `tap-install`. Then, we will tell Namespace Provisioner to import the credentials into the namespaces it creates.

These credentials are sensitive, so we'll need to SOPS-encrypt them before adding them to our repo:

```bash
cd $WORKSHOP_ROOT/enc
cp ../tap-gitops-workshop/templates/namespace-provisioner/workshop-cluster-secrets.yaml .
```

Edit the file `$WORKSHOP_ROOT/enc/workshop-cluster-secrets.yaml`, and fill it out with your credentials. You will enter your Github username and developer token in plain text.

This file contains an exported Secret named `tap-install/git-https`.
In this example, this secret is equivalent to `tanzu-sync/sync-git`, but we could use a different credential for developer workloads and even decide to pull those configurations from different repositories than our control repo for TAP.

You will also add the base64-encoded string for your registry credentials. They will be added to two secrets in this file, `registry-credentials` and `lsp-push-credentials`. Here is a command that will generate the base64 encoding that you can input for `.dockerconfigjson`
```bash
kubectl create secret docker-registry registry-credentials --docker-server=[My Registry Server] --docker-username=[Registry Username] --docker-password=[Registry Password] --dry-run=client -o jsonpath='{.data.\.dockerconfigjson}'
```

Once you have input these values, we can SOPS-encrypt them:

```bash
cd $WORKSHOP_ROOT/enc
export SOPS_AGE_RECIPIENTS=$(age-keygen -y key.txt)
sops --encrypt workshop-cluster-secrets.yaml > workshop-cluster-secrets.sops.yaml
```

In the general folder for user-provided resources, will copy our SOPS-encrypted values, add a `SecretExport` resource in the `tap-install namespace that will authorize our secrets to be imported into the developer namespaces:

```bash
cd $WORKSHOP_ROOT
mv enc/workshop-cluster-secrets.sops.yaml workshop-clusters/clusters/workshop/cluster-config/config/general
cp tap-gitops-workshop/templates/namespace-provisioner/secretexport.yaml workshop-clusters/clusters/workshop/cluster-config/config/general
```

Now, we will create a folder for resources that we want Namespace Provisioner to deploy in every developer namespace. This folder contains a `SecretImport` resource that will copy the secrets we added from the `tap-install` namespace to the developer namespace:

```bash
cd $WORKSHOP_ROOT
cp -R tap-gitops-workshop/templates/namespace-provisioner/namespace-resources workshop-clusters/clusters/workshop/cluster-config/namespace-provisioner
```

Update your `$WORKSHOP_ROOT/workshop-clusters/clusters/workshop/cluster-config/values/tap-values.yaml` file again. Add sections in the namespace provisioner configuration to look for the new `namespace-resources` directory we just created, and to add the Git secret we imported to the namespace's default service account. **NOTE:** You **must** substitute the Github URL here, with the URL of your GitOps repo.

```yaml
    namespace_provisioner:
      additional_sources:
        # additional sources points to the resources we want to fill those namespaces with
        - git:
            url: https://github.com/<GITHUB-ACCOUNT>/workshop-clusters.git
            ref: origin/main
            subPath: clusters/workshop/cluster-config/namespace-provisioner/namespace-resources
            secretRef:
              name: git-https # this is the new credential
              namespace: tap-install
      default_parameters:
        supply_chain_service_account:
          secrets:
            - git-https
```

Also, we will add configuration to the `tap-values.yaml` for the `local_source_proxy` component. This will allow developers to push their source code to the container registry, without needing a docker client or registry credentials on their local machine. **NOTE:** You **must** substitute the Image registry path here, with the project path of your image registry (e.g. myregistry.azurecr.io/tap).

   ```yaml
       local_source_proxy:
         repository: <MY_REGISTRY_PROJECT_PATH>/tap-source-proxy
         push_secret:
           name: lsp-push-credentials
           namespace: tap-install
           create_export: true
   ```

Let's commit the changes to our GitOps repo, causing them to sync to our cluster.

```bash
cd $WORKSHOP_ROOT/workshop-clusters
git add . && git commit -m "Add dev namespace credentials"
git push -u origin main
```

## Use the developer namespace

Now we can test the developer namespace you've created on your cluster, `developer-ns`. If you already have the TAP IDE tooling installed on your local machine, you can proceed directly into Developer Getting Started activities for [VS Code](https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.5/tap/getting-started-iterate-new-app-vscode.html) [IntelliJ](https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.5/tap/getting-started-iterate-new-app-intellij.html).

Alternatively, you can run this scripted process to test using the namespace. Start by cloning an application to your local machine
   ```bash
   cd $WORKSHOP_ROOT
   git clone https://github.com/Tanzu-Solutions-Engineering/tanzu-java-web-app
   cd tanzu-java-web-app
   export NAMESPACE=developer-ns
   ./mvnw compile
   ```

Now, we will start the Tilt process that deploys the code to your developer namespace using a basic supply chain:
   ```bash
   tilt up --stream=true
   ```

The first time you run this, the process will take a few minutes to complete. Once it is done, you can access the application in your browser at http://localhost:8080. Leave Tilt running in your terminal window, and open a second terminal window where we will edit one of the source code files.

   ```bash
   vim src/main/java/com/example/springboot/HelloController.java
   ```

Change the string that is returned by the controller from `Greetings from Spring Boot + Tanzu!` to something else. Save your changes, exit the edit, and trigger a compile.
   ```bash
   ./mvnw compile
   ```

If you go back to the terminal window where Tilt is running, you will see that it picks up your changes, and patches the running container in your developer namespace in seconds. Reload your browser window at https://localhost:8080, and you will see the result of your code changes.


## [Next Stage: Enable the Scanning and Testing Supply Chain>>](Stage-4-Scanning-Testing.md)