This directory includes scripts and tools for setting up Flutter's continuous
integration environments.

## Cirrus Linux

Flutter's Linux tasks run on a custom Docker image. The `Dockerfile` for this
image can be found at [/dev/ci/docker_linux/Dockerfile](https://github.com/flutter/flutter/blob/master/dev/ci/docker_linux/Dockerfile).
On each new change to this `Dockerfile`, Cirrus will build a new version of
the Docker image as a dependency to any Linux tests. It is no longer necessary
to manually build and push the Docker image locally.

There are some factors external to the actual `Dockerfile` that would
necessitate rebuilding the Docker image, such as upstream code changes, (Linux
distribution) repository updates or a file that gets `COPY`ied into the image
changing. In this case, a trivial `Dockerfile` change (such as a comment)
would invalidate the cache and trigger a rebuild.
