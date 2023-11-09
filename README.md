# Using Red Hat Service Mesh to expose pure TCP services

## Problem description

OpenShift Ingress Router can handle HTTP and TLS (with SNI) protocols only, a pure TCP (or UDP) service cannot be exposed via the OCP Router.

Possibile solutions are:

- `NodePort` services: works well but can be tricky because the allocated port on the node is different from the service port
- `ExternalIP` services: do not works on cloud platforms
- `LoadBalancer` services: works well and is a common approach on cloud platform, but will create a cloud load balancer per each service
- Service Mesh Ingress Gateway: this is the approach of this demo

## Running the demo

### Requirements

- You need an OCP cluster on AWS (can work on any other platform with some small modifications)
- Red Hat Service Mesh must be installed on the cluster (see the [doc](https://docs.openshift.com/container-platform/4.13/service_mesh/v2x/installing-ossm.html))
- The demo will create the `istio-system` namespace and the `ServiceMeshControlPlane`
- The demo is scripted with [demo.sh](https://github.com/pbertera/demo.sh) you need the script

### How it works

#### Gateway Injection demo

`rundemo-Injection.sh` uses the ingress gateway injection feature to create 2 Ingress gateways exposing 2 applications listening on TCP ports.

1. Creates the `istio-system` namespace with a basic `ServiceMeshControlPlane`
2. Creates the `gateways` namespace where the gateways will be executed
3. Creates the `echoserver-8000` and the `echoserver-9000` namespaces
4. `gateways`, `echoserver-8000` and the `echoserver-9000` namespaces are joined to the mesh
5. Creates 3 Deployments and 3 `ClusterIP` services into the `echoserver-8000` exposing 3 TCP echo servers listening on the ports 8081,8082,8083
6. Creates 3 Deployments and 3 `ClusterIP` services into the `echoserver-9000` exposing 3 TCP echo servers listening on the ports 9091,9092,9093
7. Into the `gateways` ns creates 2 `Deployment` where the Ingress gateway is injected, Deployments are exposed with a corresponding `LoadBalancer` service
8. Creates the `Gateway` and the `VirtualService` resources to expose the internal services externally

#### Control Plane Gateway

- `rundemo-SMCP.sh` uses the Ingress Gateway of the control plane to expose some TCP ports

This demo exposes the Ingress Gateway of the Service Mesh Control plane with a LoadBalancer service and routes the TCP requests to the internal services.
