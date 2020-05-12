# IBM Client Developer Advocacy App Modernization Series

## Simple Hello World app to demo  WebSphere Liberty in Docker

This fork is a demo for deploying a small Java EE app onto Openshift using Tekton, and originates from a finished solution to the lab [Build and run a WebSphere Liberty app with Docker](https://github.com/IBMAppModernization/app-modernization-liberty-on-docker).


### Building the app

You'll need the following to build the app from source:
- A Java 8 (or later) JDK
- [Maven 3.3 (or later)](https://maven.apache.org/download.cgi)

To build the app from source  run the following command from the top level folder of a clone of this repo :
    ```
    mvn clean package
    ```

This will create the app's *.war* file in the **target** subfolder.

### Running the app

#### Docker

Refer to the [lab instructions](https://github.com/IBMAppModernization/app-modernization-liberty-on-docker) in the accompanying lab exercise to run the app on Docker.

#### Openshift Pipelines (aka Tekton)

We use the Tekton resources defined in `./pipeline` to create the pipeline [components] needed to deploy this app. The image-build phase is dependent on this repo, and uses the Dockerfile included in the repo to build the image using `Buildah`.

Instantiate the PipelineRun in Openshift's GUI to run.

### Considerations and Improvements

- Make the Dockerfile build the code instead of simply coping the pre-built `.war` into the image.
- Fix the Route definition to make the TLS service's endpoint work.
