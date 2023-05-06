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
  - 192.168.0.35-192.168.0.39
---
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: service-pool
  namespace: metallb
spec:
  addresses:
  - 192.168.0.4-192.168.0.10
  autoAssign: false

---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: homelab-l2-advert
  namespace: metallb
spec:
  ipAddressPools:
  - homelab-pool
  - service-pool
EOF

# publishedservice is added so that traefik ingresses can be monitored correctly in argocd
helm install --create-namespace -n traefik traefik traefik/traefik \
 --set="additionalArguments={--providers.kubernetesingress.ingressendpoint.publishedservice=traefik/traefik}" \
 --set="providers.kubernetesCRD.allowExternalNameServices=true" \
 --set="providers.kubernetesIngress.allowExternalNameServices=true" \
 --wait

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
    - match: Host(\`traefik.k3s.home\`) # Hostname to match
      kind: Rule
      services: # Service to redirect requests to
        - name: api@internal # Special service created by Traefik pod
          kind: TraefikService
EOF_TRAEFIK_DASHBOARD
