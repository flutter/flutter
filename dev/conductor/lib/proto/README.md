## Flutter Conductor Protocol Buffers

This directory contains [conductor_state.proto](./conductor_state.proto), which
defines the persistent state file the conductor creates. After changes to this
file, you must run the [compile_proto.sh](./compile_proto.sh) script in this
directory, which will re-generate the rest of the Dart files in this directory,
format them, and prepend the license comment from
[license_header.txt](./license_header.txt).
