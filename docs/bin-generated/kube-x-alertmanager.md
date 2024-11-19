% kube-x-alertmanager(1) Version Latest | Alert Manager API Cli
# DESCRIPTION


`kube-x-alertmanager` is a [alert client](https://prometheus.io/docs/alerting/latest/clients/)
that performs request against the [alert manager api](https://petstore.swagger.io/?url=https://raw.githubusercontent.com/prometheus/alertmanager/main/api/v2/openapi.yaml)

# NOTE
Clients are expected to continuously re-send alerts as long as they are still active (usually on the order of 30 seconds to 3 minutes)
An alert is considered as resolved if it has not been updated/resend after the `resolve_timeout` configuration.
```yaml
resolve_timeout: 30m
```

# SYNOPSIS

```bash
kube-x-alertmanager [--url alert-manager-url] path method [name]
```

where:
* `path` can be all [path apis](https://petstore.swagger.io/?url=https://raw.githubusercontent.com/prometheus/alertmanager/main/api/v2/openapi.yaml)
* `method` can be:
  * `post` - post (only for alerts)
  * `get`  - get (no filtering for now)
* `name` is a mandatory alert name to post a test alerts
* `--url|-u` defines the Alert Manager URL (`http://localhost:9093`), default to `KUBE_X_ALERT_MANAGER_URL`

# Example
To trigger a test alert:
```bash
kube-x-alertmanager alerts post test
```
