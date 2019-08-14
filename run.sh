 #!/bin/bash -x

DEMO_RUN_FAST=1
. utils.sh

clear

export KUBECONFIG=/Users/puneet.gupta2/Downloads/35030/kubeconfig
kubectl config use-context minikube

desc "[MINIKUBE] brew install minikube, then minikube start" 
run "minikube status"  

desc "[POD-USING-HTTP] Simple pod yaml (declarative, no mention of HOW only specifies WHAT)"
run "cat simple-nginx-pod.yaml"

desc "[POD-USING-HTTP] API server IP"
run "minikube ip"

MASTER_IP=$(minikube ip)
 
desc "[POD-USING-HTTP] Pod creation is essentially an HTTP POST" 
COMMAND="curl -X POST --data-binary @simple-nginx-pod.yaml -H 'Content-type:application/yaml' https://$MASTER_IP:8443/api/v1/namespaces/default/pods --cacert  /Users/puneet.gupta2/.minikube/ca.crt --cert  /Users/puneet.gupta2/.minikube/client.crt --key  /Users/puneet.gupta2/.minikube/client.key " 
desc "$COMMAND"
read -s
eval $COMMAND

desc "[POD-USING-HTTP] Pod deletion"
COMMAND="curl -X DELETE https://$MASTER_IP:8443/api/v1/namespaces/default/pods/nginx --cacert  /Users/puneet.gupta2/.minikube/ca.crt --cert  /Users/puneet.gupta2/.minikube/client.crt --key  /Users/puneet.gupta2/.minikube/client.key "

desc "$COMMAND"
read -s
eval $COMMAND
sleep 3

desc "[POD-USING-KUBECTL] kubectl is just a symantically richer wrapper over http"
run "kubectl create -f simple-nginx-pod.yaml"

desc "[POD-USING-KUBECTL] kubectl is just a symantically richer wrapper over http"
run "kubectl delete -f simple-nginx-pod.yaml"

desc "============== SWITCH BACK TO SLIDES =============="
read -s

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

desc "[SVC example] How do we access a deployment that has > 1 replicas"
run "kubectl expose deployment nginx-deployment --type=NodePort --name=example-service"

desc "[SVC example] Dscribe svc" 
run "kubectl describe svc example-service" 

desc "[SVC example] Curl while true"
run "cat ./curl_to_svc.py"

desc "[SVC example] Curl while true"
run "python ./curl_to_svc.py 1 1"

desc "[SVC example] IP tables"
run "minikube ssh sudo iptables-save | grep KUBE-SVC"

desc "============== SWITCH BACK TO SLIDES =============="
read -s

desc "[HPA example] Allows scaling of pods based on metrics. Kubernetes uses metrics server to send metrics to API server"
run "kubectl get pods -n kube-system"

desc "[HPA example] To confirm things are configured correctly, use top"
run "kubectl top pod --all-namespaces"

desc "[HPA example] Lets first scale down the deployment to 1 pod"
run "kubectl scale deployment.v1.apps/nginx-deployment --replicas=1"

desc "[HPA example] HPA controller spec"
run "cat hpa.yaml"

desc "[HPA example] HPA controller spec"
run "kubectl create -f hpa.yaml"

desc "[HPA example] Create load so that HPA tries to scale the deployment to match the load"
run "python ./curl_to_svc.py 0 3"

desc "[HPA example] To confirm things are configured correctly, use top"
run "kubectl top pod --all-namespaces"

desc "Creates helm chart with the following contents"
run "tree mychart"

desc "[CREATE HELM CHART]  helm create mychart " 
desc "Creates helm chart with the following contents"
run "tree mychart"

desc "[TEARDOWN] delete deployment"
run "kubectl delete deployments nginx-deployment"

desc "[TEARDOWN] delete service"
run "kubectl delete svc example-service"

desc "[TEARDOWN] delete hpa"
run "kubectl delete hpa hpa-example"

