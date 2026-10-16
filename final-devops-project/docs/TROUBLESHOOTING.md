# Failure investigation lab

Use an isolated capstone namespace. Record commands, observed output, root cause, fix and verification. The files below are deliberately broken; a real deployment has not yet been exercised by this document.

## 1. ImagePullBackOff

```bash
kubectl apply -f troubleshooting/broken-image.yaml
kubectl get pods -n stockroom
kubectl describe deployment stockroom-broken-image -n stockroom
kubectl get events -n stockroom --sort-by=.lastTimestamp
```

Inspect the manifest's resource name if it differs. Check the image repository/tag and package access. Replace the nonexistent image with a published SHA tag and configure `imagePullSecrets` if GHCR is private. Verify readiness and remove the lab Deployment when finished. Do not infer registry permission failures from ImagePullBackOff alone; read the event text.

## 2. Service without endpoints

```bash
kubectl apply -f troubleshooting/broken-service.yaml
kubectl get svc,endpoints -n stockroom
kubectl get pods -n stockroom --show-labels
```

Compare the Service selector with pod labels. Correct the selector and target port, verify endpoints are populated, then make an HTTP request through the Service. Delete the lab Service afterwards.

## 3. PostgreSQL pod Pending

Inspect `kubectl describe pvc -n stockroom` and pod events. On EKS, check `stockroom-gp3`, the EBS CSI controller, its IAM role and `WaitForFirstConsumer`. A Running API pod is not sufficient: `/ready` must succeed and CRUD must persist data.

## 4. HPA shows unknown CPU

Run `kubectl top pods -n stockroom`, inspect Metrics Server, and check that backend CPU requests are set. Prometheus is not a substitute for Metrics Server's resource metrics API. Generate bounded load with `BASE_URL=http://stockroom.local bash scripts/load-test.sh 120 16` and watch the HPA; document observed scaling rather than assuming it happened.

## 5. GitOps healthy but application not updated

Compare `values-gitops.yaml`, the GHCR SHA tag, Argo CD's synced Git revision and the Deployment's image. A green CI run can publish images without promoting if main advanced during the run. A promotion commit is desired state, not proof of a healthy rollout.
