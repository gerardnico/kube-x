# How to create a cluster

## About

A cluster is a directory that contains the following files:
* `values.yaml`: the `helmet` cluster values file
* `inventory.yml`: the ansible cluster host files (default to [inventory](../../resources/ansible/inventory.yml)
* `.envrc`: the env file. Environment variables can be used both in `values.yaml` and `inventory.yml`

## Example

You can see clusters example at [clusters](../../resources/clusters/README.md)

## Steps

### Create your clusters directory

A `clusters directory` is a directory that contains one or more cluster directory.

In your `.bashrc`
```bash
export KUBEE_CLUSTERS_PATH=~/kubee/clusters
```
Create your clusters directory
```bash
mkdir -p "$KUBEE_CLUSTERS_PATH"
```

### Create your cluster

#### Create a cluster directory

Create a `cluster directory`
```bash
KUBEE_CLUSTER_NAME=my-cluster
mkdir -p "$KUBEE_CLUSTERS_PATH/$KUBEE_CLUSTER_NAME"
```

#### Create the default values files

```bash
kubee helmet values > "$MY_CLUSTER_PATH/values.yaml" 
```

#### Create your environment

Environment variables are set up in `.envrc`

```bash
touch "$KUBEE_CLUSTERS_PATH/$KUBEE_CLUSTER_NAME/.envrc"
```


### Set your cluster env

Set at minimal the following environment variables in your `.envrc` file 
* `KUBEE_CLUSTER_SERVER_01_FQDN` - the full qualified server hostname. ie `server-01.example.com`
* `KUBEE_CLUSTER_SERVER_01_IP` - the server ip
* `KUBEE_CLUSTER_K3S_TOKEN` - the k3s token - A random secret value (You can generate one with `openssl rand -base64 64 | tr -d '\n'`)

Example in `.envrc`:
```bash
export KUBEE_CLUSTER_SERVER_01_FQDN='server-01.example.com'
export KUBEE_CLUSTER_SERVER_01_IP='188.245.43.202'
export KUBEE_CLUSTER_K3S_TOKEN='bib7F0biIxpUUuOJJpjs9EgzqViHjAVna3MyxGbTq++gjXf6tm7y5c7' # don't change it
```


* Check that all cluster hosts environments has been set by printing the inventory
```bash
kubee --cluster "$KUBEE_CLUSTER_NAME" cluster inventory
```
```yaml
k3s_cluster:
  children:
    server:
      hosts:
        node-name.example.com: 
           ....
```

### Set your cluster private key file

By default, `kubee` will load and use the default ssh private key files.

If you don't use them, you can define your ssh private file via one of this 2 environment variables in the cluster `.envrc` file:
* `KUBEE_CLUSTER_SERVER_CONNECTION_PRIVATE_KEY_FILE` : a private key path (without any passphrase)
* `KUBEE_CLUSTER_SERVER_CONNECTION_PRIVATE_KEY` : the private key content

Example `.envrc` file:
* From a file
```bash
export KUBEE_CLUSTER_SERVER_CONNECTION_PRIVATE_KEY_FILE=~/.ssh/server_01_rsa
```
* From a identity store such as [pass](https://www.passwordstore.org/)
```bash
export KUBEE_CLUSTER_SERVER_CONNECTION_PRIVATE_KEY
KUBEE_CLUSTER_SERVER_CONNECTION_PRIVATE_KEY=$(pass cluster_name/ssh/private_key)
```


You can check that you can connect to your cluster by pinging it
```bash
kubee --cluster "$KUBEE_CLUSTER_NAME" cluster ping
```
You should get
```
server-01.example.com | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```

### Execute the cluster installation

Once, you can connect to your cluster, you can install it with the `ping` command

Example:
```bash
kubee --cluster "$KUBEE_CLUSTER_NAME" cluster play
```

The `play` command is idempotent, meaning that you can run it multiple times. 

If the kubernetes app or an operating system package is:
* not installed, it will install and configure it 
* installed, it will configure it


### Install applications in the Kubernetes cluster


With `kubee helmet`, you can install apps with any [kubee charts](kubee-helmet-chart.md)

Example:
* Install the Traefik proxy
```bash
kubee --cluster "$KUBEE_CLUSTER_NAME" helmet play traefik
```
* Install `Cert Manager`
```bash
kubee --cluster "$KUBEE_CLUSTER_NAME" helmet play cert-manager
```

The whole list of available `kubee charts` can be seen in the [Kubee Charts directory](../../resources/charts/README.md).
