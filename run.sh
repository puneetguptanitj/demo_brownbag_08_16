 #!/bin/bash -x

DEMO_RUN_FAST=1
. utils.sh

function figlet_string(){
   read -s
   clear
   figlet $1
}
export KUBECONFIG=~/.kube/config
minikube update-context
MASTER_IP=$(minikube ip)

figlet_string "Minikube"

desc "[MINIKUBE] brew install minikube, then minikube start" 
run "minikube status"  

desc "[MINIKUBE] nodes in the cluster"
run "kubectl get nodes"


figlet_string "Pods"

desc "[POD-USING-HTTP] API server IP"
run "minikube ip"

desc "[POD-USING-HTTP] Simple pod yaml (declarative, no mention of HOW only specifies WHAT)"
run "cat simple-nginx-pod.yaml"

 
desc "[POD-USING-HTTP] Pod creation is essentially an HTTP POST" 
dry_run "curl -X POST --data-binary @simple-nginx-pod.yaml 
              -H 'Content-type:application/yaml' 
               https://$MASTER_IP:8443/api/v1/namespaces/default/pods
               --cacert  /Users/puneet.gupta2/.minikube/ca.crt
               --cert  /Users/puneet.gupta2/.minikube/client.crt
               --key  /Users/puneet.gupta2/.minikube/client.key " 
curl -X POST --data-binary @simple-nginx-pod.yaml -H 'Content-type:application/yaml' https://$MASTER_IP:8443/api/v1/namespaces/default/pods --cacert  /Users/puneet.gupta2/.minikube/ca.crt --cert  /Users/puneet.gupta2/.minikube/client.crt --key  /Users/puneet.gupta2/.minikube/client.key
printf "\n"

desc "[POD-USING-HTTP] Pod deletion"
dry_run "curl -X DELETE  https://$MASTER_IP:8443/api/v1/namespaces/default/pods/nginx
              --cacert  /Users/puneet.gupta2/.minikube/ca.crt
              --cert  /Users/puneet.gupta2/.minikube/client.crt
              --key  /Users/puneet.gupta2/.minikube/client.key "
curl -X DELETE  -H 'Content-type:application/yaml' https://$MASTER_IP:8443/api/v1/namespaces/default/pods/nginx --cacert  /Users/puneet.gupta2/.minikube/ca.crt --cert  /Users/puneet.gupta2/.minikube/client.crt --key  /Users/puneet.gupta2/.minikube/client.key -d '{"gracePeriodSeconds":1,"propagationPolicy":"Background"}'
printf "\n"

desc "[POD-USING-KUBECTL] kubectl is just a symantically richer wrapper over http"
run "kubectl create -f simple-nginx-pod.yaml"

desc "[POD-USING-KUBECTL] kubectl is just a symantically richer wrapper over http"
dry_run "kubectl delete -f simple-nginx-pod.yaml" 
kubectl delete -f simple-nginx-pod.yaml --grace-period=0 --wait=false
printf "\n"

desc "============== SWITCH BACK TO SLIDES =============="
read -s

figlet_string "Controllers"

desc "[POD-WITH-CONTROLLER] Deployment controller spec"
run "cat deployment-controller.yaml"

desc "[POD-WITH-CONTROLLER] Create deployment" 
run "kubectl create -f deployment-controller.yaml"

desc "[POD-WITH-CONTROLLER] Control loop decorator on top of a pod" 
run "kubectl describe deployment nginx-deployment"

DELETE_POD=$(kubectl get pods | grep nginx | head -n1 | awk '{print $1}')
desc "[POD-WITH-CONTROLLER] Let us delete one of the replicas" 
run "kubectl delete pod $DELETE_POD" 

desc "[POD-WITH-CONTROLLER] Manually scale up" 
run "kubectl scale deployment.v1.apps/nginx-deployment --replicas=10"

desc "[POD-WITH-CONTROLLER] Manually scale down" 
run "kubectl scale deployment.v1.apps/nginx-deployment --replicas=5"

DELETE_REPLICASET=$(kubectl get replicaset | grep nginx | head -n1 | awk '{print $1}')
desc "[POD-WITH-CONTROLLER] Two level controllers"
run "kubectl delete replicaset $DELETE_REPLICASET" 

desc "============== SWITCH BACK TO SLIDES =============="
read -s

figlet_string "Services"

desc "[SVC example] How do we access a deployment that has > 1 replicas"
run "kubectl expose deployment nginx-deployment --type=NodePort --name=example-service"

desc "[SVC example] Dscribe svc" 
run "kubectl describe svc example-service" 

desc "[SVC example] Curl while true"
run "cat ./curl_to_svc.py"

desc "[SVC example] Curl while true"
run "python ./curl_to_svc.py 1 1"

desc "[SVC example] IP tables"
run "minikube ssh sudo iptables-save "

figlet_string "HPA"

desc "[HPA example] Get metrics, Kubelet summary API"
desc "[HPA example] Node level stats"
dry_run "minikube ssh 'curl http://localhost:10255/stats/summary' | jq .node | jq keys"
minikube ssh 'curl http://localhost:10255/stats/summary' | jq .node | jq keys

desc "[HPA example] Get metrics, Kubelet summary API"
desc "[HPA example] Pod level stats"
dry_run "minikube ssh 'curl http://localhost:10255/stats/summary' | jq .pods | jq .[1] | jq keys"
minikube ssh 'curl http://localhost:10255/stats/summary' | jq .pods | jq .[1] | jq keys

desc "[HPA example] Metrics server, api group"
dry_run "kubectl get --raw "/apis" | jq | tail -n 30"
kubectl get --raw "/apis" | jq | tail -n 30

desc "[HPA example] Metrics server, summary aggregator"
dry_run 'curl -H "Content-type:application/json"
               https://$MASTER_IP:8443/apis/metrics.k8s.io/v1beta1/namespaces/default/pods?labelSelector=app%%3Dnginx
               -cacert  /Users/puneet.gupta2/.minikube/ca.crt
               --cert  /Users/puneet.gupta2/.minikube/client.crt
               --key  /Users/puneet.gupta2/.minikube/client.key'
curl -H 'Content-type:application/json' https://$MASTER_IP:8443/apis/metrics.k8s.io/v1beta1/namespaces/default/pods?labelSelector=app%3Dnginx --cacert  /Users/puneet.gupta2/.minikube/ca.crt --cert  /Users/puneet.gupta2/.minikube/client.crt --key  /Users/puneet.gupta2/.minikube/client.key

desc "[HPA example] Allows scaling of pods based on metrics. Kubernetes uses metrics server to send metrics to API server"
run "kubectl get pods -n kube-system"

desc "[HPA example] To confirm things are configured correctly, use top"
run "kubectl top pod --all-namespaces"

desc "[HPA example] HPA controller spec"
run "cat hpa.yaml"

desc "[HPA example] HPA controller spec"
run "kubectl create -f hpa.yaml"

desc "[HPA example] Describe HPA"
run "kubectl describe hpa hpa-example"

desc "[HPA example] Lets first scale down the deployment to 1 pod"
run "kubectl scale deployment.v1.apps/nginx-deployment --replicas=1"

desc "[HPA example] Create load so that HPA tries to scale the deployment to match the load"
run "python ./curl_to_svc.py 0 3"


desc "[HPA example] HPA controller updates the deployment spec"
dry_run "kubectl describe deployment | grep Replicas"
kubectl describe deployment | grep Replicas

desc "============== SWITCH BACK TO SLIDES =============="
read -s

desc "[TEARDOWN] delete deployment"
run "kubectl delete deployments nginx-deployment"

desc "[TEARDOWN] delete service"
run "kubectl delete svc example-service"

desc "[TEARDOWN] delete hpa"
run "kubectl delete hpa hpa-example"


figlet_string "Helm"

desc "[HELM] Contents of a helm charts"
dry_run "tree oldchart "
tree oldchart 

desc "[HELM] Contents of a helm charts"
dry_run "vi oldchart/templates/old.yaml"
vi oldchart/templates/old.yaml

desc "[HELM] Contents of a helm charts"
dry_run "vi oldchart/values.yaml"
vi oldchart/values.yaml

desc "[HELM ] Tiller is to helm as API server is to kubectl"
dry_run "kubectl get pods -n kube-system | grep tiller"
kubectl get pods -n kube-system | grep tiller

desc "[HELM] Install a chart"
run "helm install --name old ./oldchart"

desc "[HELM] List of charts"
run "helm list"

desc "[HELM] All resources installed by the chart"
run "helm status old"


desc "============== SWITCH BACK TO SLIDES =============="
read -s

desc "[HELM UPGRADE] Contents of a helm charts"
dry_run "tree oldchart newchart"
tree oldchart newchart

desc "[HELM UPGRADE] Difference between the two" 
dry_run "vimdiff oldchart/templates/old.yaml newchart/templates/new.yaml"
vimdiff oldchart/templates/old.yaml newchart/templates/new.yaml

desc "[HELM UPGRADE] Difference between the two" 
dry_run "vimdiff oldchart/templates/existing.yaml newchart/templates/existing.yaml"
vimdiff oldchart/templates/existing.yaml newchart/templates/existing.yaml

desc "[HELM UPGRADE] Upgrade to new chart."
desc "1. Adds a new deployment"
desc "2. Removes an old deployment"
desc "3. Updates number of replicas of existing deployement"
run "helm upgrade old ./newchart"

desc "[HELM ROLLBACK] Rollback to old version"
run "helm rollback old 0"

desc "[TEARDOWN] Remove helm charts"
run "helm delete old --purge"

figlet_string "ZDT"

desc "[ZDT] ZDT Upgrade using Deployment object's rolling upgrade feature"
run "cat  zdt_v1.yaml"

desc "[ZDT] Deployment that we would be upgrading it to"
dry_run "vimdiff zdt_v1.yaml zdt_v2.yaml"
vimdiff zdt_v1.yaml zdt_v2.yaml

desc "[ZDT] Deploy v1"
run "kubectl apply -f zdt_v1.yaml"

desc "[ZDT] Simulate clients using the service continuously"
run "python ./curl_zdt_test.py 0.5 1"

desc "[TEARDOWN] Cleanup"
run "kubectl delete deployment zdt-deployment"

desc "[TEARDOWN] Cleanup"
run "kubectl delete service zdt-service"

figlet_string "Thanks!!"
