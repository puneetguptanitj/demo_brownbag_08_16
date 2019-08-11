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
run "kubectl scale deployment.v1.apps/nginx-deployment --replicas=1"

DELETE_REPLICASET=$(kubectl get replicaset | grep nginx | head -n1 | awk '{print $1}')
desc "[POD-WITH-CONTROLLER] Two level controllers"
run "kubectl delete replicaset $DELETE_REPLICASET" 


desc "Creates helm chart with the following contents"
run "tree mychart"

desc "[CREATE HELM CHART]  helm create mychart " 
desc "Creates helm chart with the following contents"
run "tree mychart"
