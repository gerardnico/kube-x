{{/*
Library of templates createe with the define keyword
https://helm.sh/docs/chart_template_guide/named_templates/#declaring-and-using-templates-with-define-and-template
*/}}


{{/*
Helper to print the basic auth name for consitency
(used for middelware, ...)
*/}}
{{- define "kubernetes-dashboard-name" }}
{{- printf "%s"
    (include "kube-x-name-prefix" (dict "Release" .Release "Values" .Values.kube_x ))
    }}
{{- end }}

{{/*
Name Helper
*/}}
{{- define "kubernetes-dashboard-transport-no-tls-name" }}
{{- printf "%s-%s"
    (include "kube-x-name-prefix" (dict "Release" .Release "Values" .Values.kube_x ))
    "no-tls"
    }}
{{- end }}