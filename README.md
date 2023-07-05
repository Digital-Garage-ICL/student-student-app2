
# wayfinder-app

This repository is a template for creating a new application repository for Wayfinder. It contains a workflow that will build and deploy a simple example application to a Kubernetes cluster managed by Wayfinder.

The contents of this repo needs to be tailored to suit your needs, e.g. the source folder needs to be replaced with your application code.

## Prerequisites

If you created this repo using a [create-wf-app workflow](https://github.com/Digital-Garage-ICL/create-wf-app/actions) for students, all pre-requesites should already be set up for you.

Here's a list of pre-requisites for this repository to work:

1. A Wayfinder instance. You will find the URL for the Wayfinder portal in the `Resources info` step of the [create-wf-app workflow](https://github.com/Digital-Garage-ICL/create-wf-app/actions) that you've run.

2. A Workspace created. You can also find the name of the Wayfinder workspace in the `Resources info` step of the create-wf-app workflow.

3. A Kubernetes cluster created and available to use in your workspace. A shared student cluster is available for you to use. The [AppEnv](./infra/appenv.yaml) resource points to it.

4. Permission on this repository to add secrets and trigger Github workflows. You should be owner of this repository if you created it using the create-wf-app workflow.

5. Wayfinder CLI. Read more [here](https://docs.appvia.io/wayfinder/getting-started/cli)

6. gh and jq installed. See more in comments section at the beginning of the [setup.sh](./setup.sh) script.

## Setup Repository
  
Before you start, you will need run the setup.sh script to setup the repo. This will create the required secrets and Variables for the workflow to work and set up access to the Wayfinder workspace for the CI pipeline.


 1. Clone the repository you've created using the create-wf-app workflow. You can find the URL in the `Resources info` step of the create-wf-app workflow.

 2. Open the terminal and navigate to the root of this repository then
    run the following command:

	```bash
	./setup.sh  ${WORKSPACE_NAME} ${GITHUB_PERSONAL_ACCESS_TOKEN}
	```
	
	Where:
	- `${WORKSPACE_NAME}` is the name of the Wayfinder workspace you've created using the create-wf-app workflow.
	- `${GITHUB_PERSONAL_ACCESS_TOKEN}` is a Github personal access token with `read:packages` scope. Make sure you create a `Classic` token. You can find more information about how to create a token [Managing your personal access tokens](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens#creating-a-personal-access-token-classic)

Once this is complete the script will generate the relevant secrets, and variables for the workflow to work. Now you can start configuring the repository for your application.

You should now re-run the `deployment` GitHub workflow that got triggered when you created this repository. This will deploy the application to the Kubernetes cluster. In your repo's UI on GitHub, go to Actions. You should see a workflow run with a name of "Initial commit" that has failed. Re-run it by clicking on the "Re-run all jobs" button.

The workflow initially failed because the CI token was not authorised to do the things it needs to do (creating an application, an environment and deploying an application to that environment). You created and authorised the token in the previous step (running `./setup.sh`). The workflow should now succeed.

## Creating your image
  
There is a CI workflow, which can take your Dockerfile and build an image for you. This is the recommended way to build your image.

 - You will need to adjust your Docker file for your pacific application.  
 - Then CI workflow will be triggered on a push to main branch.
 -  The image will be created in GitHub registry which can be located here

>   https://github.com/ImperialCollegeLondon/{REPO NAME}/pkgs/container/{REPO NAME}

## Deployment strategy

There are Two ways to the point using Wayfinder  

 1. Configure resources using the UI
 2. Configure resources using yaml

## Deployment using the UI

### Creating Application

In Wayfinder, **Applications** are a way to model the elements of your applications (containers, cloud resources, environments, etc) to simplify deployment and provisioning. Applications should consist of things that follow the same software lifecycle and would typically be deployed together, although individual components can be deployed separately.

 - Navigate to [wayfinder](https://portal-20-0-245-170.go.wayfinder.run/login?returnURL=/).
 - Then find your workspace and create a new application.
 - Once you created your application, you can add components.

	>   Components are individually deployable parts of your application and component can either be of type [**container**](https://docs.appvia.io/wayfinder/using/devex/application-components#container-components) or of type  [**cloud resource**](https://docs.appvia.io/wayfinder/using/devex/application-components#cloud-resource-components).

### **Container components**[​](https://docs.appvia.io/wayfinder/using/devex/application-components#container-components "Direct link to heading")

A container component requires an image and registry path to be specified when defined.

Container components are defined in Wayfinder's web interface by selecting  **Workspaces**, and then by clicking on the  **Step2: Define Components** button.

If you do not have an existing Kubernetes manifest then you can define one by specifying the following:

-   Container image
-   [Dependencies](https://docs.appvia.io/wayfinder/using/devex/application-components#dependencies)
-   [Environment variables](https://docs.appvia.io/wayfinder/using/devex/application-components#environment-variables)
-   [Endpoints](https://docs.appvia.io/wayfinder/using/devex/application-components#endpoints)


![enter image description here](https://docs.appvia.io/img/wayfinder/wf-self-service-container-component.png)


Now that you created the application, we need to set what environments this application will be deployed in.


### Environments

Environments map to namespaces in Kubernetes. Kubernetes namespaces provide a mechanism for isolating groups of resources within a single cluster. You can deploy your application into an environment which uses existing infrastucture.


Here are the steps to get set up.

 - Navigate to your application
 - Find the create button on the top right hand corner and select environment
 - A wizard with a pair, and you need to specify **Environment name** and then you will need to select an existing **Environment host** called aks-stdnt1
 - Then select create environment.

Now you have your application and environments ready, we're ready to deploy.


### Deploy 

We have a workflow set up called you ci.yaml which will be the workflow that you need to use.  This workflow is triggered on merge to the main branch.

You will need to comment out the job which you are not using for example, if you're using configured-with-ui  make sure the configured-with-ui job is not commented


 ## Configure resources using yaml 
 
### Creating Application

In Wayfinder, **Applications** are a way to model the elements of your applications (containers, cloud resources, environments, etc) to simplify deployment and provisioning. Applications should consist of things that follow the same software lifecycle and would typically be deployed together, although individual components can be deployed separately.

 - Create application.yaml and located in the infra/ folder. 

	```yaml
    apiVersion: app.appvia.io/v2beta1
    kind: Application
    metadata:
    	name: {{YOUR APPLICATION NAME}}
    spec:
	    cloud: azure
		name: {{YOUR APPLICATION NAME}}
	```
Once you created your application, you can add components.

### **Container components**[​](https://docs.appvia.io/wayfinder/using/devex/application-components#container-components "Direct link to heading")


  > Components are individually deployable parts of your application and component can either be of type [**container**](https://docs.appvia.io/wayfinder/using/devex/application-components#container-components) or of type  [**cloud resource**](https://docs.appvia.io/wayfinder/using/devex/application-components#cloud-resource-components).

A container component can take the following inputs

-   Container image
-   [Dependencies](https://docs.appvia.io/wayfinder/using/devex/application-components#dependencies)
-   [Environment variables](https://docs.appvia.io/wayfinder/using/devex/application-components#environment-variables)
-   [Endpoints](https://docs.appvia.io/wayfinder/using/devex/application-components#endpoints)

Please copy the below code and replace the the values with your application name 
 
```yaml
apiVersion: app.appvia.io/v2beta1
kind: Application
metadata:
	name: {{YOUR APPLICATION NAME}}
spec:
	cloud: azure
	name: {{YOUR APPLICATION NAME}}
	components:
		name: {{YOUR COMPONENT NAME}}
		type: Container
		- container:
			image: {{IMAGE PATH}}
			port: {{PORT NUMBER}}
			expose: {{true/false}}
			tls: {{true/false}}
```

Now that you created the application, we need to set what environments this application will be deployed in.


### Environments

Environments map to namespaces in Kubernetes. Kubernetes namespaces provide a mechanism for isolating groups of resources within a single cluster. You can deploy your application into an environment which uses existing infrastucture.


Here are the steps to get set up.

 - Create appenv.yaml and located in the infra/ folder. 
apiVersion: app.appvia.io/v2beta1

```yaml
kind: AppEnv
metadata:
	name:  {{Application name}}-{{environment name}}
spec:
	name:  {{environment name}}
	stage: nonprod
	application: {{Application name}}
	cloud: azure
	clusterRef:
		group: compute.appvia.io
		kind: Cluster
		name: aks-stdnt1
		version: v2beta1
```

Now you have your application and environments ready, we're ready to deploy.


### Deploy 

We have a workflow set up called you ci.yaml which will be the workflow that you need to use.  This workflow is triggered on merge to the main branch.

You will need to comment out the job which you are not using for example, if you're using configured-with-yaml make sure the configured-with-yaml job is not commented




