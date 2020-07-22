This directory includes scripts to build the docker container image used for
building flutter/flutter in our CI system (currently [Cirrus](cirrus-ci.org)).

In order to run the scripts, you have to setup `docker` and `gcloud`. Please
refer to the [internal flutter team doc](go/flutter-team) for how to setup in a
Google internal environment.

To debug the image locally:
* (Optional) edit the `Dockerfile` to change how the container image is built.
* Run `./docker_build.sh` to build the container image (`sudo` permission is
  required)
* Run `./docker_attach.sh` to start a container from the image and attach to its
  internal bash shell. From here, you can invoke shell commands from the
  `.cirrus.yml` (you will have to manually run any `setup` steps; e.g. the
  container will not have the Flutter repo cloned yet).
