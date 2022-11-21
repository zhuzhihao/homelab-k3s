#!/bin/bash

helm install --create-namespace -n portainer portainer portainer/portainer \
             --set service.type=ClusterIP  \
             --set tls.force=false  \
             --set ingress.enabled=true \
             --set ingress.hosts[0].host=portainer-k3s.home.local \
             --set ingress.hosts[0].paths[0].path="/" \
             --set persistence.size=2Gi
