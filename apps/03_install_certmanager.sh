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
  name: selfsigned
spec:
  selfSigned: {}

---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: k3s.home
  namespace: kube-system
spec:
  dnsNames:
    - k3s.home
  secretName: home.local
  issuerRef:
    name: selfsigned
    kind: ClusterIssuer
EOF
