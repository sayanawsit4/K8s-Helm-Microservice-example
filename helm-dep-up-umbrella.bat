@ECHO off
set arg1=%1
ECHO release version ................%arg1%
IF [%1] == []  EXIT /b
ECHO Compiling Charts

ECHO Compiling frontend microservice charts....
CMD /c "helm dep up frontend/myapp"
ECHO Compiling backend microservice charts....
CMD /c "helm dep up backend/backapp"
ECHO Compiling global microservice charts....
CMD /c "helm dep up global"
ECHO Compiling virtual services for microservice intercomm....
CMD /c "helm dep up network/route"

ECHO Charts are updated....
ECHO Ensure that you have correct config spec for the following 
ECHO *************************
ECHO Deployment (Adjust Image tag,HPA)  : global/values.yaml
ECHO Network (Adjust Carnary Weight, Virtual SVC routing): network/values.yaml
ECHO *************************

ECHO starting Deployment
ECHO release name is %arg1%
CMD /c "helm delete --purge %arg1%" 
CMD /c "helm delete --purge rc1n"
CMD /c "helm install global --name=%arg1%"
CMD /c "helm install network/route --name=rc1n"
REM CMD /c "kubectl apply --filename https://raw.githubusercontent.com/giantswarm/kubernetes-elastic-stack/master/manifests-all.yaml"

ECHO Below are the cluster monitoring and management endpoints
ECHO **********************************************************
ECHO K8s Dashboard: http://127.0.0.1:61642/api/v1/namespaces/kube-system/services/http:kubernetes-dashboard:/proxy/
ECHO grafana : http://localhost:3000
ECHO tracing : http://localhost:16686
ECHO ServiceGraph : http://localhost:8088/force/forcegraph.html
ECHO Kibana : http://192.168.99.119:30621 (Disabled in Local for memory usage)

ECHO  Run the below commands to view the above portals
ECHO  minikube dashboard
ECHO  kubectl -n istio-system port-forward grafana-5c45779547-d8s5x 3000:3000
ECHO  kubectl port-forward -n istio-system istio-tracing-5576449bd9-9gt8r 16686:16686
ECHO  kubectl -n istio-system port-forward  servicegraph-559df9c549-69flx 8088:8088