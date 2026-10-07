#!/usr/bin/env bash
source scripts/evidence.sh
cluster_lab() {
 kubectl version; kubectl get nodes -o wide; kubectl get pods -n kube-system
 kubectl create namespace mayank-labs
}
objects_lab() {
 kubectl apply -n mayank-labs -f session10-k8s-core-objects/pod.yml
 kubectl wait -n mayank-labs --for=condition=Ready pod/nginx-pod --timeout=150s
 kubectl exec -n mayank-labs nginx-pod -- nginx -v
 kubectl apply -n mayank-labs -f session10-k8s-core-objects/deployment/deployment-v1.yaml
 kubectl rollout status -n mayank-labs deployment/web --timeout=150s
 kubectl apply -n mayank-labs -f session10-k8s-core-objects/deployment/deployment-v2.yaml
 kubectl rollout status -n mayank-labs deployment/web --timeout=150s
 kubectl rollout undo -n mayank-labs deployment/web
 kubectl rollout status -n mayank-labs deployment/web --timeout=150s
 kubectl get -n mayank-labs pods,rs,deploy -o wide
}
services_lab() {
 kubectl create namespace mayank-services
 kubectl apply -n mayank-services -f session-11-kubernetes-services/01-clusterip
 kubectl rollout status -n mayank-services deployment/web-app-clusterip --timeout=150s
 kubectl wait -n mayank-services --for=condition=Ready pod/curl-client --timeout=90s
 kubectl get -n mayank-services svc,endpoints
 kubectl exec -n mayank-services curl-client -- curl -fsS http://web-service-clusterip:8080 | head -5
}
ingress_lab() {
 kubectl create namespace mayank-ingress
 kubectl apply -n mayank-ingress -f session-12-ingress-configmaps-secrets/04-full-demo
 kubectl rollout status -n mayank-ingress deployment/mayankapp-backend --timeout=150s
 kubectl rollout status -n mayank-ingress deployment/mayankapp-frontend --timeout=150s
 kubectl get -n mayank-ingress configmap,secret,ingress,svc
 kubectl exec -n mayank-ingress deploy/mayankapp-frontend -- wget -qO- http://mayankapp-backend:8080/api
 echo 'Backend response verified; Ingress resource created. Controller/TLS routing not exercised in this check.'
}
storage_lab() {
 kubectl apply -n mayank-labs -f session-13-storage-hpa-probes/01-kubernetes-volumes/pv.yaml
 kubectl apply -n mayank-labs -f session-13-storage-hpa-probes/01-kubernetes-volumes/pvc.yaml
 kubectl apply -n mayank-labs -f session-13-storage-hpa-probes/01-kubernetes-volumes/pod.yaml
 kubectl wait -n mayank-labs --for=condition=Ready pod/storage-demo --timeout=150s
 kubectl exec -n mayank-labs storage-demo -- sh -c 'echo "Mayank Gupta 24BCS10220" > /data/student.txt'
 kubectl delete -n mayank-labs pod storage-demo --wait
 kubectl apply -n mayank-labs -f session-13-storage-hpa-probes/01-kubernetes-volumes/pod.yaml
 kubectl wait -n mayank-labs --for=condition=Ready pod/storage-demo --timeout=120s
 kubectl exec -n mayank-labs storage-demo -- cat /data/student.txt
 kubectl get -n mayank-labs pv,pvc
 kubectl apply -n mayank-labs -f session-13-storage-hpa-probes/02-hpa
 kubectl rollout status -n mayank-labs deployment/hpa-demo --timeout=150s
 kubectl get -n mayank-labs hpa
 echo 'Static volume persistence checked; HPA resource created. CPU-driven scaling requires metrics-server and load testing.'
}
troubleshooting_lab() {
 kubectl create namespace mayank-troubleshooting
 kubectl apply -n mayank-troubleshooting -f 'Mini Project/manifests/deployment.yaml'
 kubectl rollout status -n mayank-troubleshooting deployment/troubleshooting-app --timeout=150s
 kubectl apply -n mayank-troubleshooting -f 'Mini Project/manifests/service-broken.yaml'
 kubectl get -n mayank-troubleshooting endpoints troubleshooting-service
 test -z "$(kubectl get -n mayank-troubleshooting endpoints troubleshooting-service -o jsonpath='{.subsets[*].addresses[*].ip}')"
 kubectl apply -n mayank-troubleshooting -f 'Mini Project/manifests/service.yaml'
 sleep 3
 kubectl get -n mayank-troubleshooting endpoints troubleshooting-service
 test -n "$(kubectl get -n mayank-troubleshooting endpoints troubleshooting-service -o jsonpath='{.subsets[*].addresses[*].ip}')"
 echo 'PASS: broken selector has no endpoints; corrected selector restores endpoints'
}
helm_lab() {
 for chart in session-15-helm/01-helm-commands/my-chart session-15-helm/02-rollback/app-chart session-15-helm/03-mini-project/notes-chart final-devops-project/helm/tickethub; do
  helm lint "$chart"; helm template mayank "$chart" >/tmp/mayank-chart.yaml
 done
 helm upgrade --install mayank-notes session-15-helm/03-mini-project/notes-chart -n mayank-labs --wait --timeout 3m
 helm upgrade mayank-notes session-15-helm/03-mini-project/notes-chart -n mayank-labs --set replicaCount=2 --wait --timeout 3m
 helm rollback mayank-notes 1 -n mayank-labs --wait --timeout 3m
 helm history mayank-notes -n mayank-labs
 kubectl get -n mayank-labs deploy/mayank-notes-deploy
}
evidence session9-k8s cluster_lab
evidence session10-k8s-core-objects objects_lab
evidence session-11-kubernetes-services services_lab
evidence session-12-ingress-configmaps-secrets ingress_lab
evidence session-13-storage-hpa-probes storage_lab
evidence 'Mini Project' troubleshooting_lab
evidence session-15-helm helm_lab
