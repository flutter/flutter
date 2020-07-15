This directory includes scripts to build the docker container image used for
building flutter/flutter in our CI system (currently [Cirrus](cirrus-ci.org)).

To run the scripts, you have to set up `docker` and `gcloud`. Please
refer to the [internal flutter team doc](go/flutter-team) for how to set up in a
Google internal environment.

After setup,
* edit `Dockerfile` to change how the container image is built.
* run `./docker_build.sh` to build the container image.
* run `./docker_push.sh` to push the image to google cloud registry. This will
  affect our CI tests.
