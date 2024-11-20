% promtool(1) Version Latest | Promtool shipped in Docker
# DESCRIPTION

The [PromTool](https://prometheus.io/docs/prometheus/latest/command-line/promtool/) cli driven by [env](#environment-variable) with XTras.

# EXAMPLE

```bash
cat metrics.prom | promtool check metrics
curl -s http://localhost:9090/metrics | promtool check metrics
promtool test rules test.yml
```
The files (`metrics.prom`, `test.yml`) should be in the current directory.



# EXECUTION

The `PromTool` is executed with:
* the Prometheus docker image 
* only the working directory available

# EXTRAS

## PrometheusRule Check

The command `check prometheusRule prometheusRuleFile` permits to check a [Prometheus Rule](https://prometheus-operator.dev/docs/api-reference/api/#monitoring.coreos.com/v1.PrometheusRule)

## The url flag

This script will set the `--url` flag (The URL for the Prometheus server) 
if the `KUBE_X_PROM_URL` is set (default to `http://localhost:9090`)

### Basic Auth

This script will set the `--http.config.file` (It defines the HTTP client configuration file for promtool to connect to Prometheus)
with `Basic Auth` configuration.

The `Basic Auth` credentials should be stored in [pass](https://www.passwordstore.org/)

* For the [basic_auth user](https://prometheus.io/docs/alerting/latest/configuration/#http_config): the env `KUBE_X_PROM_BASIC_AUTH_PASS_USER` gives its path  
```bash
# ie this command should return the user
pass "$KUBE_X_PROM_BASIC_AUTH_PASS_USER"
```
* For the [basic_auth password](https://prometheus.io/docs/alerting/latest/configuration/#http_config): the env `KUBE_X_PROM_BASIC_AUTH_PASS_PASSWORD` gives its path 
```bash
# ie this command should return the password
pass "$KUBE_X_PROM_BASIC_AUTH_PASS_PASSWORD"
```

# SYNOPSIS

```bash
${SYNOPSIS}
```
