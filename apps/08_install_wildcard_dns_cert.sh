#!/bin/bash
set -euo pipefail

# Wildcard certificate for *.zhuzhihao.me (plus the apex) via Let's Encrypt DNS-01.
# The certificate lands in the traefik namespace and is installed as Traefik's
# default certificate, so every Ingress/IngressRoute for a *.zhuzhihao.me host
# is served with it without per-app TLS config.

SECRET_NS=cert-manager
SECRET_NAME=cloudflare-api-token

if ! kubectl -n "$SECRET_NS" get secret "$SECRET_NAME" >/dev/null 2>&1; then
  echo "[ERROR] Secret $SECRET_NS/$SECRET_NAME is missing."
  echo "Create a Cloudflare API token (Zone -> DNS -> Edit, scoped to zhuzhihao.me),"
  echo "fill in apps/certmanager/cloudflare_api_token_secret_example.yaml and run:"
  echo "  kubectl apply -f <your-filled-in-file>"
  exit 1
fi

# Traefik moved its CRD API group from traefik.containo.us to traefik.io in v2.10.
if kubectl get crd tlsstores.traefik.io >/dev/null 2>&1; then
  CRD_GROUP=traefik.io
elif kubectl get crd tlsstores.traefik.containo.us >/dev/null 2>&1; then
  CRD_GROUP=traefik.containo.us
else
  echo "[ERROR] No TLSStore CRD found; is Traefik installed with its CRDs?"
  exit 1
fi

# Dedicated issuer: leaves letsencrypt-production/staging (HTTP-01) untouched.
cat <<EOF | kubectl apply -f -
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-dns01
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: abcde12345.z@gmail.com
    privateKeySecretRef:
      name: letsencrypt-dns01
    solvers:
      - dns01:
          cloudflare:
            email: abcde12345.z@gmail.com
            apiTokenSecretRef:
              name: $SECRET_NAME
              key: api-token
EOF

# cert-manager renews automatically at 2/3 of the certificate lifetime.
cat <<EOF | kubectl apply -f -
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: wildcard-zhuzhihao-me
  namespace: traefik
spec:
  secretName: wildcard-zhuzhihao-me-tls
  dnsNames:
    - "*.zhuzhihao.me"
    - "zhuzhihao.me"
  issuerRef:
    name: letsencrypt-dns01
    kind: ClusterIssuer
EOF

# Make it Traefik's default certificate.
cat <<EOF | kubectl apply -f -
---
apiVersion: $CRD_GROUP/v1alpha1
kind: TLSStore
metadata:
  name: default
  namespace: traefik
spec:
  defaultCertificate:
    secretName: wildcard-zhuzhihao-me-tls
EOF

echo "Waiting for certificate to become Ready (up to 5 minutes)..."
STATUS=
for _ in $(seq 1 60); do
  STATUS=$(kubectl -n traefik get certificate wildcard-zhuzhihao-me \
    -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || true)
  if [ "$STATUS" = "True" ]; then
    break
  fi
  sleep 5
done

if [ "$STATUS" != "True" ]; then
  echo "[WARN] Certificate is not Ready yet. Inspect with:"
  echo "  kubectl -n traefik describe certificate wildcard-zhuzhihao-me"
  echo "  kubectl -n traefik get challenges,orders"
  exit 1
fi

echo "Certificate wildcard-zhuzhihao-me is Ready."
echo
echo "Remaining manual step: make *.zhuzhihao.me and zhuzhihao.me resolve to the"
echo "Traefik LoadBalancer IP $(kubectl -n traefik get svc traefik -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo '<traefik-lb-ip>')"
echo "(Cloudflare DNS-only A record and/or AdGuard Home DNS rewrite)."
