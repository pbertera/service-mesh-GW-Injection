#!/bin/bash

. demo.sh

set -e

clear

#DEMO_DEBUG=yes
DEMO_AUTO_TYPE=no
DEMO_SPEED=0.01
DEMO_CSIZE=4
#DEMO_NOWAIT=no
PROJECT=netcat

ps1_bg_color=${c['bg_CYAN']}
ps1_color=${c['ORANGE']}
ps1_demo="RHSM Demo"

ps1() {
    echo -ne "${ps1_bg_color}${ps1_color}${ps1_demo}${c['reset']}${c['CYAN']} ${c['BLUE']}\$${c['reset']} "
}


function create_app(){
  PORT="$1"
  pi "# Let's create the application listening on port $PORT"
  app_manifest=$(cat manifests/app-tcp.yaml | PORT=$PORT envsubst)
  p "cat << EOF | oc create -n $PROJECT -f -"
  echo "$app_manifest"
  echo EOF
  echo "$app_manifest" | oc create -n $PROJECT -f -
}

function create_gateway(){
  gw_manifest=$(cat manifests/gateway.yaml)
  pi "# We now want to create the Gateway in order to expose the application"
  pi "# We want to create the Gateway into the istio-system namespace"
  p "cat << EOF | oc create -n istio-system -f -"
  echo "$gw_manifest"
  echo EOF
  echo "$gw_manifest" | oc create -n istio-system -f -
}

function create_virtualservice(){
  pi "# We use a VirtualService link the app services to the Gateway"
  pi "# We want to create the VirtualService into the istio-system namespace"
  vs_manifest=$(cat manifests/virtualservice.yaml)
  p "cat << EOF | oc create -n istio-system -f -"
  echo "$vs_manifest"
  echo EOF
  echo "$vs_manifest" | oc create -n istio-system -f -
}

pi "# Let's create the '$PROJECT' project containing the applications"
pe "oc new-project $PROJECT"

create_app 8081
create_app 8082
create_app 8083

pi "# We now need to expose the applications"
pi "# Let's create the istio-system namespace and the Service Mesh Control Plane"; sleep 1
pe "oc new-project istio-system"
scm_manifest=$(cat manifests/smcp.yaml)
pi 'cat << EOF | oc create -n istio-system -f -'
echo "$scm_manifest"
echo EOF
oc create -f manifests/smcp.yaml

pi "# Let's have a look at the 'istio-ingressgateway' service"
pe "oc get svc -n istio-system istio-ingressgateway -o yaml"

pi "# Let's add the project '$PROJECT' to the mesh"
smmr_manifest=$(cat manifests/servicemesh-memberroll.yaml | PROJECT=$PROJECT envsubst)
pi 'cat << EOF | oc create -n istio-system -f -'
echo "$smmr_manifest"
echo EOF
echo "$smmr_manifest" | oc create -n istio-system -f -

create_gateway
create_virtualservice

pi "# We can discover the LoadBalancer hostname"
pe "oc -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"

NLB=$(oc -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

pi "# You can now test the services:"
pi "# Port 8081: nc $NLB 8081"
pi "# Port 8082: nc $NLB 8082"
pi "# Port 8083: nc $NLB 8083"
