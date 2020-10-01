
LOG_LEVEL=${LOG_LEVEL:-info}
command -v conprof
if [[ $? -ne 0 ]]; then
  log "Conprof binary not found"
  exit 1
fi

start_conprof() {
  log "Starting conprof"
  log "Log at conprof-${UUID}.log"
  {
    kubectl -n openshift-user-workload-monitoring port-forward pod/prometheus-user-workload-0 9090:9090 &
    pid1=$!
    kubectl -n openshift-user-workload-monitoring port-forward pod/prometheus-user-workload-1 9091:9090 &
    pid2=$!
    kubectl -n openshift-monitoring port-forward pod/prometheus-k8s-0 9092:9090 &
    pid3=$!
    kubectl -n openshift-monitoring port-forward pod/prometheus-k8s-1 9093:9090 &
    pid4=$!
    conprof all --config.file conprof-config/config.yaml --log.level=${LOG_LEVEL} --storage.tsdb.path=${TSDB} &
    pid5=$!
  } >> conprof-${UUID}-${JOB_NAME}.log 2>&1
}

stop_conprof() {
  log "Stopping conprof"
  kill -2 ${pid1} ${pid2} ${pid3} ${pid4} ${pid5}
}
