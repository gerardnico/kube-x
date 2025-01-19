# A main.libsonnet script based on kube-prometheus/main.libsonnet
# https://github.com/prometheus-operator/kube-prometheus/blob/main/jsonnet/kube-prometheus/main.libsonnet
local kubernetesControlPlane = import './components/k8s-control-plane.libsonnet';
local customMixin = import './components/mixin/custom.libsonnet';
local prometheusOperator = import './components/prometheus-operator.libsonnet';
local prometheus = import './components/prometheus.libsonnet';


# local utils = import './lib/utils.libsonnet';

{
  // using `values` as this is similar to helm
  values:: {
    common: {
      namespace: 'default',
      platform: null,
      ruleLabels: {
        role: 'alert-rules',
        prometheus: $.values.prometheus.name,
      },
      // to allow automatic upgrades of components, we store versions in autogenerated `versions.json` file and import it here
      versions: {
        alertmanager: error 'must provide version',
        blackboxExporter: error 'must provide version',
        grafana: error 'must provide version',
        kubeStateMetrics: error 'must provide version',
        nodeExporter: error 'must provide version',
        prometheus: error 'must provide version',
        prometheusAdapter: error 'must provide version',
        prometheusOperator: error 'must provide version',
        kubeRbacProxy: error 'must provide version',
        configmapReload: error 'must provide version',
      } + (import 'versions.json'),
      images: {
        alertmanager: 'quay.io/prometheus/alertmanager:v' + $.values.common.versions.alertmanager,
        blackboxExporter: 'quay.io/prometheus/blackbox-exporter:v' + $.values.common.versions.blackboxExporter,
        grafana: 'grafana/grafana:' + $.values.common.versions.grafana,
        kubeStateMetrics: 'registry.k8s.io/kube-state-metrics/kube-state-metrics:v' + $.values.common.versions.kubeStateMetrics,
        nodeExporter: 'quay.io/prometheus/node-exporter:v' + $.values.common.versions.nodeExporter,
        prometheus: 'quay.io/prometheus/prometheus:v' + $.values.common.versions.prometheus,
        prometheusAdapter: 'registry.k8s.io/prometheus-adapter/prometheus-adapter:v' + $.values.common.versions.prometheusAdapter,
        prometheusOperator: 'quay.io/prometheus-operator/prometheus-operator:v' + $.values.common.versions.prometheusOperator,
        prometheusOperatorReloader: 'quay.io/prometheus-operator/prometheus-config-reloader:v' + $.values.common.versions.prometheusOperator,
        kubeRbacProxy: 'quay.io/brancz/kube-rbac-proxy:v' + $.values.common.versions.kubeRbacProxy,
        configmapReload: 'ghcr.io/jimmidyson/configmap-reload:v' + $.values.common.versions.configmapReload,
      },
    },
    prometheus: {
      namespace: $.values.common.namespace,
      version: $.values.common.versions.prometheus,
      image: $.values.common.images.prometheus,
      name: 'k8s',
      alerting: {
        alertmanagers: [{
          namespace: $.values.common.namespace,
          name: 'alertmanager-' + $.values.alertmanager.name,
          port: $.alertmanager.service.spec.ports[0].name,
          apiVersion: 'v2',
        }],
      },
      mixin+: { ruleLabels: $.values.common.ruleLabels },
    },
    prometheusOperator: {
      namespace: $.values.common.namespace,
      version: $.values.common.versions.prometheusOperator,
      image: $.values.common.images.prometheusOperator,
      configReloaderImage: $.values.common.images.prometheusOperatorReloader,
      mixin+: { ruleLabels: $.values.common.ruleLabels },
      kubeRbacProxyImage: $.values.common.images.kubeRbacProxy,
    },
    kubernetesControlPlane: {
      namespace: $.values.common.namespace,
      mixin+: { ruleLabels: $.values.common.ruleLabels },
    },
  },

  prometheus: prometheus($.values.prometheus),
  prometheusOperator: prometheusOperator($.values.prometheusOperator),
  kubernetesControlPlane: kubernetesControlPlane($.values.kubernetesControlPlane),
  kubePrometheus: customMixin(
    {
      namespace: $.values.common.namespace,
      mixin+: { ruleLabels: $.values.common.ruleLabels },
    }
  )
}
