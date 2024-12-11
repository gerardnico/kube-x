{{/*
Library of templates createe with the define keyword
https://helm.sh/docs/chart_template_guide/named_templates/#declaring-and-using-templates-with-define-and-template
*/}}

{{/*
Encode the admin and a list of users for the basic auth secret
The point as second argument of the include is the context. It's mandatory to get access to the values `.Values...`
Usage: {{ include "basic-auth-list-base64-encode" . }}

Note:
This is equivalent to create a line by user that contains the ouput of:
`htpasswd -nb admin@traefik welcome`

Traefik expects the passwords to be hashed using MD5, SHA1, or BCrypt.
*/}}
{{- define "basic-auth-list-base64-encode" }}
{{- $result := list }}
{{/* Add the admin user */}}
{{- $result = append $result (htpasswd .Values.kube_x.cluster.adminUser.username .Values.kube_x.cluster.adminUser.password | b64enc)}}
{{/*https://github.com/helm/helm/issues/7533#issuecomment-1039521776*/}}
{{- range $user, $password := .Values.kube_x.traefik.middleware.basicAuth.users }}
{{- $result = append $result (htpasswd $user $password | b64enc) }}
{{- end }}
{{- join "\n" $result | indent 4}}
{{- end }}