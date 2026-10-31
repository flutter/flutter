# PR Description Template

Fill in every section. Delete a section only if it says it is optional.

```markdown
Add an embedder API to <what it does>: `FlutterEngine{Api}`. This is exposed in
dart:ui as `PlatformDispatcher.{name}` with an `on{Name}Changed` callback, which the
framework now uses.

The `flutter/<channel>` platform channel is deprecated but remains for old embedders.
<Inbound: The engine logs an error the first time it is used.> The <list> embedders
are updated to use the new API.

## Design

- Direction: <inbound | outbound>, <state | event>.
- Payload: `<C type>` in the embedder API, `<C++ type>` internally, `<Dart type>` in
  dart:ui.
- <Which existing hops were reused, and why.>
- <Internal representation choice A or B from classification, and why.>

## Compatibility

- Embedders that still send on `flutter/<channel>` keep working.
- Apps listening on `SystemChannels.<channel>` still receive messages. <Or why not.>
- No existing embedder API, public platform header, or dart:ui member changed.
  <Or list each public platform API addition or deprecation, for example a new
  Android constructor and the `@Deprecated` old one.>
- Behaviour changes: <for example "state is now sent from startup instead of after
  the framework listens", or "None".>

## Testing

- <Tests added, per layer.>
- Ran locally: <list of test binaries / commands and results>.

## Unverified platforms

<Platforms whose code changed but which were not built or tested locally, for
example "iOS (no Xcode on host)". Write "None" if everything was verified.>

## Follow-ups (optional)

- <Other methods or the other direction of the channel.>
- <Typed internal path, if option A was chosen.>
- Remove the deprecated channel handling once embedders have migrated.

## Pre-launch Checklist

<Copy the checklist from the repository's pull request template.>
```

Present the filled-in description to the user. Do not create the PR unless asked.
