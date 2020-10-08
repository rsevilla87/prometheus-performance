#!/bin/bash

trap exit_script SIGINT

log() {
    echo $(date "+%d-%m-%YT%H:%M:%S") ${@}
}

usage() {
    cat << EOF
Usage: ${0} -j <job-name>
Options:
  -j Job name
  -s Sleep period beforing destroying assets and stopping pprof collection
  -c Kube-burner config file
EOF
exit 0
}

exit_script () {
  log "Ctrl-C detected, destroying assets"
  log "Killing PID: ${pprof_pid}"
  kill -6 ${pprof_pid}
  stop_pprof
  kube-burner destroy -c ${CONFIG} --uuid ${UUID}
  exit 1
}

while getopts "j:s:c:h" opt; do
  case ${opt} in
    j )
      JOB_NAME=$OPTARG
      ;;
    s )
      SLEEP_PERIOD=$OPTARG
      ;;
    c )
      CONFIG=$OPTARG
      ;;
    h )
      usage 
      ;;
    \? )
      echo "Invalid option: $OPTARG requires an argument" 1>&2
      ;;
  esac
done

if [[ -z ${JOB_NAME} ]] || [[ -z ${SLEEP_PERIOD} ]]; then
  usage
fi

if [[ ! -f ${CONFIG} ]]; then
  echo "Config file ${CONFIG} not found"
  exit 1
fi

UUID=$(uuidgen)

log "Running test with uuid: ${UUID}"
source pprof.sh
start_pprof
kube-burner init -c ${CONFIG} --uuid ${UUID}
log "Sleeping now ${SLEEP_PERIOD}"
sleep ${SLEEP_PERIOD}
kube-burner destroy -c ${CONFIG} --uuid ${UUID}
exit_script
