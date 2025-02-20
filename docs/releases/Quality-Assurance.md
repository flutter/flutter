With each beta we need to test that there are no regressions. We have lots of automated tests, but sometimes the thing that breaks is something we hadn't thought to test (or haven't figured out how to test) and so human testing is important!

## When to test betas

We announce betas on our Discord (see the [Chat](../contributing/Chat.md) page for the invite link), in the #releases channel, about once a month.

## How to get a beta build

When a beta build is announced, switch to the beta channel:

> `flutter channel beta && flutter upgrade`

If you get a `git` error, then you probably have a contributor checkout of Flutter. Use git instead:

> `git fetch upstream && git checkout upstream/beta`

Either way, check that everything is as you expect:

> `flutter --version`

It should specify the version number that you are testing.

## How to test a beta build

This is the easiest part: just use it! Test it on your projects, try running demos, try doing things you depend on normally.

Tell others who are testing the beta branch what you're doing in #quality-assurance on Discord!

In time, we will collect some specific things to try out here.