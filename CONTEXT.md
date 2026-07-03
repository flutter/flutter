# Flutter Tooling Extensibility (GEP) Context

Canonical terminology and domain concepts for the Generic Extension Protocol (GEP) within Flutter tools.

## Language

**Extension Build Environment Forwarding**:
The process by which dynamic extension build subcommands collect standard CLI build options (`--debug`, `--profile`, `--release`, `-t/--target`, `-o/--output`, `--dart-define`) and forward them into `BuildEnvironment.defines` alongside target platform and build mode before delegating compilation over GEP RPC (`build.build`).
_Avoid_: Dynamic extension CLI flag parsing, arbitrary flag injection.
