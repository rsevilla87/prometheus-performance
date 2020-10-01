# Prometheus performance & scale

## Test scenario

The key points of the test scenario are the following:
- User namespaces
- Prometheus operator custom-resources
- Number of exposed metrics
- Series Cardinality


## Measurements
### Number of samples
- Samples per target: `sum(avg_over_time(scrape_samples_scraped[15m])) by (job)`
- Rate of ingested samples: `sum by(job,namespace) (rate(prometheus_tsdb_head_samples_appended_total{namespace=~"openshift-monitoring|openshift-user-workload-monitoring"}[2m]))`

### Number of active time series

prometheus_tsdb_head_series

Legend: {{ job}}

- Number of series by job and namespace: sum by (job,namespace) (prometheus_tsdb_head_series{})

### Top 10 exposing metrics

- topk(10, count by (job)({__name__=~".+"}))


### System metrics
- rate(node_network_receive_bytes_total[2m])
- rate(node_network_transmit_bytes_total[2m])
- prometheus container memory. sum(container_memory_rss{pod=~"prometheus-k8s-\d",namespace!="",name!="",container="prometheus"}
- prometheus CPU usage 

## Iterations

50 worker nodes: 1 namespace with 100 pods. 100 * 100 series = 10K series
50 worker nodes: 10 namespaces with 100 pods each. 1000 * 100 series = 100K series
50 worker nodes: 100 namespaces with 100 pods each. 10000 * 100 series = 1M series
50 worker nodes: 100 namespaces with 100 pods each. 10000 * 400 series = 4M series

