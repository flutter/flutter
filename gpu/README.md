This directory exists solely to hold shims for compatibility with the Chromium 
reposository of Khronos headers. That repo is significantly easier to use than
the upstream verions, since:
- The upstream headers are spread over two repositories.
- The upstream repositories are large, due to files that aren't
  relevant for building (see
  https://github.com/KhronosGroup/OpenGL-Registry#there-sure-is-a-lot-of-stuff-in-here).
- The Chromium version already has a BUILD.gn file.

However, it contains slight forking to add Chromium-specific headers, so this
folder provides dummy versions of those headers.
