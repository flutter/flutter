About
=====

This is a prototype for plumbing Mojo into the NaCl sandbox.  It is
currently insecure (see below), does not provide a stable ABI (IRT
support must be added), and does not support Mojo functions that
return pointers (for example, `MojoMapBuffer`).


Using
=====

To use this prototype run `mojo/tools/mojob.py gn --nacl` and then build
and test as usual.

Run `mojo/tools/mojob.py nacltest` for additional nacl-specific tests.


Notes
=====

`generator/interface.py` contains a programmatic description of the
stable Mojo interface.  This will need to be updated as the interface
changes.  Run `generator/generate_nacl_bindings.py` to generate the
bindings that plumb this interface into the NaCl sandbox.


Security TODO
=============

* Separate trusted and untrusted Mojo handles.
* Validate and copy option structures.
* Protect untrusted buffers passed into Mojo:
  * `NaClVmIoWillStart/HasEnded`.
  * volatile accesses to untrusted memory (untrusted code could race).
* Overflow checking in array bounds validation.

