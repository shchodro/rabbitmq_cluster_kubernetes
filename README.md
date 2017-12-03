# RabbitMQ cluster as stateful set in Kubernetes

Here is a stateful set for RabbitMQ cluster deployed to Kubernetes.
I spent some time searching for working solution, tried to use different Docker images and play with configuration to make it work in cluster as it's required. Here is a ready to go repo with Dockerfile with examples how to add and enable different plugins and set the RabbitMQ broker definitions during start up and Kubernetes ready yaml config which also is compatible with helm.

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

### Prerequisites

This works with Kubernetes 1.5 and above. Helm 2.2.2 and above.

### Installing

Clone the repository:

```
git clone https://github.com/shchodro/rabbitmq_cluster_kubernetes.git
```

Configure your `kubectl` to communicate with appropriate environment (see Kubernetes documentation).

## Deployment

Once you have configured Kubernetes cluster and can communicte with it using `kubectl`, you are ready to go.

First create a new secret to hold Erlang cookie:
```
kubectl create secret generic rabbitmq-config --from-literal=erlang-cookie=c-is-for-cookie-thats-good-enough-for-me
```

Then run `kubectl create -f /helm-chart/templates/rabbitmq.yaml`
Or using helm `helm install --name=rabbitmq helm-chart`

Wait a minute until cluster will be completely up. Then run `kubectl describe service rabbitmq-management` find an external IP and open in your browser `external_ip:15672`
Log in with username `admin` and password `*Password92!`. This is what we store in example `definitions.json`

Now run `kubectl delete pod rabbitmq-2` and watch what happens. Node will go red in management UI but then Kubernetes will recreate the same node.

## Production deployment

Create a persistence volume in your cluster. Then uncomment the following strings in  `helm-chart/templates/rabbitmq.yaml`:

```
...
volumeMounts:
- name: rabbitmq
  mountPath: /var/lib/rabbitmq

volumeClaimTemplates:
- metadata:
name: rabbitmq
annotations:
volume.alpha.kubernetes.io/storage-class: anything
spec:
accessModes: [ "ReadWriteOnce" ]
resources:
requests:
  storage: 1Gi # make this bigger in production
...
```

Prepare your own Dockerfile, add required plugins. If you need the plugin to be downloaded you can use `curl` (already in image) or install `wget` to store the `.ez` file. Save it to `/plugins`, then add a plugin name to the `RUN rabbitmq-plugins enable` command in Dockerfile. Or you can store it in extras and use `ADD` command to move it during the image creation.
In the example we use the `rabbitmq_delayed_message_exchange` and `rabbitmq_stomp` plugins. Stomp plugin uses port `61613`, so uncomment all rows describing this port in `helm-chart/templates/rabbitmq.yaml` before run this installation.

Upload the Broker definitions. The easiest way to have a preconfigured RabbitMQ node is to prepare the broker configuration (queues, exchanges, users, etc), go to web management page and on overview tab find a section `Export definitions` then save it to `extras/definitions.json`. Definitions will be applied during image creation.

Set an appropriate registry. Replace the example image with a link to your registry

```
...
spec:
  containers:
  - name: rabbitmq
    imagePullPolicy: Always
    image: rabbitmq:3.6.6-management-alpine #registry.gitlab.com/your_account/your_project:{{ .Values.revision }}
    lifecycle:
...
# also, you need the last two rows if you use your own registry
imagePullSecrets:
  - name: regsecret
```
I hope you are familiar how to configure secrets storage in your installation and this part is patently for you.

Now you need build and push an image and then install the stateful set by the same way as in Deployment section.

### Links
Thanks to
[Wes Morgans's blog post ](https://wesmorgan.svbtle.com/rabbitmq-cluster-on-kubernetes-with-statefulsets) to implement a way how to configure cluster with `postStart` command set.

### Known issues
`Helm upgrade` does'n recreate PODs. - In progress
Working on the best way to update the set.
