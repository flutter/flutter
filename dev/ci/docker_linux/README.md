This directory includes scripts to build the docker container image used for
building flutter/flutter in our CI system (currently [Cirrus](cirrus-ci.org)).

In order to run the scripts, you have to setup `docker` and `gcloud`. Please
refer to the [internal flutter team doc](go/flutter-team) for how to setup in a
Google internal environment.

After setup,
* edit `Dockerfile` to change how the container image is built.
* run `./build_docker.sh` to build the container image.
* run `./push_docker.sh` to push the image to google cloud registry. This will
  affect our CI tests.

