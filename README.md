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

- You need an OCP cluster on AWS (the demo has been desinged for ROSA)
- Red Hat Service Mesh must be installed on the cluster (see the [doc](https://docs.openshift.com/container-platform/4.13/service_mesh/v2x/installing-ossm.html))
- The demo will create the `istio-system` namespace and the `ServiceMeshControlPlane`
- The demo is scripted with [demo.sh](https://github.com/pbertera/demo.sh) you need the script

### How it works

The demo deploys 3 applications composed by a `Deployment` and a `Service`. Each application runs a TCP echo server listening on a port:

- `nc-8081` rund the echo server on the 8081 port
- `nc-8082` rund the echo server on the 8082 port
- `nc-8083` rund the echo server on the 8083 port

After creating the application the demo creates the `istio-system` namespace and the `ServiceMeshControlPlane`.
The Control plane is configured to expose the Mesh and the 3 additional TCP ports with an AWS Network Load Balancer.

Into the `istio-system` namespace the `Gateway` resource is added in order to create the three servers.
The services are then exposed with the `VirtualService` resource.

### Cleanup

Just remove `istio-system` and `netcat` namespaces: `oc delete project netcat istio-system`
