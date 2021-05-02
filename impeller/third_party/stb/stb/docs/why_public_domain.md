My collected rationales for placing these libraries
in the public domain:

1. Public domain vs. viral licenses

  Why is this library public domain?
  Because more people will use it. Because it's not viral, people are
  not obligated to give back, so you could argue that it hurts the
  development of it, and then because it doesn't develop as well it's
  not as good, and then because it's not as good, in the long run
  maybe fewer people will use it. I have total respect for that
  opinion, but I just don't believe it myself for most software.

2. Public domain vs. attribution-required licenses

  The primary difference between public domain and, say, a Creative Commons
  commercial / non-share-alike / attribution license is solely the
  requirement for attribution. (Similarly the BSD license and such.)
  While I would *appreciate* acknowledgement and attribution, I believe
  that it is foolish to place a legal encumberment (i.e. a license) on
  the software *solely* to get attribution.

  In other words, I'm arguing that PD is superior to the BSD license and
  the Creative Commons 'Attribution' license. If the license offers
  anything besides attribution -- as does, e.g., CC NonCommercial-ShareAlike,
  or the GPL -- that's a separate discussion.

3. Other aspects of BSD-style licenses besides attribution

  Permissive licenses like zlib and BSD license are perfectly reasonable
  in their requirements, but they are very wordy and
  have only two benefits over public domain: legally-mandated
  attribution and liability-control. I do not believe these
  are worth the excessive verbosity and user-unfriendliness
  these licenses induce, especially in the single-file
  case where those licenses tend to be at the top of
  the file, the first thing you see.

  To the specific points, I have had no trouble receiving
  attribution for my libraries; liability in the face of
  no explicit disclaimer of liability is an open question,
  but one I have a lot of difficulty imagining there being
  any actual doubt about in court. Sometimes I explicitly
  note in my libraries that I make no guarantees about them
  being fit for purpose, but it's pretty absurd to do this;
  as a whole, it comes across as "here is a library to decode
  vorbis audio files, but it may not actually work and if
  you have problems it's not my fault, but also please
  report bugs so I can fix them"--so dumb!

4. full discussion from stb_howto.txt on what YOU should do for YOUR libs

```
EASY-TO-COMPLY LICENSE

I make my libraries public domain. You don't have to.
But my goal in releasing stb-style libraries is to
reduce friction for potential users as much as
possible. That means:

  a. easy to build (what this file is mostly about)
  b. easy to invoke (which requires good API design)
  c. easy to deploy (which is about licensing)

I choose to place all my libraries in the public
domain, abjuring copyright, rather than license
the libraries. This has some benefits and some
drawbacks.

Any license which is "viral" to modifications
causes worries for lawyers, even if their programmers
aren't modifying it.

Any license which requires crediting in documentation
adds friction which can add up. Valve used to have
a page with a list of all of these on their web site,
and it was insane, and obviously nobody ever looked
at it so why would you care whether your credit appeared
there?

Permissive licenses like zlib and BSD license are
perfectly reasonable, but they are very wordy and
have only two benefits over public domain: legally-mandated
attribution and liability-control. I do not believe these
are worth the excessive verbosity and user-unfriendliness
these licenses induce, especially in the single-file
case where those licenses tend to be at the top of
the file, the first thing you see. (To the specific
points, I have had no trouble receiving attribution
for my libraries; liability in the face of no explicit
disclaimer of liability is an open question.)

However, public domain has frictions of its own, because
public domain declarations aren't necessary recognized
in the USA and some other locations. For that reason,
I recommend a declaration along these lines:

// This software is dual-licensed to the public domain and under the following
// license: you are granted a perpetual, irrevocable license to copy, modify,
// publish, and distribute this file as you see fit.

I typically place this declaration at the end of the initial
comment block of the file and just say 'public domain'
at the top.

I have had people say they couldn't use one of my
libraries because it was only "public domain" and didn't
have the additional fallback clause, who asked if
I could dual-license it under a traditional license.

My answer: they can create a derivative work by
modifying one character, and then license that however
they like. (Indeed, *adding* the zlib or BSD license
would be such a modification!) Unfortunately, their
lawyers reportedly didn't like that answer. :(
```
