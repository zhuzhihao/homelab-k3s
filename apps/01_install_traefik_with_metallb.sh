#!/bin/bash

helm install --create-namespace -n metallb metallb metallb/metallb --wait
cat <<EOF |kubectl apply -f -
---
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: homelab-pool
  namespace: metallb
spec:
  addresses:
  - 192.168.0.35-192.168.0.37

---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: homelab-l2-advert
  namespace: metallb
spec:
  ipAddressPools:
  - homelab-pool
EOF

helm install --create-namespace -n traefik traefik traefik/traefik --wait

# enable traefik dashboard
cat <<EOF_TRAEFIK_DASHBOARD |kubectl apply -f -
---
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: traefik-dashboard
  namespace: traefik
spec:
  entryPoints:
    - web
    - websecure
  routes:
    - match: Host(\`traefik-k3s.home.local\`) # Hostname to match
      kind: Rule
      services: # Service to redirect requests to
        - name: api@internal # Special service created by Traefik pod
          kind: TraefikService
EOF_TRAEFIK_DASHBOARD
