The Sky Environment
===================

The main files loaded by the Sky environment are Sky files, though
they can refer to binary resources like images and fonts.

Sky files
---------

Conventional MIME type: ``text/sky``, though this type is neither
necessary nor sufficient to indicate that a file is a Sky file; only
the signature matters for type dispatch of Sky files.

Conventional extension: ``.sky``

Signatures:

For application files, one of the following:
* ``23 21 6d 6f 6a 6f 20 6d 6f 6a 6f 3a 73 6b 79 0a`` ("``#!mojo mojo:sky\n``")
* ``23 21 6d 6f 6a 6f 20 6d 6f 6a 6f 3a 73 6b 79 0d`` ("``#!mojo mojo:sky\r``")
* ``23 21 6d 6f 6a 6f 20 6d 6f 6a 6f 3a 73 6b 79 20`` ("``#!mojo mojo:sky ``")

For module files, one of the following:
* ``53 4b 59 20 4d 4f 44 55 4c 45 0a`` ("``SKY MODULE\n``")
* ``53 4b 59 20 4d 4f 44 55 4c 45 0d`` ("``SKY MODULE\r``")
* ``53 4b 59 20 4d 4f 44 55 4c 45 20`` ("``SKY MODULE ``")


Notes
-----

```
magical imports:
  the core mojo fabric JS API   sky:mojo:fabric:core
  the asyncWait/cancelWait mojo fabric JS API (interface to IPC thread)  sky:mojo:fabric:ipc
  the mojom for the shell, proxying through C++ so that the shell pipe isn't exposed  sky:mojo:shell
  the sky API  sky:core
  the sky debug symbols for private APIs  sky:debug
```
