# IBM Client Developer Advocacy App Modernization Series
## Simple Hello World App to demo WebSphere Liberty deployed to Openshift using Tekton.

This fork is a demo for deploying a small Java EE app onto Openshift using Tekton, and originates from a finished solution to the lab [Build and run a WebSphere Liberty app with Docker](https://github.com/IBMAppModernization/app-modernization-liberty-on-docker).

Many of the Tekton and K8s resources included here originate from demos and tutorials developed by various IBM Garage organizations, specifically the [Garage Solution Engineering](https://ibm-cloud-architecture.github.io/) team and the [Cloud Pak Acceleration Team]().

The K8s manifests and the Tekton Tasks and Pipeline used in this demo were modified from the resources used in the ["Deploy using Tekton (OpenShift Pipelines) on OCP 4.3" demo](https://ibm-cloud-architecture.github.io/modernization-playbook/applications/liberty/liberty-deploy-tekton#deploy-using-tekton-(openshift-pipelines)-on-ocp-4.3) from GSE's Modernization Playbook.

The Tekton Trigger resources used here were based on the resources linked in the [IBM Garage Cloud Native Bootcamp's CI-CD lab](https://cloudnative101.dev/project-cicd/).

# Step-by-Step Guide to Deploying on Openshift

## Considerations and Prerequisites

Start by forking this repository to your preferred Git environment.

The Dockerfile included in the forked repository does **not** build the Java application. Instead, the Dockerfile uses the `.war` file already included in the `./target` directory.

Continuing from here, the guide will expect that you have the desired `.war` file in the `./target` directory of your forked repository. If you want to modify the application included here, you'll need to rebuild the WebSphere application and push your new `.war` to Git. Building the app from source (locally) requires:
- A Java 8 (or later) JDK
- [Maven 3.3 (or later)](https://maven.apache.org/download.cgi)

To build the app from source, run the following command from the top level folder of your cloned repo:

```
mvn clean package
```

This will create the app's *.war* file in the **target** subfolder.

*Future editions of this demo may be improved by including the build-step in the CI-CD pipeline.*

## Testing the App Locally

Refer to the [lab instructions](https://github.com/IBMAppModernization/app-modernization-liberty-on-docker) in the accompanying lab exercise to run the app on Docker.

## Set-Up Openshift Environment

In order to deploy and run the WebSphere Liberty Docker image in an OpenShift cluster, we first need to configure certain security aspects for the cluster. The Security Context Constraint provided here grants the service account that the WebSphere Liberty Docker container is running under the required privileges to function correctly.

A cluster administrator can use the file provided here with the following command to create the Security Context Constraint (SCC):

```
cd openshift
oc apply -f scc.yaml
```

Create the project that will be used for the Tekton pipeline and the initial deployment of the application.
Issue the command shown below to create the project:

```
oc new-project hello-liberty-tekton
```

It is a good Kubernetes practice to create a service account for your applications. A service account provides an identity for processes that run in a Pod. In this step we will create a new service account with the name websphere and add the Security Context Constraint created above to it.
Issue the commands shown below to create the websphere service account and bind the ibm-websphere-scc to it in each of the projects:

```
oc create serviceaccount websphere -n hello-liberty-tekton
oc adm policy add-scc-to-user ibm-websphere-scc -z websphere -n hello-liberty-tekton
```

## Update and Deploy Tekton Pipeline

Import the Tekton Tasks, Pipeline and PipelineResources in to the project using the commands shown below:

```
cd ../tekton/pipeline
oc apply -f build-deploy-pipeline.yaml
oc apply -f build-pipeline-resources.yaml
oc apply -f gse-apply-manifests-task.yaml
oc apply -f gse-buildah-task.yaml
```

## Run the Pipeline

The recommended way to trigger the pipeline would be via a webhook, which we will do later on in the guide. For simplicity the command line can be used now. Issue the command below to trigger the pipeline:

```
tkn pipeline start hello-liberty-build-deploy-pipeline -n hello-liberty-tekton
```

When prompted to choose the git resource, accept the default git-source value corresponding to your repository; do the same for your docker-image.

In order to track the PipelineRun progress, run the code outputted from the previous command. It will be something like this:

```
tkn pipelinerun logs hello-liberty-build-deploy-pipeline-run-<POD_HASH> -f -n hello-liberty-tekton
```

You can also inspect the PipelineRun within the OpenShift Container Platform UI. Change to the Developer view, select the `hello-liberty-tekton` project and then select Pipelines. Click on the Last Run entry -> Select "Logs".

Once both the gse-build and gse-apply-manifests steps are complete, the pipeline is finished.

## Test the Route

Now that the pipeline is complete, validate the Hello World application is deployed and running in `hello-liberty-tekton` project.

In the OpenShift Console, navigate to Topology view and click on the `hello-liberty` DeploymentConfig to view deployment details, including Pods, Service, and Route.

You can test that the application is serving by clicking the Route's URI and adding `/hello` to the end of the URL in the browser to access the application. Verify that "Hello World" is displayed.

## (Advanced) Set-Up Git Webhook via Tekton EventListener

This is only possible if your OpenShift cluster is accessible from your github server (ie. github.com).

For your CI pipeline to connect to and use your GitHub repo, it will need a GitHub personal access token with public_repo and write:repo_hook scopes.

Navigate to Developer Settings and generate a new token; name it something like “CI pipeline”.

Select `public_repo` scope to enable git clone, and `write:repo_hook` scope so the pipeline can create a web hook.

The GitHub UI will never again let you see this token, so be sure to save the token in your password manager or somewhere safe that you can access later on.

Create the shell variables below, replacing <GIT_USERNAME> and <GIT_TOKEN> and keeping the quotes:

```
export GIT_USERNAME='<GIT_USERNAME>'
export GIT_TOKEN='<GIT_TOKEN>'
```

Create and expose the Tekton EventListener:

```
cd ..
oc apply -f triggers/ -n $NAMESPACE
oc create route edge --service=el-hello-liberty-cicd -n hello-liberty-tekton
export GIT_WEBHOOK_URL=$(oc get route el-hello-liberty-cicd -o jsonpath='{.spec.host}' -n hello-liberty-tekton)
echo "https://$GIT_WEBHOOK_URL"
```

Set the GIT_REPO_NAME to name of your Git repo, like liberty-hello-world-app:

```
export GIT_REPO_NAME='<GIT_REPO_NAME>'
```

Set the GIT_REPO_OWNER to name of the Git repo's owner like josephdibartolo

```
export GIT_REPO_OWNER='<GIT_REPO_OWNER>'
```

Run curl to create the web hook:

```
curl -v -X POST -u $GIT_USERNAME:$GIT_TOKEN \
-d "{\"name\": \"web\",\"active\": true,\"events\": [\"push\"],\"config\": {\"url\": \"https://$GIT_WEBHOOK_URL\",\"content_type\": \"json\",\"insecure_ssl\": \"0\"}}" \
-L https://api.github.com/repos/$GIT_REPO_OWNER/$GIT_REPO_NAME/hooks
```