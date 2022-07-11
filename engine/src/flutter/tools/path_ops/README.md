# path_ops

A small library that exposes C bindings for Skia's SkPathOps, with a minimal
interface for SkPath.

This library only supports four commands from SkPath: `moveTo`, `lineTo`,
`cubicTo`, and `close`.

This library is a subset of the functionality provided by Skia's `PathKit`
library. It is primarily intended for use with the `vector_graphics` optimizing
compiler. That library uses this one to optimize certain masking and clipping
operations at compile time.
