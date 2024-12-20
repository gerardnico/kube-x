% kube-x-config(1) Version Latest | kube-x-config
# kube-x-config.sh documentation

Return a `KUBECONFIG` file

## DESCRIPTION

If the `KUBECONFIG` env is not set, `kube-x` will generate it dynamically.

## How

It retrieves:
* the `cluster` data from the `pass` secret manager.
* the `user` data from the `pass` secret manager.
* the `namespace` from the env

It's a `zero-trust` connection tool.

## ENV

* `KUBE_X_CLUSTER`: The cluster to connect (default to `default`)
* `KUBE_X_USER`: The user to connect with (default to `default`)
* `KUBE_X_PASS_HOME`: The directory where to store `kube-x` pass information (default to `kube-x`)
* `KUBE_X_CONNECTION_NAMESPACE`: the connection namespace (default to the app namespace or to the KUBE_X_DEFAULT_NAMESPACE)

## How to create the secrets in path

```bash
# Set the config where to extract the information
export KUBECONFIG="$HOME/.kube/config"
# The pass home directory (default to kube-x)
export KUBE_X_PASS_HOME="kube-x"

# Get the cluster and user name from the KUBECONFIG
# or set your own
KUBE_X_CLUSTER=$(kubectl config view --minify --raw --output 'jsonpath={$.clusters[0].name}')
KUBE_X_USER=$(kubectl config view --minify --raw --output 'jsonpath={$.users[0].name}')

# Store the user and cluster properties in path
kubectl config view --minify --raw --output 'jsonpath={$.users[0].client-certificate-data}' | pass insert -m "$KUBE_X_PASS_HOME/users/$KUBE_X_USER/client-certificate-data"
kubectl config view --minify --raw --output 'jsonpath={$.users[0].client-key-data}' | pass insert -m "$KUBE_X_PASS_HOME/users/$KUBE_X_USER/client-key-data"
kubectl config view --minify --raw --output 'jsonpath={$.clusters[0].certificate-authority-data}' | pass insert -m "$KUBE_X_PASS_HOME/clusters/$KUBE_X_CLUSTER/certificate-authority-data"
kubectl config view --minify --raw --output 'jsonpath={$.clusters[0].server}' | pass insert -m "$KUBE_X_PASS_HOME/clusters/$KUBE_X_CLUSTER/server"
```


