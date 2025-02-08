local validation = import './kubee/validation.libsonnet';

local kxExtValues = std.extVar('values');
// Values are flatten, so that we can:
// * use the + operator and the error pattern in called library
// * we can easily rename
local kxValues = {

  kubernetes_monitoring_namespace: validation.notNullOrEmpty(kxExtValues, 'namespace'),
  grafana_enabled: validation.notNullOrEmpty(kxExtValues, 'grafana.enabled'),
  grafana_name: validation.notNullOrEmpty(kxExtValues, 'grafana.name'),
  grafana_folder: 'kubernetes-monitoring',
  grafana_data_source: validation.notNullOrEmpty(kxExtValues, 'grafana.data_sources.prometheus.name'),
  kube_state_metrics_enabled: validation.notNullOrEmpty(kxExtValues, 'kube_state_metrics.enabled'),
  kube_state_metrics_scrape_interval: validation.notNullOrEmpty(kxExtValues, 'kube_state_metrics.scrape_interval'),
  kube_state_metrics_memory: validation.notNullOrEmpty(kxExtValues, 'kube_state_metrics.memory'),
  kube_state_metrics_version: validation.notNullOrEmpty(kxExtValues, 'kube_state_metrics.version'),
  kubelet_enabled: validation.notNullOrEmpty(kxExtValues, 'kubelet.enabled'),
  kubelet_scrape_interval: validation.notNullOrEmpty(kxExtValues, 'kubelet.scrape_interval'),
  kubelet_drop_buckets: validation.notNullOrEmpty(kxExtValues, 'kubelet.drop_bucket_metrics'),
  api_server_enabled: validation.notNullOrEmpty(kxExtValues, 'api_server.enabled'),
  api_server_scrape_interval: validation.notNullOrEmpty(kxExtValues, 'api_server.scrape_interval'),
  api_server_drop_buckets: validation.notNullOrEmpty(kxExtValues, 'api_server.drop_bucket_metrics'),
  core_dns_enabled: validation.notNullOrEmpty(kxExtValues, 'core_dns.enabled'),
  core_dns_scrape_interval: validation.notNullOrEmpty(kxExtValues, 'core_dns.scrape_interval'),
  node_exporter_enabled: validation.notNullOrEmpty(kxExtValues, 'node_exporter.enabled'),
  node_exporter_version: validation.notNullOrEmpty(kxExtValues, 'node_exporter.version'),
  node_exporter_scrape_interval: validation.notNullOrEmpty(kxExtValues, 'node_exporter.scrape_interval'),
  node_exporter_memory: validation.notNullOrEmpty(kxExtValues, 'node_exporter.memory'),

};

local k3sConfigPatch = {
  // Kubernetes Scheduler, Controller manager and proxy metrics comes from the api server endpoint
  // in k3s
  kubeApiserverSelector: 'job="apiserver"',  // the default value
  kubeSchedulerSelector: self.kubeApiserverSelector,
  kubeControllerManagerSelector: self.kubeApiserverSelector,
  kubeProxySelector: self.kubeApiserverSelector,
  kubeletSelector: 'job="kubelet"',
  cadvisorSelector: self.kubeletSelector,  // the default is 'job="cadvisor"'
};

local stripLeadingV(value) =
  if std.type(value) != 'string' then
    value
  else if std.startsWith(value, 'v') then
    std.substr(value, 1, std.length(value) - 1)
  else
    value;


// The kube-prometheus values
// Adapted from main https://github.com/prometheus-operator/kube-prometheus/blob/main/jsonnet/kube-prometheus/main.libsonnet#L18
local kpValues = {
  common: {
    namespace: kxValues.kubernetes_monitoring_namespace,
    // to allow automatic upgrades of components, we store versions in autogenerated `versions.json` file and import it here
    versions: {
      // RbacProxy is used by kube-prometheus to protect exporter endpoints
      kubeRbacProxy: error 'must provide version',
    } + (import 'kube-prometheus/versions.json') + {
      kubeStateMetrics: stripLeadingV(kxValues.kube_state_metrics_version),
      nodeExporter: stripLeadingV(kxValues.node_exporter_version),
    },
    images: {
      kubeStateMetrics: 'registry.k8s.io/kube-state-metrics/kube-state-metrics:v' + $.common.versions.kubeStateMetrics,
      nodeExporter: 'quay.io/prometheus/node-exporter:v' + $.common.versions.nodeExporter,
      kubeRbacProxy: 'quay.io/brancz/kube-rbac-proxy:v' + $.common.versions.kubeRbacProxy,
    },
  },
  kubeStateMetrics: {
    namespace: $.common.namespace,
    version: $.common.versions.kubeStateMetrics,
    image: $.common.images.kubeStateMetrics,
    mixin+: {
      _config+:: k3sConfigPatch,
    },
    kubeRbacProxyImage: $.common.images.kubeRbacProxy,
    resources:: {
      requests: { cpu: '10m', memory: kxValues.kube_state_metrics_memory },
      limits: { memory: kxValues.kube_state_metrics_memory },
    },
    scrapeInterval: kxValues.kube_state_metrics_scrape_interval,
  },
  kubernetesControlPlane: {
    namespace: $.common.namespace,
    mixin+: {
      _config+:: k3sConfigPatch,
    },
  },
  nodeExporter: {
    namespace: $.common.namespace,
    version: $.common.versions.nodeExporter,
    image: $.common.images.nodeExporter,
    mixin+: {
      _config+:: k3sConfigPatch,
    },
    kubeRbacProxyImage: $.common.images.kubeRbacProxy,
    resources:: {
        requests: { cpu: '102m', memory: kxValues.node_exporter_memory },
        limits: { memory: kxValues.node_exporter_memory },
      },
  },
};
// k8s-control-plane.libsonnet is a function
local kubernetesControlPlane = (import './kube-prometheus/components/k8s-control-plane.libsonnet')(kpValues.kubernetesControlPlane);



// mixin is not a function but an object
local mixin = (import 'github.com/kubernetes-monitoring/kubernetes-mixin/mixin.libsonnet') {
  _config+:: k3sConfigPatch {
    // the name of the data source (in place of default)
    datasourceName: kxValues.grafana_data_source,
  },
};

// Returned Object
{
  ['kubernetes-monitoring-' + name]:
    (
      if name == 'prometheusRule'
      then
        local prometheusRule = kubernetesControlPlane[name];
        prometheusRule {
          spec: {
            groups: [
              group
              for group in prometheusRule.spec.groups
              // We filter out the following groups
              if !std.member([], group.name)
            ],
          },
        }
      else if name == 'serviceMonitorKubelet' then
        local serviceMonitorKubelet = kubernetesControlPlane[name];
        serviceMonitorKubelet {
          spec+: {
            endpoints: [
              endpoint {
                interval: kxValues.kubelet_scrape_interval,
                metricRelabelings+: (if !kxValues.kubelet_drop_buckets then [] else [
                                       {
                                         sourceLabels: ['__name__'],
                                         regex: '.*_bucket',
                                         action: 'drop',
                                       },
                                     ]),
              }
              for endpoint in serviceMonitorKubelet.spec.endpoints
            ],
          },
        }
      else if name == 'serviceMonitorApiserver' then
        local serviceMonitorApiServer = kubernetesControlPlane[name];
        serviceMonitorApiServer {
          spec+: {
            endpoints: [
              endpoint {
                interval: kxValues.api_server_scrape_interval,
                metricRelabelings+: (if !kxValues.api_server_drop_buckets then [] else [
                                       {
                                         sourceLabels: ['__name__'],
                                         regex: '.*_bucket',
                                         action: 'drop',
                                       },
                                     ]),
              }
              for endpoint in serviceMonitorApiServer.spec.endpoints
            ],
          },
        }
      else if name == 'serviceMonitorCoreDNS' then
        local serviceMonitorCoreDNS = kubernetesControlPlane[name];
        serviceMonitorCoreDNS {
          spec+: {
            endpoints: [
              endpoint {
                interval: kxValues.api_server_scrape_interval,
              }
              for endpoint in serviceMonitorCoreDNS.spec.endpoints
            ],
          },
        }
      // We fail as normally, there is no more components or this is a typing error
      else error 'Internal Error: Controle Plane component ' + name + ' was unexpected'
    )
  for name in std.objectFields(kubernetesControlPlane)
  // k3s is only one binary
  // and does not need to scrape KubeScheduler and KubeControllerManager
  // The metrics are gathered with the api server scrape
  if !std.member(['serviceMonitorKubeScheduler', 'serviceMonitorKubeControllerManager'], name)
  // Enable/Disabled Monitor
  && !(name == 'serviceMonitorKubelet' && !kxValues.kubelet_enabled)
  && !(name == 'serviceMonitorApiserver' && !kxValues.api_server_enabled)
  && !(name == 'serviceMonitorCoreDNS' && !kxValues.core_dns_enabled)
} +
// kube-state metrics
(
  if !kxValues.kube_state_metrics_enabled then {} else
    local kubeStateMetrics = (import './kubee/kube-state-metrics.libsonnet')(kpValues.kubeStateMetrics);
    {
      ['kubernetes-monitoring-state-metrics-' + name]: kubeStateMetrics[name]
      for name in std.objectFields(kubeStateMetrics)
    }
) +
// Node Exporter
(
  if !kxValues.node_exporter_enabled then {} else
    local nodeExporter = (import './kubee/node-exporter.libsonnet')(kpValues.nodeExporter + kxValues);
    {
      ['kubernetes-monitoring-node-' + name]: nodeExporter[name]
      for name in std.objectFields(nodeExporter)
    }
) +
// Kubernetes Dashboard and Folder
(
  if !kxValues.grafana_enabled then {} else (import 'kubee/mixin-grafana.libsonnet')(kxValues {
    mixin: mixin,
    mixin_name: 'kubernetes-monitoring',
    grafana_folder_label: 'Kubernetes Monitoring',
  })
)
