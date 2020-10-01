#!/bin/bash

trap exit_script SIGINT

log() {
    echo ${bold}$(date "+%d-%m-%YT%H:%m:%S") ${@}${normal}
}

usage() {
    cat << EOF
Usage: ${0} -j <job-name>
Options:
  -j Job name
  -s Sleep period beforing stopping conprof
EOF
exit 0
}

exit_script () {
  log "Ctrl-C detected"
  kill -2 ${pid}
  stop_conprof
}

while getopts "j:s:h" opt; do
  case ${opt} in
    j )
      JOB_NAME=$OPTARG
      ;;
    s )
      SLEEP_PERIOD=$OPTARG
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

UUID=$(uuidgen)

log "Running test with uuid: ${UUID}"
export TSDB=tsdb-${UUID}-${JOB_NAME}
source conprof.sh
start_conprof
kube-burner init -c load-monitoring.yml --uuid ${UUID}
log "Sleeping now ${SLEEP_PERIOD}"
sleep ${SLEEP_PERIOD}
stop_conprof
kube-burner destroy -c load-monitoring.yml --uuid ${UUID}


