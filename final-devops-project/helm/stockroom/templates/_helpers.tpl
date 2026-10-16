{{- define "stockroom.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "stockroom.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "stockroom.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "stockroom.labels" -}}
app.kubernetes.io/name: {{ include "stockroom.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/part-of: stockroom
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
owner: mayank
{{- end -}}

{{- define "stockroom.databaseUrl" -}}
postgresql+psycopg://{{ .Values.postgres.user }}:$(POSTGRES_PASSWORD)@{{ .Release.Name }}-postgres:5432/{{ .Values.postgres.database }}
{{- end -}}

{{- define "stockroom.databaseSecret" -}}
{{- default (printf "%s-db-secret" .Release.Name) .Values.postgres.existingSecret -}}
{{- end -}}
