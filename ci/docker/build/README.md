This directory includes scripts to build the docker container image used for
building flutter/engine in our CI system (currently [Cirrus](cirrus-ci.org)).

In order to run the scripts, you have to setup `docker` and `gcloud`. Please
refer to internal doc go/installdocker for how to setup `docker` on gLinux.

Cirrus will build (and cache) a Docker image based on this `Dockerfile` for
Linux tasks using its
[Dockerfile as CI](https://cirrus-ci.org/guide/docker-builder-vm/) feature.
Any change to the `Dockerfile` will cause a new task to be triggered to build
and tag a new version of the Docker image which will be a dependency of the
other Linux tasks. This task will instantiate a new GCP VM based on the image
specified in the `.cirrus.yml` `builder_image_name` field.

To test changes to the Linux `Dockerfile`, create a PR with the changes, and
Cirrus will attempt to build a new image.

To debug locally, you can build an image with `./build_docker.sh`, but pushing
to the registry is no longer necessary.
