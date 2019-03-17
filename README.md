# demo K8s IAC Proto

This repo is an `prototype` on the deployment architecture of a microservice and currently dev in progress.
This should be visualized as a baseline to create a microservice deployment leveraging the following capabilities

| SNo| Artifact                      |Capabilities                                            |
|----|-------------------------------|--------------------------------------------------------|
|1   |Core Kubernetes                |Replication Set,HPA,Service Discovery                   |
|2   |Helm Chart                     |Deployment template,Umbrella chart,subcharts            |                            |3   |Istio                          |Service Mesh,Virtual Service,Gateway,Canary deployment  |  
|4   |Resource Monitoring & Logging  |k8s dashboard,Grafana,ServiceGraph,Jaeger,Kibana        | 
  
`Note` This repo `doesn't` cover the OAuth2 spring implementation code itself.That is part of a different repo and will be published soon.This repo talks only on the deployment part of the infrastructure.
   
## Requirements

 `Minikube` installed,`kubectl` is configured to talk to some K8S cluster, also  `helm` and `Istio` installed.

## Prototype Environment
   
   `os` - Windows 10 with headless Vbox
   `kubernetes Cluster` -Minikube
    
As this local deployment focus only on `CD` part of the flow, Docker images are build locally and injected to `Minikube`
To inject docker image to a cluster simply login to the cluster using `minikube ssh` command and then execute docker    build command 
The Docker images under `/docker` have 2 basic spring boot app build as `myapp` as a frontend app which interns calls a backend microservice `backapp`.

Also Ideally in an actual cluster there should be an LB that will relay traffic to `Istio` gateway but as this is a local `Minikube` instance we are going to expose the `Istio` ingress service as `NodePort` so that we can connect to it using Kube IP. Use `Kubectl apply` command to inject `/local/ingress_add_port.yaml`config changes to the cluster


## Installation

The Umbrella chart installs its' subcharts, which in turn depend on the Common chart
Use the following command 
```
helm-dep-up-umbrella.bat <<rc1>> 
```
where rc1 is the release name.
  
This will first compile charts and then deploy the entire set  of microservice `frontend,backend and network` to K8s cluster.To modify the image tags and other configurations,tweak below to config files as per need

--`/global/values` holds pod deployment related configs modify image tag version,canary type,service port, hpa etc here<br>
--`/network/route/values`  lays down the config for intelligent routing   <br>   

 to deploy a canary deployment update `/global/values` for `istio.carnary` to true and probably use a different image tag.Then run the umberella command as usal to deploy a new set
```
helm-dep-up-umbrella.bat <<rc2>> 
```
 where rc2 is the canary release name.

Once deployed check for all deployments using 

```kubectl get pods,svc,virtualservice,deployment,destinationrule,hpa```

  
## Use cases

### Mange and Monitor

Open various `mangement portals` using the link set displayed in console post executing the umbrella script.
```
K8s Dashboard: run minikube dashboard
grafana : http://localhost:3000
tracing : http://localhost:16686
ServiceGraph : http://localhost:8088/force/forcegraph.html
Kibana : http://192.168.99.119:30621 (Disabled in Local for memory usage)
```
### HPA , LB , Tracing...

Check loadbalancing, autoscaling, tracing features firing up the pods with random requests as below
```$while true; do   curl -s http://192.168.99.119:31391/hello;   echo "";   sleep 1; done```

### Graceful shutdown of Pods

use `liveness` and `readiness` probes for a graceful shutdown.
`Note`: Current readiness probe is not functioning properly and it is in dev in progress.

### Plan your deployment and rope in any versions of individual services to create a release set
Use the umbrella chart values to deploy a set of microservice as needed by modifying `/global/values`

###  Internal routing in Spring boot using Rest Template
Internally the frontend microservice calls the backend microservice using the K8s Service registry DNS.The virtual service on top of this creates the additional intelligent routing based on the weight-age or other header parameters passed.

``` java @GetMapping("/hello")  
public String index() throws UnknownHostException {  
    LOG.info("Printing Hello World message");  
  RestTemplate restTemplate = new RestTemplate();  
  String resourceUrl = "http://"+"backapp";  
  ResponseEntity<String> response    = restTemplate.getForEntity(resourceUrl, String.class);  
 return " Message from frontend modified is "+version+ InetAddress.getLocalHost().getHostName()+"\n\n"+"Message from backend  is: " + response.getBody();  
  }```
