#!/bin/bash

helm install --create-namespace -n loki \
             loki grafana/loki-stack \
             --set grafana.enabled=true,prometheus.enabled=true, \
             --set grafana.persistence.enabled=true \
             --set grafana.persistence.size=2Gi \
             --set prometheus.alertmanager.persistentVolume.enabled=false \
             --set prometheus.server.persistentVolume.enabled=true \
             --set prometheus.server.persistentVolume.size=20Gi

TMP_FILE=$(mktemp)
cat <<EOF >$TMP_FILE
spec:
  template:
    spec:
      containers:
      - name: kube-state-metrics
        image: k8s-gcr-io.mirrors.sjtug.sjtu.edu.cn/kube-state-metrics/kube-state-metrics:v2.3.0
EOF
kubectl patch -n loki deployment loki-kube-state-metrics --type merge --patch-file=$TMP_FILE 
rm $TMP_FILE
kubectl -n loki get secret loki-grafana -o go-template='{{range $k,$v := .data}}{{printf "%s: " $k}}{{if not $v}}{{$v}}{{else}}{{$v | base64decode}}{{end}}{{"\n"}}{{end}}'

cat <<EOF2 | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: grafana
  namespace: loki
spec:
  rules:
  - host: grafana-k3s.home.local
    http:
      paths:
      - backend:
          service:
            name: loki-grafana
            port:
              number: 80
        path: /
        pathType: Prefix
EOF2
