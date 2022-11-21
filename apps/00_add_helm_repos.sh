#!/bin/bash

helm repo add longhorn https://charts.longhorn.io
helm repo add rm3l https://helm-charts.rm3l.org
helm repo add portainer https://portainer.github.io/k8s/
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add jetstack https://charts.jetstack.io
helm repo add metallb https://metallb.github.io/metallb
helm repo add traefik https://traefik.github.io/charts
helm repo update
