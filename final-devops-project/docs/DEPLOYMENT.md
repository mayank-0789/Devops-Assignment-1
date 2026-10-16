# AWS, Helm and GitOps deployment runbook

Run commands from `final-devops-project/` unless stated otherwise. This is a runbook, not a record of completed deployment. Required tools: AWS CLI, Terraform 1.9+, kubectl compatible with the cluster, Helm 3, Docker, Python 3.12+, Node 22. Local development does not need AWS.

## 1. Release images

Review and merge the Stockroom branch. `.github/workflows/capstone.yml` runs on main changes to the capstone. Confirm the tests, security checks and both Trivy scans pass. The image job publishes:

```text
ghcr.io/mayank-0789/devops-assignment-1/stockroom-backend:<full-commit-sha>
ghcr.io/mayank-0789/devops-assignment-1/stockroom-frontend:<full-commit-sha>
```

The promotion job updates exactly two tags in `helm/stockroom/values-gitops.yaml`. Initial `not-published` values deliberately do not point at a fictitious release. Pull requests build and scan but never publish or promote.

The Actions token needs repository Contents read/write and Packages write for the corresponding jobs. If main is protected against bot pushes, use a reviewed promotion PR with the same `scripts/promote.py <sha>` command; do not disable branch protection just for this workflow. The concurrency/head check prevents an older run from overwriting newer desired state.

GHCR packages may start private. Either make these classroom image packages public, or provision a read-only registry pull Secret and set `imagePullSecrets: [{name: ghcr-pull}]`. Both Deployments and the backend migration init container support it. Never put a registry token in Git.

## 2. Provision AWS

Authenticate through your normal AWS profile/SSO and confirm the intended account before running apply.

```bash
aws sts get-caller-identity
cd terraform
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan -out=capstone.tfplan
terraform apply capstone.tfplan
terraform output
# Run the configure_kubectl output, for example:
aws eks update-kubeconfig --region ap-south-1 --name stockroom-dev-eks
kubectl get nodes
cd ..
```

The plan creates a VPC, two public and two private subnets, a NAT gateway, an EKS control plane, managed worker nodes and EBS CSI IAM/add-on support. EKS and NAT incur charges. Keep the local state safe and do not run destroy from a different state file. A team deployment should move state to a protected shared backend before multiple people operate it.

The default Kubernetes version is 1.35, rather than the old reference's 1.31. Reconfirm [AWS's supported version list](https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html) and account/region availability at deployment time. The public API endpoint is enabled for laptop administration; scope its access before operating beyond a classroom demo.

## 3. Cluster prerequisites

```bash
kubectl apply -f kubernetes/namespace.yaml
kubectl apply -f kubernetes/storageclass.yaml
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm repo add traefik https://traefik.github.io/charts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm upgrade --install metrics-server metrics-server/metrics-server -n kube-system --wait --timeout 5m
helm upgrade --install traefik traefik/traefik -n ingress --create-namespace --wait --timeout 10m
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack -n monitoring --create-namespace -f monitoring/prometheus-values.yaml --wait --timeout 15m
helm upgrade --install argocd argo/argo-cd -n argocd --create-namespace --wait --timeout 10m
kubectl apply -f monitoring/grafana-dashboard.yaml
kubectl apply -f monitoring/alert-rules.yaml
```

Record the installed chart versions in your evidence. Third-party chart versions are not pinned in these bootstrap commands; select and record compatible releases when deploying. On EKS, verify the Traefik LoadBalancer receives an address; its provisioning depends on the cluster's AWS load-balancer integration. If your cluster requires AWS Load Balancer Controller, install/configure it before expecting an external address.

Create a random database password directly into Kubernetes, without saving it in repository files. This creates the Secret only if missing; changing it afterwards also requires a database password rotation.

```bash
if ! kubectl get secret stockroom-db-secret -n stockroom >/dev/null 2>&1; then
  python3 - <<'PY' | kubectl apply -f -
import json, secrets
print(json.dumps({"apiVersion":"v1","kind":"Secret","metadata":{"name":"stockroom-db-secret","namespace":"stockroom"},"type":"Opaque","stringData":{"POSTGRES_PASSWORD":secrets.token_hex(32)}}))
PY
fi
```

The generated hex password is safe inside the database connection URI. If supplying your own password, URI-encode reserved characters before using this chart's URL assembly.

## 4. Deploy through GitOps

```bash
kubectl apply -f gitops/argocd-application.yaml
kubectl get applications -n argocd -w
kubectl get pods,svc,pvc,hpa -n stockroom
kubectl rollout status deployment/stockroom-backend -n stockroom --timeout=300s
kubectl rollout status deployment/stockroom-frontend -n stockroom --timeout=300s
kubectl get deployment stockroom-backend stockroom-frontend -n stockroom -o wide
kubectl get ingress -n stockroom
```

Wait for Argo CD **Synced AND Healthy**, inspect its synced Git revision, and confirm both Deployment images use the promoted SHA. A promotion job finishing does not prove rollout health. Argo CD renders Helm without creating a Helm release, so `helm list` will not show the Argo-managed application.

**The grading rubric separately asks for a Helm release demonstration.** Before enabling Argo CD, demonstrate the same chart with:

```bash
kubectl create namespace stockroom-helm-demo
# Create a separate stockroom-db-secret in this namespace using the same method above.
helm upgrade --install stockroom ./helm/stockroom -n stockroom-helm-demo \
  -f helm/stockroom/values-eks.yaml -f helm/stockroom/values-gitops.yaml \
  --set ingress.host=stockroom-helm.local --wait --timeout 10m
helm list -n stockroom-helm-demo
```

Capture its working evidence, then choose a controlled handover. The simplest classroom approach is to perform the Helm demonstration in a separate disposable namespace with its own DB Secret, capture evidence, and uninstall that release before the Argo demonstration. Do not have Helm and Argo simultaneously manage the same live release, and remember Helm uninstall deletes this chart's PVC/data. For retaining data during a handover, explicitly plan ownership/PVC retention first.

Set `ingress.host` to your real hostname in values and configure DNS to the ingress controller's external address. `stockroom.local` is a local lab hostname, not public DNS. For testing an AWS load-balancer DNS name without public DNS, use `curl -H 'Host: stockroom.local' http://<load-balancer-dns>/api/products` or a local port-forward/hosts setup. Confirm the UI and all API routes through the same Ingress.

## 5. Observe, scale and demonstrate

```bash
kubectl top pods -n stockroom
kubectl get hpa -n stockroom -w
# In another terminal, against your accessible host:
BASE_URL=http://stockroom.local bash scripts/load-test.sh 120 16
kubectl logs -n stockroom deployment/stockroom-backend --tail=100
kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9090:9090
# Separate terminal:
kubectl port-forward -n monitoring svc/monitoring-grafana 3001:80
```

Get Grafana's generated admin password from its Kubernetes Secret privately. Confirm the Stockroom ServiceMonitor appears on Prometheus Targets as UP and open the Stockroom dashboard. Generate API traffic long enough for rate windows to populate. Capture observed HPA scaling; installing an HPA alone is not scaling evidence.

Push a visible app change, follow CI → SHA images → values promotion → Argo reconciliation, and show the updated app. Finish the [failure investigation lab](TROUBLESHOOTING.md).

## 6. Tear down after evaluation

Capture evidence first and back up any data you need. Disable Argo reconciliation/delete the application and wait for its resources to terminate. Uninstall bootstrap Helm releases including ingress load balancers, delete disposable PVCs and wait for load-balancer/volume cleanup before destroying the VPC. Deleting a namespace alone does not guarantee external AWS resources have disappeared.

```bash
kubectl delete application stockroom -n argocd --wait=true
helm uninstall traefik -n ingress
helm uninstall monitoring -n monitoring
helm uninstall metrics-server -n kube-system
helm uninstall argocd -n argocd
cd terraform
terraform plan -destroy
terraform destroy
```

Record the completed destroy output and check AWS for leftover load balancers, EBS volumes and other non-Terraform resources. Do not claim zero charges merely because an application pod was removed.
