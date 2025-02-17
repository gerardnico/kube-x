# Contrib Dev


## Jsonnet Bootstrap

The [jsonnet project](jsonnet/README.md) was bootstrapped with:
```bash
cd jsonnet
```
* The [kube-prometheus libs](utilities/download-kube-prometheus-scripts):
```bash
./download-kube-prometheus-scripts
```
* The jsonnet bundler (as seen on the [kube-prometheus jsonnetfile.json](https://github.com/prometheus-operator/kube-prometheus/blob/main/jsonnet/kube-prometheus/jsonnetfile.json)
```bash
jb init
jb install github.com/prometheus-operator/prometheus-operator/jsonnet/prometheus-operator@main
jb install github.com/prometheus-operator/prometheus-operator/jsonnet/mixin@main
jb install github.com/kubernetes-monitoring/kubernetes-mixin@master # for alerts, dashboard for prometheus and prometheus operator
jb install github.com/prometheus/prometheus/documentation/prometheus-mixin@v3.1.0
```
* Try it out with
* helmet
```bash
# set debug (to not delete the created manifests in the jsonnet/out directory)
export BASHLIB_ECHO_LEVEL=4
kubee helmet -n prometheus template prometheus > /tmp/all.yaml
```
* or Raw Jsonnet command
```bash
cd jsonnet
rm -rf out && mkdir -p out && jsonnet -J vendor \
  --multi out \
  "main.jsonnet"  \
  --ext-code "values={ kubee: std.parseYaml(importstr \"../../kubee/values.yaml\") }" \
  | xargs -I{} sh -c 'cat {} | gojsontoyaml > "{}.yaml" && rm {}' -- {}
```


## How to



### Verify that the prometheus instance is up and running

```bash
kubectl get prometheus -n kube-prometheus
# continuously
kubectl get prometheus -n kube-prometheus -w  
```
```
NAME         VERSION   DESIRED   READY   RECONCILED   AVAILABLE   AGE
prometheus                       1       True         True        39s
```

### Check that the operator is up and running

```bash
kubectl wait --for=condition=Ready pods -l  app.kubernetes.io/name=prometheus-operator -n kube-prometheus
```


## CRD

See [](../prometheus-crds/README.md)

## Why Not Full Kubernetes Prometheus

Because we want to be able to manage the installation granularity. No big bang.
When I installed the kubernetes-monitoring, the prometheus memory went to the roof (1G)

