# Devtools packages

The `common` subdirectory contains what we currently expose as "devtools",
mirroring it as a [separate repository](https://github.com/domokit/devtools) for
consumption without a Mojo checkout.

Further subdirectories TBD might be added in the future, to contain heavy
language-specific tooling which we will mirror / expose separately.

The toolsets are intended for consumption by Mojo consumers as **separate
checkouts**. No dependencies on files outside of devtools are allowed.
