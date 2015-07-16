#! /bin/sh -e

# This script downgrades MSVC 2008 projects to MSVC 2005 projects, allowing
# people with MSVC 2005 to open them.  Otherwise, MSVC 2005 simply refuses to
# open projects created with 2008.  We run this as part of our release process.
# If you obtained the code direct from version control and you want to use
# MSVC 2005, you may have to run this manually.  (Hint:  Use Cygwin or MSYS.)

for file in *.sln; do
  echo "downgrading $file..."
  sed -i -re 's/Format Version 10.00/Format Version 9.00/g;
              s/Visual Studio 2008/Visual Studio 2005/g;' $file
done

for file in *.vcproj; do
  echo "downgrading $file..."
  sed -i -re 's/Version="9.00"/Version="8.00"/g;' $file
done

# Yes, really, that's it.
