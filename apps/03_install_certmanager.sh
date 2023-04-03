#!/bin/bash

helm install \
     cert-manager jetstack/cert-manager \
     --namespace cert-manager \
     --version v1.5.0 \
     --create-namespace \
     --set installCRDs=true

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
EOF
