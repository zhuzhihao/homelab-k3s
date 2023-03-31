#!/bin/bash

TRAEFIK_EXTERNAL_IP=$(kubectl get svc -n traefik -o=jsonpath="{.items[0].status.loadBalancer.ingress[0].ip}")

cat <<EOF >adguard-home-values.yaml
---
env:
  TZ: Asia/Shanghai
image:
  tag: v0.107.18
service:
  dns-udp:
    type: LoadBalancer
config: |
  bind_host: 0.0.0.0
  bind_port: 3000
  beta_bind_port: 0
  users: []
  auth_attempts: 5
  block_auth_min: 15
  http_proxy: ""
  language: ""
  debug_pprof: false
  web_session_ttl: 720
  dns:
    bind_hosts:
    - 0.0.0.0
    port: 53
    statistics_interval: 1
    querylog_enabled: true
    querylog_file_enabled: true
    querylog_interval: 168h
    querylog_size_memory: 1000
    anonymize_client_ip: false
    protection_enabled: true
    blocking_mode: default
    blocking_ipv4: ""
    blocking_ipv6: ""
    blocked_response_ttl: 10
    parental_block_host: family-block.dns.adguard.com
    safebrowsing_block_host: standard-block.dns.adguard.com
    ratelimit: 200
    ratelimit_whitelist: []
    refuse_any: true
    upstream_dns:
    - 192.168.0.1
    - 114.114.114.114
    - 8.8.8.8
    - '# specify upstream DNS server for special cases'
    - '[/home.local/]192.168.0.1'
    - '[/test.local/]192.168.0.1'
    - '[/raw.githubusercontent.com/]8.8.8.8'
    upstream_dns_file: ""
    bootstrap_dns:
    - 9.9.9.10
    - 149.112.112.10
    - 2620:fe::10
    - 2620:fe::fe:10
    all_servers: true
    fastest_addr: false
    fastest_timeout: 1s
    allowed_clients: []
    disallowed_clients: []
    blocked_hosts:
    - version.bind
    - id.server
    - hostname.bind
    trusted_proxies:
    - 127.0.0.0/8
    - ::1/128
    cache_size: 4194304
    cache_ttl_min: 0
    cache_ttl_max: 60
    cache_optimistic: false
    bogus_nxdomain: []
    aaaa_disabled: false
    enable_dnssec: false
    edns_client_subnet: false
    max_goroutines: 300
    ipset: []
    filtering_enabled: true
    filters_update_interval: 24
    parental_enabled: false
    safesearch_enabled: false
    safebrowsing_enabled: false
    safebrowsing_cache_size: 1048576
    safesearch_cache_size: 1048576
    parental_cache_size: 1048576
    cache_time: 30
    rewrites:
    - domain: mco.lbsg.net
      answer: 192.168.0.178
    - domain: longhorn.k3s.home
      answer: $TRAEFIK_EXTERNAL_IP
    - domain: portainer.k3s.home
      answer: $TRAEFIK_EXTERNAL_IP
    - domain: grafana.k3s.home
      answer: $TRAEFIK_EXTERNAL_IP
    - domain: hass.k3s.home
      answer: $TRAEFIK_EXTERNAL_IP
    - domain: adguard.k3s.home
      answer: $TRAEFIK_EXTERNAL_IP
    blocked_services: []
    upstream_timeout: 10s
    private_networks: []
    use_private_ptr_resolvers: true
    local_ptr_upstreams:
    - 192.168.0.1
  tls:
    enabled: false
    server_name: ""
    force_https: false
    port_https: 443
    port_dns_over_tls: 853
    port_dns_over_quic: 784
    port_dnscrypt: 0
    dnscrypt_config_file: ""
    allow_unencrypted_doh: false
    strict_sni_check: false
    certificate_chain: ""
    private_key: ""
    certificate_path: ""
    private_key_path: ""
  filters:
  - enabled: true
    url: https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt
    name: AdGuard DNS filter
    id: 1
  - enabled: false
    url: https://adaway.org/hosts.txt
    name: AdAway Default Blocklist
    id: 2
  whitelist_filters: []
  user_rules:
  - ""
  dhcp:
    enabled: false
    interface_name: ""
    local_domain_name: lan
    dhcpv4:
      gateway_ip: ""
      subnet_mask: ""
      range_start: ""
      range_end: ""
      lease_duration: 86400
      icmp_timeout_msec: 1000
      options: []
    dhcpv6:
      range_start: ""
      lease_duration: 86400
      ra_slaac_only: false
      ra_allow_slaac: false
  clients:
    runtime_sources:
      whois: true
      arp: true
      rdns: true
      dhcp: true
      hosts: true
      persistent: []
  log_compress: false
  log_localtime: false
  log_max_backups: 0
  log_max_size: 100
  log_max_age: 3
  log_file: ""
  verbose: false
  os:
    group: ""
    user: ""
    rlimit_nofile: 0
  schema_version: 14
EOF

helm install -n homelab --create-namespace adguard-home k8s-at-home/adguard-home -f adguard-home-values.yaml 

cat <<EOF2 | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: adguard-home
  namespace: homelab
spec:
  rules:
  - host: adguard.k3s.home
    http:
      paths:
      - backend:
          service:
            name: adguard-home
            port:
              number: 3000
        path: /
        pathType: Prefix
EOF2

rm adguard-home-values.yaml
