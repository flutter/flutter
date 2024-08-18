Flutter repositories require that your commits are signed (as of Nov 17, 2021, this is not enabled in all repos, but it's best to be prepared). To get started follow the GitHub instructions in [Signing Commits][1].

## Troubleshooting

### `GIT_TRACE=1`

If a `git` command fails with a complaint about `gpg`, run the same command again with `GIT_TRACE=1`. For example, if the failing command is:

```
git commit -S -m 'some message'
```

Run this instead:

```
GIT_TRACE=1 git commit -S -m 'some message'
```

With tracing enabled `git` will provide more information about the failure.

### fatal: failed to write commit object

If you see the following output from `git commit -S`:

```
error: gpg failed to sign the data
fatal: failed to write commit object
```

This error may indicate that your GPG name, comment, and email do not match those of `git`. To fix this issue, add `user.signingkey` to your git configuration referring to the GPG key by its hash rather than by name. To find out the GPG key hash run:

```
gpg --list-secret-keys --keyid-format=long
```

In the list of keys printed to the console find the one you want to use (the one you registered with GitHub) and copy its hash from the line that begins with `sec`. For example, the key hash in the following line is `XYZ`:

```
sec   rsa4096/XYZ 20201-11-16
```

To add it to your git configuration run:

```
git config --global user.signingkey XYZ
```

[1]: https://docs.github.com/en/authentication/managing-commit-signature-verification/signing-commits
