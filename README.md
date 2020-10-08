# Prometheus performance & scale

## Hardware

- 3xMaster nodes: r5.4xlarge
- 50xWorker nodes: m5.2xlarge
- 3xInfra nodes: m5.2xlarge

Prometheus user-workload-monitoring-config configmap [here](assets/user-workload-monitoring-config.yaml)
In order to avoid noise Cluster Prometheus and User workload prometheus pods are pinned to different nodes.

## Measurements
### Number of samples

- Samples per target: `sum(avg_over_time(scrape_samples_scraped[15m])) by (job)`
- Rate of ingested samples: `sum by(job,namespace) (rate(prometheus_tsdb_head_samples_appended_total{namespace=~"openshift-monitoring|openshift-user-workload-monitoring"}[2m]))`
- Top 10 exposing metrics: `topk(10, count by (job)({__name__=~".+"}))`
- Number of active time series: `sum by (job,namespace) (prometheus_tsdb_head_series{})`

### System metrics
- prometheus container memory. sum(container_memory_rss{pod=~"prometheus-k8s-\d",namespace!="",name!="",container="prometheus"}
- prometheus CPU usage 
- rate(node_network_receive_bytes_total[2m])
- rate(node_network_transmit_bytes_total[2m])


## Test cases

### Cardinality stress

The goal of this test is measure how the cardinality of the ingested metrics affect Prometheus resource usage.

KPIs:
 - Prometheus memory
 - Prometheus CPU

**Test scenarios**
- 50 worker nodes: 1 namespace * 100 deployments * 10 replicas * 10 series = 10K series
- 50 worker nodes: 8 namespace * 100 deployments * 10 replicas * 8 series = 80K series

---

### Service Monitor stress

This test tries to identify the resource consumption of having a high number of service monitors across the cluster.

KPIs:
  - Memory from Prometheus operator
  - CPU from Prometheus operator
  - kube-apiserver requests/sec and status codes

**Test scenarios**
- 50 worker nodes: 1 namespace with 1000 servicemonitors pointing to 1 service each
- 50 worker nodes: 2 namespace with 1000 servicemonitors pointing to 1 service each

i.e. The first workload can be executed with the following command:

```
./load.sh -j 1000sm -s 60m -c service-monitors/load-monitoring-1000sm.yml
```

---

### Targets stress

The goal of this test is observe how a high number of small targets affect Prometheus performance:
KPIs:
  - Memory
  - CPU
  - Network usage
  - Disk usage

**Test scenarios**
- 50 worker nodes: 10 namespace * 100 deployments * 10 replicas * 5 static series = 10K targets and 150K series
- 50 worker nodes: 10 namespace * 100 deployments * 10 replicas * 10 static series = 10K targets and 500K series

i.e. The first workload can be executed with the following command:

```
./load.sh -j 10ktargets -s 60m -c targets/load-monitoring-targets-1.yml
```

---

### Compaction

The goal of this test is observe how Prometheus Head compaction affects memory usage.
KPIs:
  - Memory
  - CPU
