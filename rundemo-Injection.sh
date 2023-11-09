#!/bin/bash

. demo.sh

set -e

clear

#DEMO_DEBUG=yes
DEMO_AUTO_TYPE=no
DEMO_SPEED=0.01
DEMO_CSIZE=4
#DEMO_NOWAIT=no
PROJECT_8000=echo-server-8000
PROJECT_9000=echo-server-9000
GW_PROJECT=gateways

ps1_bg_color=${c['bg_CYAN']}
ps1_color=${c['ORANGE']}
ps1_demo="RHSM Demo"

ps1() {
    echo -ne "${ps1_bg_color}${ps1_color}${ps1_demo}${c['reset']}${c['CYAN']} ${c['BLUE']}\$${c['reset']} "
}


function create_app(){
  PORT="$1"
  PROJECT="$2"
  pi "# Let's create the application listening on port $PORT in project $PROJECT"
  app_manifest=$(cat manifests/app-tcp.yaml | PORT=$PORT envsubst)
  p "cat << EOF | oc create -n $PROJECT -f -"
  echo "$app_manifest"
  echo EOF
  echo "$app_manifest" | oc create -n $PROJECT -f -
}

function create_gateway_deploy(){
  APP="$1"
  pi "# Let's create the deployment of the Ingress Gateway 'ingressgateway-$APP'"
  gw_deploy_manifest=$(cat manifests/gateway-${APP}-deployment.yaml)
  p "cat << EOF | oc create -n $GW_PROJECT -f -"
  echo "$gw_deploy_manifest"
  echo EOF
  echo "$gw_deploy_manifest" | oc create -n $GW_PROJECT -f -
}

function create_gateway(){
  APP="$1"
  gw_manifest=$(cat manifests/gateway-${APP}.yaml)
  pi "# We now want to create the Gateway gateway-${APP} in order to expose the application"
  pi "# We want to create the Gateway into the $GW_PROJECT namespace"
  p "cat << EOF | oc create -n $GW_PROJECT -f -"
  echo "$gw_manifest"
  echo EOF
  echo "$gw_manifest" | oc create -n $GW_PROJECT -f -
}

function create_virtualservice(){
  APP="$1"
  pi "# We use a VirtualService echo-server-${APP} link the app services to the Gateway"
  pi "# We want to create the VirtualService into the $GW_PROJECT namespace"
  vs_manifest=$(cat manifests/virtualservice-${APP}.yaml)
  p "cat << EOF | oc create -n $GW_PROJECT -f -"
  echo "$vs_manifest"
  echo EOF
  echo "$vs_manifest" | oc create -n $GW_PROJECT -f -
}

pi "# Let's create the '$PROJECT_8000' project containing the applications listening on ports 8081,8082 and 8083"
pe "oc new-project $PROJECT_8000"

create_app 8081 $PROJECT_8000
create_app 8082 $PROJECT_8000
create_app 8083 $PROJECT_8000

pe "oc get pods,svc -n $PROJECT_8000"

pi "# Let's create the '$PROJECT_9000' project containing the applications listening on ports 9091,9092 and 9093"
pe "oc new-project $PROJECT_9000"

create_app 9091 $PROJECT_9000
create_app 9092 $PROJECT_9000
create_app 9093 $PROJECT_9000

pe "oc get pods,svc -n $PROJECT_9000"

pi "# We now need to expose the applications"
pi "# Let's create the istio-system namespace and the Service Mesh Control Plane"; sleep 1
pe "oc new-project istio-system"

scm_manifest=$(cat manifests/smcp.yaml)
pi 'cat << EOF | oc create -n istio-system -f -'
echo "$scm_manifest"
echo EOF
echo "$scm_manifest" | oc create -n istio-system -f -

#pi "# Let's have a look at the 'istio-ingressgateway' service"
#pe "oc get svc -n istio-system istio-ingressgateway -o yaml"

pi "# Let's create the '$GW_PROJECT' project containing the ingress gateways"
pe "oc new-project $GW_PROJECT"

pi "# Let's add the projects $PROJECT_8000,$PROJECT_9000 and $GW_PROJECT to the mesh"
smmr_manifest=$(cat manifests/servicemesh-memberroll-deploy.yaml | PROJECT_8000=$PROJECT_8000 PROJECT_9000=$PROJECT_9000 GW_PROJECT=$GW_PROJECT envsubst)
pi 'cat << EOF | oc create -n istio-system -f -'
echo "$smmr_manifest"
echo EOF
echo "$smmr_manifest" | oc create -n istio-system -f -

pi "# We need to create a role to access the secrets"
role_manifest=$(cat manifests/gateway-role.yaml)
pi "cat << EOF | oc create -n $GW_PROJECT -f -"
echo "$role_manifest"
echo EOF
echo "$role_manifest" | oc create -n $GW_PROJECT -f -

create_gateway_deploy 8000
create_gateway 8000
create_virtualservice 8000

create_gateway_deploy 9000
create_gateway 9000
create_virtualservice 9000

pi "# We can discover the AWS Load Balancer hostname for the ingressgateway-8000"
pe "oc -n $GW_PROJECT get service ingressgateway-8000 -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
NLB=$(oc -n $GW_PROJECT get service ingressgateway-8000 -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

pi "# You can now test the services:"
pi "# Port 8081: nc $NLB 8081"
pi "# Port 8082: nc $NLB 8082"
pi "# Port 8083: nc $NLB 8083"

pi "# We can discover the AWS Load Balancer hostname for the ingressgateway-9000"
pe "oc -n $GW_PROJECT get service ingressgateway-9000 -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
NLB=$(oc -n $GW_PROJECT get service ingressgateway-9000 -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

pi "# You can now test the services:"
pi "# Port 9091: nc $NLB 9091"
pi "# Port 9092: nc $NLB 9092"
pi "# Port 9093: nc $NLB 9093"
