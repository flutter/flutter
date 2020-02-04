#!/bin/bash

set -e

if [[ -z $OPEN_JDK_URL ]]; then
  exit 0
fi

mkdir -p $HOME/Java
pushd $HOME/Java
curl -L $OPEN_JDK_URL --output open_jdk.tar.gz
tar -xvf open_jdk.tar.gz
rm open_jdk.tar.gz
popd
