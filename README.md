
K8s Guidelines Example Helm Charts
==================================

The following are a set of Helm Charts that are used as part of the container orchestration guidelines.  These have been tested on minikube v1.0.1 with Kubernetes v1.14.1 on Ubuntu 18.04, using Helm v2.13.1.

Minikube
========

Using [Minikube](https://kubernetes.io/docs/getting-started-guides/minikube/) enables us to create a single node stand alone Kubernetes cluster for testing purposes.  If you already have a cluster at your disposal, then you can skip forward to 'Running the TM Integration on Kubernetes'.

The generic installation instructions are available at https://kubernetes.io/docs/tasks/tools/install-minikube/.

Minikube requires the Kubernetes runtime, and a host virtualisation layer such as kvm, virtualbox etc.  Please refer to the drivers list at https://github.com/kubernetes/minikube/blob/master/docs/drivers.md .

Ensure that the inbuilt NGINX Ingress controller is enables with:
```
minikube addons enable ingress
```

Helm Chart
----------

The Helm Chart based install of the TM Integration relies on [Helm](https://docs.helm.sh/using_helm/#installing-helm) (surprise!).  The easiest way to install is using the install script:
```
curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash
```

Running the TM Integration on Kubernetes
----------------------------------------

The basic configuration for each component of the Tango Controls example is held in the `values.yaml` file in each chart directory eg: `charts/tango-chart-example/values.yaml`.

The mode that we are using Helm in here is purely for templating - this avoids the need to install the Tiller process on the Kubernetes cluster, and we don't need to be concerned about making it secure (requires TLS and the setup of a CA).

To see all the make targets and configurable variables, run:
```
$make
```

Create the initial set of SSL certificates for the Ingress with:
```
$ make mkcerts
```

On for the main event - we launch the Charts/s with:
```
$ make deploy
```

This will give extensive output describing what has been deployed in the test namespace:
```
kubectl describe namespace default || kubectl create namespace default
Name:         default
Labels:       <none>
Annotations:  <none>
Status:       Active

No resource quota.

No resource limits.
persistentvolume/tangodb-tango-chart-example-test unchanged
persistentvolumeclaim/tangodb-tango-chart-example-test unchanged
service/databaseds-tango-chart-example-test unchanged
statefulset.apps/databaseds-tango-chart-example-test unchanged
service/tango-rest-tango-chart-example-test unchanged
deployment.extensions/tango-rest-tango-chart-example-test unchanged
service/tangodb-tango-chart-example-test unchanged
statefulset.apps/tangodb-tango-chart-example-test unchanged
pod/tango-example-tango-chart-example-test unchanged
ingress.extensions/api-tango-chart-example-test configured
```

Please wait patiently - it will take time for the Container images to download, and for the database to initialise.  After some time, you can check what is running with:
```
watch kubectl get all,pv,pvc,ingress
```

Which will give output like:
```
Every 2.0s: kubectl get all,pv,pvc,ingress                                                   wattle: Thu May  2 05:24:24 2019

NAME                                                       READY   STATUS    RESTARTS   AGE
pod/databaseds-tango-chart-example-test-0                  1/1     Running   0          11h
pod/tango-example-tango-chart-example-test                 1/1     Running   2          11h
pod/tango-rest-tango-chart-example-test-77878466bc-c8c85   1/1     Running   0          11h
pod/tango-rest-tango-chart-example-test-77878466bc-dc5g9   1/1     Running   0          11h
pod/tango-rest-tango-chart-example-test-77878466bc-hwqfk   1/1     Running   0          11h
pod/tangodb-tango-chart-example-test-0                     1/1     Running   0          11h

NAME                                          TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)     AGE
service/databaseds-tango-chart-example-test   ClusterIP   None             <none>        10000/TCP   11h
service/kubernetes                            ClusterIP   10.96.0.1        <none>        443/TCP     15h
service/tango-rest-tango-chart-example-test   ClusterIP   10.100.107.214   <none>        80/TCP      11h
service/tangodb-tango-chart-example-test      ClusterIP   None             <none>        3306/TCP    11h

NAME                                                  READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/tango-rest-tango-chart-example-test   3/3     3            3           11h

NAME                                                             DESIRED   CURRENT   READY   AGE
replicaset.apps/tango-rest-tango-chart-example-test-77878466bc   3         3         3       11h

NAME                                                   READY   AGE
statefulset.apps/databaseds-tango-chart-example-test   1/1     11h
statefulset.apps/tangodb-tango-chart-example-test      1/1     11h

NAME                                                CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM
                      STORAGECLASS   REASON   AGE
persistentvolume/tangodb-tango-chart-example-test   1Gi        RWO            Retain           Bound    default/tangodb-tango
-chart-example-test   standard                11h

NAME                                                     STATUS   VOLUME                             CAPACITY   ACCESS MODES
  STORAGECLASS   AGE
persistentvolumeclaim/tangodb-tango-chart-example-test   Bound    tangodb-tango-chart-example-test   1Gi        RWO
  standard       11h

NAME                                              HOSTS                          ADDRESS         PORTS     AGE
ingress.extensions/api-tango-chart-example-test   tango-example.minikube.local   192.168.86.47   80, 443   11h
```

To setup your local /etc/hosts file to point to the Minikube Kubernetes Ingress with a default hostname of tango-example.minikube.local, run:
```
$make localip
```

Now you should be able to access the Tango Controls REST API server, with:
```
$make test
```

This should give output like:
```
$ make test
---------------------------------------------------
test http:
curl -u "tango-cs:tango" -XGET http://tango-example.minikube.local/tango/rest/rc4/hosts/databaseds-tango-chart-example-test/10000 || \
curl -vvv -u "tango-cs:tango" -XGET http://tango-example.minikube.local/tango/rest/rc4/hosts/databaseds-tango-chart-example-test/10000
{"name":"sys/database/2","host":"databaseds-tango-chart-example-test-0.databaseds-tango-chart-example-test.default.svc.cluster.local","port":10000,"info":["TANGO Database sys/database/2"," ","Running since 2019-05-01 06:22:21"," ","Devices defined  = 22","Devices exported  = 16","Device servers defined  = 11","Device servers exported  = 8"," ","Device properties defined  = 14 [History lgth = 14]","Class properties defined  = 66 [History lgth = 0]","Device attribute properties defined  = 0 [History lgth = 0]","Class attribute properties defined  = 0 [History lgth = 0]","Object properties defined  = 0 [History lgth = 0]"],"devices":"http://tango-example.minikube.local/tango/rest/rc4/hosts/databaseds-tango-chart-example-test/10000/devices"}, echo
---------------------------------------------------
test https:
curl -k -u "tango-cs:tango" -XGET https://tango-example.minikube.local/tango/rest/rc4/hosts/databaseds-tango-chart-example-test/10000 || \
curl -vvv -k -u "tango-cs:tango" -XGET https://tango-example.minikube.local/tango/rest/rc4/hosts/databaseds-tango-chart-example-test/10000
{"name":"sys/database/2","host":"databaseds-tango-chart-example-test-0.databaseds-tango-chart-example-test.default.svc.cluster.local","port":10000,"info":["TANGO Database sys/database/2"," ","Running since 2019-05-01 06:22:21"," ","Devices defined  = 22","Devices exported  = 16","Device servers defined  = 11","Device servers exported  = 8"," ","Device properties defined  = 14 [History lgth = 14]","Class properties defined  = 66 [History lgth = 0]","Device attribute properties defined  = 0 [History lgth = 0]","Class attribute properties defined  = 0 [History lgth = 0]","Object properties defined  = 0 [History lgth = 0]"],"devices":"http://tango-example.minikube.local/tango/rest/rc4/hosts/databaseds-tango-chart-example-test/10000/devices"}
```

To clean up the Helm Chart release:
```
$make delete
```
