Provides an in-memory `Resolvers` implementation for use with `package:build`.

This implementation does a monolithic analysis from source, with fine grained
invalidation, which works well when it can be shared across multiple build steps
in the same process. It is not however suitable for use in more general build
systems, which should build up their analysis context using analyzer summaries.
