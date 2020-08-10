# aks-privatelink-demo

## Intro

One of the concerns when linking Networks together is the depletion of available IP-addresses.
This is especially the case if you are using Azure Kubernetes Services with CNI as network architecture; with CNI every pod on the AKS cluster gets it's own IP address.
Azure Private Link and Azure Private Endpoint can link your available Kubernetes services over different networks without VNET peering. 
This makes it possible to use different VNETs everytime you roll out an AKS cluster. Now you do not have to worry about overlapping IP addresses or depletion of available IP adresses.

![Image of APIM solution](https://raw.githubusercontent.com/chrisvugrinec/aks-privatelink-demo/master/images/aks_privatelink.png)

This cookbook rolls out an AKS cluster and deploys 2 services. Making the services available on a management hub via an Azure Private Endpoint and using an Azure Private DNS zone entry per service.

## Cookbook

### Create Infra


- get sources; ```git clone https://github.com/chrisvugrinec/aks-privatelink-demo.git```
- prepare Azure storage (for terraform state); ```cd infra``` change the variables in the ```1_setupTFStorage.sh``` script.
- create the storage: ```./1_setupTFStorage.sh*```
- set the ARM_ACCESS_KEY variable; ```export ARM_ACCESS_KEY= [ the storage key found in the previous step] ```
- setup tier 2, the network structure; ```cd tier_2``` change the variables.tf, naming and storage account settings
- rollout the network structure; ```terraform init; terraform plan; terraform apply```
- setup tier 3, AKS; ```cd tier_3``` change the variables.tf, naming and storage account settings
- rollout the demo app structure; ```terraform init; terraform plan; terraform apply```


#### Setup ingress/ services, private link and DNS

-  ```cd tier_post_aks/```
- ```./create.sh AKS_CLUSTER AKS_RG```

After completion of the script, rollout the remaining terraform plan:

```
terraform plan plan.out

```

This script does the following:

- getKubeCredentials; you need kubectl access to your kubernetes cluster
- assignContribRoleToManagedIdentity; assign the contributor role on the subnet for your AKS APP ID
- installIngress; installs the NGINX  ingress controller on AKS using an Azure Internal Loadbalancer
- installServices; installs the hello and poker service and configures ingress entry points as well
- createPrivateLink; creates the Private link to the Internal Loadbalancer(nginx ingress) and create a private endpoint on the mgmt vnet that links to the private service link
  
#### Test accessing your services

Create a vm on your Management Vnet and try to access the following services:

Sayhello service:

```
 curl -d '{"name":"freddy krueger"}' -H "Content-Type: application/json" -X POST http://hello.apimdemo.service.local/sayhello
```

Poker service:

```
curl  -H "Content-Type: application/json"  http://poker.apimdemo.service.local/pokerhost/v1/testdeal?nrOfPlayers=2
```

## Links

- Private Link documentation; https://docs.microsoft.com/en-us/azure/private-link/