# Stage 2: Enable Ingress

## Obtain an SSL Certificate

We will need a signed wildcard TLS Certificate for proper function of all platform features. If you have the ability to issue your own signed certificate for a domain you control, please feel free to use it. Otherwise, we provide pre-issued certificates you can use for the workshop, and these instructions will describe how to use them.

VMware employees can access the [Domains and Certificates Spreadsheet](https://onevmw.sharepoint.com/:x:/s/TanzuApplicationPlatformTAPTSL/EcyhihIXXdxHoagtOm9x_SEB3yNIce8OjDtnhRtJlPkgZw?e=Ph4e4p) to reserve a domain. Enter your name in Column D for the domain you want to use for your workshop.

## Configure DNS

1. Fetch the external IP address of the contour ingress:

```bash
kubectl get service envoy -n tanzu-system-ingress
```

You should see output similar to the following:

```bash
$ kubectl get service envoy -n tanzu-system-ingress
NAME    TYPE           CLUSTER-IP   EXTERNAL-IP   PORT(S)                      AGE
envoy   LoadBalancer   10.0.73.9    4.151.25.22   80:31334/TCP,443:31095/TCP   5d19h
```

Take the value in the "External-IP" column, and enter it into Column E of the worksheet for your domain. Let the instructor know that you've entered it, so that they can update the DNS record.

## Install the certificate

Create a certificates directory:
```bash
mkdir $WORKSHOP_ROOT/certificates
```
Go to the spreadsheet, and download the certificate (fullchain.pem) and the private key (privkey.pem) in columns B and C for your domain. Copy these 2 files into the `certificates` directory you created.

Now, let's create a secret for this certificate that can be installed onto our cluster. Be sure to replace the filenames in this command with the filenames of your certificate files.
```bash
cd $WORKSHOP_ROOT/certificates
chmod 600 workshopx-privkey.pem
kubectl create secret tls tls -n contour-tls --cert=workshopx-fullchain.pem --key=workshopx-privkey.pem --dry-run=client -o yaml > $WORKSHOP_ROOT/enc/certificate.yaml
```

This certificate file has sensitive private key data, so we need to encrypt it before adding it to our cluster's GitOps repo.

```bash
cd $WORKSHOP_ROOT/enc
export SOPS_AGE_RECIPIENTS=$(age-keygen -y key.txt)
sops --encrypt certificate.yaml > certificate.sops.yaml
```

Let's create a general folder in our GitOps repo for Kubernetes resources that we want to sync to our workshop cluster, and copy our SOPS-encrypted certificate secret there.

```bash
cd $WORKSHOP_ROOT
mkdir workshop-clusters/clusters/workshop/cluster-config/config/general
mv enc/certificate.sops.yaml workshop-clusters/clusters/workshop/cluster-config/config/general
```

We will copy some additional resources we want to deploy into this general folder: the namespace where our certificate secret will live, and a [TlsCertificateDelegation](https://projectcontour.io/docs/1.25/config/tls-delegation/) resource that instructs Contour to use this wildcard certificate to terminate HTTPS requests to the TAP cluster:

```bash
cp tap-gitops-workshop/templates/ingress/* workshop-clusters/clusters/workshop/cluster-config/config/general
```

Update your `$WORKSHOP_ROOT/workshop-clusters/clusters/workshop/cluster-config/values/tap-values.yaml` file:
- Set the `shared.ingress_domain` field to your wildcard domain.
- Update your `cnrs` configuration so that your workloads will be assigned a DNS name inside the wildcard domain.
- Point `tap_gui` at the TLS certificate we installed.
```yaml
    shared:
      ingress_domain: workshop999.tap-pilot.com # change this to your domain

    cnrs:
      default_tls_secret: contour-tls/tls
      domain_template: "{{.Name}}-{{.Namespace}}.{{.Domain}}" # this is a go-template

    tap_gui:
      tls:
        namespace: contour-tls
        secretName: tls
```

## Configure TAP GUI Guest Access in tap-values.yaml

Let's commit the changes to our GitOps repo, causing them to sync to our cluster.

```bash
cd $WORKSHOP_ROOT/workshop-clusters
git add . && git commit -m "Add TLS Ingress"
git push -u origin main
```

### Access TAP GUI Via The Browser

From your browser, navigate to [https://tap-gui.<ingress_domain>](https://tap-gui.<ingress_domain>) and verify you can see the TAP GUI.

## [Next Stage: Add Namespace Provisioner >>](Stage-3-Namespace-Provisioner.md)