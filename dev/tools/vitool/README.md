# vitool

This tool generates Dart files from frames described in SVG files that follow
the small subset of SVG described below.
This tool was crafted specifically to handle the assets for certain Material
design animations as created by the Google Material Design team, and is not
intended to be a general-purpose tool.

## Supported SVG features
  - groups
  - group transforms
  - group opacities
  - paths (strokes are not supported, only fills, elliptical arc curve commands are not supported)
