
PPROF_PERIOD=${PPROF_PERIOD:-10m}

start_pprof() {
  kubectl apply -f pprof-config/ocp.yaml
  url1=https://$(oc get route -n openshift-user-workload-monitoring prometheus-user-workload-0 -o go-template --template="{{.spec.host}}")/debug/pprof/heap
  url2=https://$(oc get route -n openshift-user-workload-monitoring prometheus-user-workload-1 -o go-template --template="{{.spec.host}}")/debug/pprof/heap
  token=$(oc sa get-token -n openshift-user-workload-monitoring pprof)
  while true; do
    curl -sSk -H "Authorization: Bearer ${token}" ${url1} -o prometheus-user-workload-0-${JOB_NAME}-$(date "+%H_%M_%S").pprof
    curl -sSk -H "Authorization: Bearer ${token}" ${url2} -o prometheus-user-workload-1-${JOB_NAME}-$(date "+%H_%M_%S").pprof
    sleep ${PPROF_PERIOD}
  done &
  pprof_pid=$!
}

stop_pprof() {
    tar czf pprof-${UUID}.tar.gz prometheus-user-workload-0-${JOB_NAME}-*.pprof
    rm -f prometheus-user-workload-0-${JOB_NAME}-*.pprof
}
