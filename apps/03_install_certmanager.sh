#!/bin/bash

# v1.21.x is required: cert-manager < v1.12.16 misbuilds the Cloudflare cleanup
# URL ("/zones//dns_records/...") since Cloudflare stopped returning zone_id on
# DNS records (cert-manager issue #7540), which breaks DNS-01 wildcard issuance.
helm upgrade --install \
     cert-manager jetstack/cert-manager \
     --namespace cert-manager \
     --version v1.21.2 \
     --create-namespace \
     --set crds.enabled=true

cat <<EOF |kubectl apply -f -
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: abcde12345.z@gmail.com
    privateKeySecretRef:
      name: letsencrypt-staging
    solvers:
      - http01:
          ingress:
            class: traefik
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-production
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: abcde12345.z@gmail.com
    privateKeySecretRef:
      name: letsencrypt-production
    solvers:
      - http01:
          ingress:
            class: traefik
EOF
