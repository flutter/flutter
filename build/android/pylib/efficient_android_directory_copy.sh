#!/system/bin/sh

# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Android shell script to make the destination directory identical with the
# source directory, without doing unnecessary copies. This assumes that the
# the destination directory was originally a copy of the source directory, and
# has since been modified.

source=$1
dest=$2
echo copying $source to $dest

delete_extra() {
  # Don't delete symbolic links, since doing so deletes the vital lib link.
  if [ ! -L "$1" ]
  then
    if [ ! -e "$source/$1" ]
    then
      echo rm -rf "$dest/$1"
      rm -rf "$dest/$1"
    elif [ -d "$1" ]
    then
      for f in "$1"/*
      do
       delete_extra "$f"
      done
    fi
  fi
}

copy_if_older() {
  if [ -d "$1" ] && [ -e "$dest/$1" ]
  then
    if [ ! -e "$dest/$1" ]
    then
      echo cp -a "$1" "$dest/$1"
      cp -a "$1" "$dest/$1"
    else
      for f in "$1"/*
      do
        copy_if_older "$f"
      done
    fi
  elif [ ! -e "$dest/$1" ] || [ "$1" -ot "$dest/$1" ] || [ "$1" -nt "$dest/$1" ]
  then
    # dates are different, so either the destination of the source has changed.
    echo cp -a "$1" "$dest/$1"
    cp -a "$1" "$dest/$1"
  fi
}

if [ -e "$dest" ]
then
  echo cd "$dest"
  cd "$dest"
  for f in ./*
  do
    if [ -e "$f" ]
    then
      delete_extra "$f"
    fi
  done
else
  echo mkdir "$dest"
  mkdir "$dest"
fi
echo cd "$source"
cd "$source"
for f in ./*
do
  if [ -e "$f" ]
  then
    copy_if_older "$f"
  fi
done
