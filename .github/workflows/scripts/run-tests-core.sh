#!/usr/bin/env bash

set -eu
set -o pipefail


source "$(dirname ${BASH_SOURCE[0]})/lib/testing.sh"


cid_es="$(container_id elasticsearch)"
cid_kb="$(container_id kibana)"

ip_es="$(service_ip elasticsearch)"
ip_kb="$(service_ip kibana)"

log 'Waiting for readiness of Elasticsearch'
poll_ready "$cid_es" "http://${ip_es}:9200/" -u 'elastic:testpasswd'

log 'Waiting for readiness of Kibana'
poll_ready "$cid_kb" "http://${ip_kb}:5601/api/status" -u 'kibana_system:testpasswd'

sleep 5
curl -X POST "http://${ip_es}:9200/logs-generic-default/_refresh" -u elastic:testpasswd \
	-s -w '\n'
