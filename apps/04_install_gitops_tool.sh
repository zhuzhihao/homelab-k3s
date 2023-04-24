#!/bin/bash

TOOL_OF_CHOICE=argocd

if [[ $TOOL_OF_CHOICE == argocd ]]; then
  kubectl create namespace argocd
  kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

  # enable insecure connection for traefik ingress
  kubectl patch  configmap -n argocd argocd-cmd-params-cm -p '{"data":{"server.insecure": "true"}}'
  kubectl scale -n argocd deployment --replicas=0 argocd-server
  kubectl scale -n argocd deployment --replicas=1 argocd-server
  # create ingress
  TMP_FILE=$(mktemp)
  cat <<EOF_ARGOCD >$TMP_FILE
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: argocd-server
  namespace: argocd
spec:
  entryPoints:
    - web
    - websecure
  routes:
    - kind: Rule
      match: Host(\`argocd.k3s.home\`)
      priority: 10
      services:
        - name: argocd-server
          port: 80
    - kind: Rule
      match: Host(\`argocd.k3s.home\`) && Headers(\`Content-Type\`, \`application/grpc\`)
      priority: 11
      services:
        - name: argocd-server
          port: 80
          scheme: h2c
EOF_ARGOCD

  kubectl apply -f $TMP_FILE
  rm $TMP_FILE
  kubectl rollout status deployment -n argocd argocd-server --timeout=60s
  echo !argocd initial password:
  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
else
  helm install --create-namespace -n portainer portainer portainer/portainer \
             --set service.type=ClusterIP  \
             --set tls.force=false  \
             --set ingress.enabled=true \
             --set ingress.hosts[0].host=portainer.k3s.home \
             --set ingress.hosts[0].paths[0].path="/" \
             --set persistence.size=2Gi

  TMP_FILE=$(mktemp)
  cat <<EOF >$TMP_FILE
[
  "op": "add",
  "path": "/spec/template/spec/containers/0/env",
  "value": [
    { "name": "https_proxy", "value": "http://proxy.home.local:7890" },
    { "name": "HTTPS_PROXY", "value": "http://proxy.home.local:7890" }
  ]
]
EOF
  kubectl patch -n portainer deployment portainer --type='json' --patch-file=$TMP_FILE
  rm $TMP_FILE
fi
