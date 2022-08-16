#!/bin/sh
echo "Importing a claimed cluster"

# requires cluster claim name to find the namespace containing kubeconfig secret for imports
if [ -z "${CLUSTER_CLAIM_NAME}" ]; then
    echo "Please provide CLUSTER_CLAIM_NAME as an environment variable"
    exit
fi
# For OTP, this is default to `rhacm-clusterpools`
if [ -z "${CLUSTER_CLAIM_NAMESPACE}" ]; then
    echo "Please provide CLUSTER_CLAIM_NAMESPACE as an environment variable"
    exit
fi
if [ -z "${MANAGED_CLUSTER_SET}" ]; then
    echo "Please provide MANAGED_CLUSTER_SET as an environment variable, if none, use `default`"
    exit
fi


# https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.5/html/clusters/managing-your-clusters#cli-prerequisites
echo "Preparing cluster for imports"
echo "-- Get claimed cluster name"
export CLUSTER_NAME="$(oc get clusterclaims.hive.openshift.io/$CLUSTER_CLAIM_NAME -o=jsonpath='{.spec.namespace}' -n $CLUSTER_CLAIM_NAMESPACE)"
oc label namespace ${CLUSTER_NAME} cluster.open-cluster-management.io/managedCluster=${CLUSTER_NAME} --overwrite=true
echo "-- Create a new managed cluster CR"
echo "-- Get the managed cluster set for cluster pool (if applicable)"
export CLUSTER_POOL_NAME="$(oc get clusterclaims.hive.openshift.io/$CLUSTER_CLAIM_NAME -o=jsonpath='{.spec.clusterPoolName}' -n $CLUSTER_CLAIM_NAMESPACE)"
envsubst < ./managed-cluster.yaml | oc apply -f -

echo "Importing the cluster with the auto import secret"
export KUBECONFIG_B64=$(oc get secret -n ${CLUSTER_NAME} -l hive.openshift.io/secret-type=kubeconfig -o=jsonpath='{.items[0].data.kubeconfig}')
envsubst < ./auto-import-secret.yaml | oc apply -f -

until oc get managedcluster ${CLUSTER_NAME} -o=jsonpath='{.status.conditions[*].type}' | grep ManagedClusterJoined | grep ManagedClusterConditionAvailable
do
  echo "Waiting for cluster to have conditions: ManagedClusterJoined and ManagedClusterConditionAvailable"
  sleep 1
done
echo "Cluster ${CLUSTER_NAME} imported."