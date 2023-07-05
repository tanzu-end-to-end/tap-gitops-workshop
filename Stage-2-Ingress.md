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

1. In your DNS zone, create a wildcard `A` record for the TAP-GUI, using the `EXTERNAL-IP` from the output above and the `ingress_domain` wildcard DNS domain from your `tap-values.yaml` file.

1. From your browser, navigate to [https://tap-gui.<ingress_domain>](https://tap-gui.<ingress_domain>) and verify you can see the TAP GUI.  

   **NOTE:** You may get a security warning due to the self-signed certificate that was created, ignore the warning and proceed to the site.
