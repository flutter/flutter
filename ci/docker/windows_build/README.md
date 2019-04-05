This directory should include scripts to build the docker container image used
for building flutter/engine in our CI system (currently [Cirrus](cirrus-ci.org))
using Windows.

So far we're still waiting GKE to have Kubernetes 1.14 and Windows containers.

Before that, we use GCE Windows VMs for our CI tests. This directory includes
scripts for preparing that VM.
