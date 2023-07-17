# Stage 2: Enable Ingress

## Configure TAP-GUI DNS

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

1. In your DNS zone, create a wildcard `A` record for the TAP-GUI, using the `EXTERNAL-IP` from the output above and the `ingress_domain` wildcard DNS domain from your `tap-values.yaml` file. (If this is an AWS load balancer, you will see a DNS name instead of an IP address, and you will create it as a CNAME record rather than an A record)

### Configure TAP GUI Guest Access in tap-values.yaml

Add the following section to your `$WORKSHOP_ROOT/workshop-clusters/clusters/workshop/cluster-config/values/tap-values.yaml`.

```yaml
      tap_gui:
        app_config:
          auth:
          allowGuestAccess: true
```

This allows guest access to TAP GUI. This was on by default prior to TAP 1.6 and is a breaking change.

Let's commit the changes to our GitOps repo, causing them to sync to our cluster.

```bash
cd $WORKSHOP_ROOT/workshop-clusters
git add . && git commit -m "Add TAP GUI guest access"
git push -u origin main
```

### Access TAP GUI Via The Browser

From your browser, navigate to [https://tap-gui.<ingress_domain>](https://tap-gui.<ingress_domain>) and verify you can see the TAP GUI.

**NOTE:** You may get a security warning due to the self-signed certificate that was created, ignore the warning and proceed to the site.
