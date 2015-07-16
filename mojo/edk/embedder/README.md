Mojo Embedder API
=================

The Mojo Embedder API is an unstable, internal API to the Mojo system
implementation. It should be used by code running on top of the system-level
APIs to set up the Mojo environment (instead of directly instantiating things
from src/mojo/edk/system).

Example uses: Mojo shell, to set up the Mojo environment for Mojo apps; Chromium
code, to set up the Mojo IPC system for use between processes. Note that most
code should use the Mojo Public API (under src/mojo/public) instead. The
Embedder API should only be used to initialize the environment, set up the
initial MessagePipe between two processes, etc.
