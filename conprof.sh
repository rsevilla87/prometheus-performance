
LOG_LEVEL=${LOG_LEVEL:-info}
command -v conprof
if [[ $? -ne 0 ]]; then
  log "Conprof binary not found"
  exit 1
fi

start_conprof() {
  base_config=conprof-config/config.yaml
  conprof_cfg=/tmp/conprof-$(date +%s).yaml
  kubectl create sa conprof -n openshift-user-workload-monitoring
  kubectl apply -f conprof-config/ocp.yaml
  url1=$(oc get route -n openshift-user-workload-monitoring prometheus-user-workload-0 -o go-template --template="{{.spec.host}}")
  url2=$(oc get route -n openshift-user-workload-monitoring prometheus-user-workload-1 -o go-template --template="{{.spec.host}}")
  token=$(oc sa get-token -n openshift-user-workload-monitoring conprof)
  sed -e "s#TARGET1#${url1}#g" -e "s#TARGET2#${url1}#g" -e "s#TOKEN#${token}#g" ${base_config} > ${conprof_cfg}
  log "Starting conprof"
  conprof all --config.file=${conprof_cfg} --log.level=${LOG_LEVEL} --storage.tsdb.path=${TSDB} > /dev/null 2>&1 &
}

