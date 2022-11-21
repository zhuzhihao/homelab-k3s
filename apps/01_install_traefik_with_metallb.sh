#!/bin/bash

helm install --create-namespace -n kube-system metallb metallb/metallb --wait
cat <<EOF |kubectl apply -f -
---
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: homelab-pool
  namespace: kube-system
spec:
  addresses:
  - 192.168.0.40-192.168.0.45

---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: homelab-l2-advert
  namespace: kube-system
spec:
  ipAddressPools:
  - homelab-pool
EOF

helm install --create-namespace -n traefik traefik traefik/traefik --wait
