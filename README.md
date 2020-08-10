# aks-privatelink-demo

## Intro

One of the concerns when linking Networks together is the depletion of available IP-addresses.
This is especially the case if you are using Azure Kubernetes Services with CNI as network architecture; with CNI every pod on the AKS cluster gets it's own IP address.
Azure Private Link and Azure Private Endpoint can link your available Kubernetes services over different networks without VNET peering. 
This makes it possible to use different VNETs everytime you roll out an AKS cluster. Now you do not have to worry about overlapping IP addresses or depletion of available IP adresses.

![Image of APIM solution](https://raw.githubusercontent.com/chrisvugrinec/aks-privatelink-demo/master/images/aks_privatelink.png)

## Cookbook

### Create Infra

For this demo you will need the following Azure Infra components: AKS cluster, APIM and a Private DNS zone. This demo uses a tiered setup into 2 layers. Terraform is used for the rollout and the State is stored on Azure Blob storage.

- get sources; ```git clone https://github.com/chrisvugrinec/apim-demo.git```
- prepare Azure storage (for terraform state); ```cd infra``` change the variables in the ```1_setupTFStorage.sh``` script.
- create the storage: ```./1_setupTFStorage.sh*```
- set the ARM_ACCESS_KEY variable; ```export ARM_ACCESS_KEY= [ the storage key found in the previous step] ```
- setup tier 2, the network structure; ```cd tier_2``` change the variables.tf, naming and storage account settings
- rollout the network structure; ```terraform init; terraform plan; terraform apply```
- setup tier 3, AKS; ```cd tier_3``` change the variables.tf, naming and storage account settings
- rollout the demo app structure; ```terraform init; terraform plan; terraform apply```

#### Setup HELM

Sometimes an old version of HELM is required, this demo is using version 2.13, tiller downloaded from the helm.sh site
- ```cd helm/darwin-amd64```
- ```./installTiller.sh AKS_CLUSTER AKS_RG```

This will get the credentials for your AKS cluster and initialise tiller on your AKS cluster.

#### Setup ingress controller

-  ```cd ingress/```
- ```./createIngress.sh AKS_CLUSTER AKS_RG```

This will give your managed identity of your AKS cluster the rights to create resources on the AKS subnet.
Next to this it will create an Nginx Ingress controller linked to an Internal Azure LoadBalancer.
Please note thate the current Internal loadbalancer is based on the following configured IP address:   
```
  loadBalancerIP: 15.1.2.100
```
If you like to change this, make sure that it is in the range of your configured AKS subnet. You can change the ip of the ingress loadbalancer by editing this file: ```ingress/nginx/service/loadbalancer.yaml```

### Deploy service

Deploy the sayHello service
- ```cd services/hello-python-service/helm```
- ```../../../helm/darwin-amd64/helm install -n sayhello sayhello/```

Deploy the poker service
- ```cd services/poker-springboot-service/helm```
- ```../../../helm/darwin-amd64/helm install -n poker-deal-test pokerservice/```

After this deployments you should be able to:
- check helm deployments; helm ls
- check if the pods are running; kubectl get pods 
- check if services are available: kubectl get svc
- check if ingresses are configured; kubectl get ing

### Config APIM

#### Setup services

In your Azure Poral go to the APIM and select the API tab:

![Config APIM service](https://raw.githubusercontent.com/chrisvugrinec/apim-demo/master/images/apim1.png)

Select the OpenAPI option and use the wizzard to configure the services. 
In the services folder you can find the api spec (swagger extraction):
```
services/hello-python-service/api.json
services/poker-springboot-service/api.json
```
In the `API URL suffix` you fill in the path you like your service to be accessible from the APIM.

Your service is now visible within the API portal, select your service and then select the `Design` tab. Within the design tab, select the policy for Inbound processing:

![Config APIM service](https://raw.githubusercontent.com/chrisvugrinec/apim-demo/master/images/apim3.png)

In this policy you should forward your backend request to the AKS backend service, by adding this code:
```
<policies>
...
    <backend>
        <forward-request />
    </backend>
...
</policies>
```

Please note that you can configure this policy on Operation level or more globally on API level. If you do not configure this, you backend service will never be reached, also have a look at the caching possibilities.
Of course you can configure other policies as well, for more information please read the [APIM documentation](https://docs.microsoft.com/en-us/azure/api-management/).

In the `Settings` tab you need to configure the URL of your backend service. If you used the scripts in this repo you should have 2 domains configured:

```
hello.apimdemo.service.local
poker.apimdemo.service.local
```

Both services are pointing to the internal loadbalancer, which is pre configured on this address: `15.1.2.100`. This address is used by the nginx ingress controller, which will make sure that you address the appropriate services which are deployed on the AKS cluster.

For the hello service you enter: `http://hello.apimdemo.service.local` in the `Web service URL` field. Make sure you select `HTTP`.

For the poker service your config should look like this:

![Config APIM service](https://raw.githubusercontent.com/chrisvugrinec/apim-demo/master/images/apim5.png)

If you have configured your `<forward-request />` and the proper `Web service URL` you should be able to test your service through the portal. Ps If testing using an external tool like *Postman* make sure you post the required headers as well, for eg `Ocp-Apim-Subscription-Key` with the key for the defined APIM product.

#### Configure Authentication

There are multiple ways to enforce authentication on your services using APIM. 
We will use AUTH0 as Secure Token Service (STS), please create an account (it's free) at https://auth0.com/
Of course you can also use Azure Active Directory or other 3rd party Authentication providers.

Once you have signed up, you will have an instance which can provide a token service for you. Take the following steps:

- Create an [API](https://raw.githubusercontent.com/chrisvugrinec/apim-demo/master/images/auth0-1.png)
- Configure [API](https://raw.githubusercontent.com/chrisvugrinec/apim-demo/master/images/auth0-2.png) , fill in the name and identifier and select `HS256` as Signing algorithm, this will create an API and a AUTH0 application as well
- Create a [scope](https://raw.githubusercontent.com/chrisvugrinec/apim-demo/master/images/auth0-3.png), by selecting the `Permissions` TAB for the API, this can be any value, for eg: `use.svc`
- Assign the permissions to the scope you just created; go to the `Machine to Machine Applications` tab, select the service and then check the [tickbox](https://raw.githubusercontent.com/chrisvugrinec/apim-demo/master/images/auth0-4.png)

That's it (one of the reasons I love auth0)! Now we need to configure the policy for the service so that it enforces Authentication using this STS. Go back to the inbound [Policy configuration](https://raw.githubusercontent.com/chrisvugrinec/apim-demo/master/images/apim3.png). And add the following code in the `<inbound>` tag:

```
<inbound>
...
        <validate-jwt header-name="Authorization" failed-validation-error-message="Unauthorized....." require-scheme="Bearer">
            <openid-config url="https://XXX_YOURDOMAIN_XXX/.well-known/openid-configuration" />
            <issuer-signing-keys>
                <key>XXX_SIGNING_KEY_XXX</key>
            </issuer-signing-keys>
            <audiences>
                <audience>XXX_AUDIENCE_XXX</audience>
            </audiences>
            <issuers>
                <issuer>XXX_YOURDOMAIN_XXX</issuer>
            </issuers>
            <required-claims>
                <claim name="scope" match="any" separator=" ">
                    <value>XXX_SCOPE_XXX</value>
                </claim>
            </required-claims>
        </validate-jwt>
</inbound>
```

You can find the data for the ```XXX``` values here:

- XXX_YOURDOMAIN_XXX; go to the [Test tab](https://raw.githubusercontent.com/chrisvugrinec/apim-demo/master/images/auth0-5.png)
- XXX_SIGNING_KEY_XXX; you can find the Signing key in the  `Settings` tab, you need to scroll down a bit. *ATTENTION*  you need to base64 encode this value before you put it in the policy. You can use https://www.base64encode.org/ for encrypting your key.
- XXX_AUDIENCE_XXX; This is the `Identifier` value in the `Settings` tab
- XXX_SCOPE_XXX; This is the name of the scope you have defined.

Now you are done, let's test this using postman.

#### Test Authentication

Create a service for getting your Authorization token from AUTH0:

![Postman 1](https://raw.githubusercontent.com/chrisvugrinec/apim-demo/master/images/postman1.png)

You should get an Access token, but also make sure that AUTH0 returns a `scope`.
You can copy the token from the previous service and configure the APIM service like this:

![Postman 2](https://raw.githubusercontent.com/chrisvugrinec/apim-demo/master/images/postman-3.png)

Select `Baerer Token` in the `Authorization` tag and paste the token there,
the body of the `hello` service looks like this:

```
  {
    "name": "the dude"
  }
```

Select send to see if it works, if you fill in an faulty token (or no value at all) you will get and `Unauthorized` message.

## Links

- APIM documentation; https://docs.microsoft.com/en-us/azure/api-management/
- APIM AAD authentication; https://docs.microsoft.com/en-us/azure/api-management/api-management-howto-protect-backend-with-aad
- oauth2; https://auth0.com/docs/integrations/azure-api-management
