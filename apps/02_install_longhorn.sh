#!/bin/bash

helm install longhorn longhorn/longhorn --wait --namespace longhorn-system --create-namespace --version 1.3.2 \
             --set defaultSettings.backupTarget=nfs://qnap.home.local:/AppData/backups

cat <<EOF |kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: longhorn
  namespace: longhorn-system
spec:
  rules:
  - host: longhorn.k3s.home
    http:
      paths:
      - backend:
          service:
            name: longhorn-frontend
            port:
              number: 80
        path: /
        pathType: Prefix
EOF
