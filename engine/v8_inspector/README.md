v8_inspector
============

v8_inspector is an attempt to build a standalone library for running
a Chrome-DevTools compatible WebSocket server which speaks the "Debugger"
portion of the DevTools json protocol.

Currently v8_inspector is deeply tied into the rest of sky/engine/core,
however the goal is to remove that dependency by moving the files out of
sky/engine/core.


More Information
================

https://docs.google.com/document/d/1fEkZFMH_U5DhIYM95Mhp5ovtBUeHaToSvgQapDzgNDc/edit
http://crbug.com/435243