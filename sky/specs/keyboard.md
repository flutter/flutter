Keyboard Events
===============

Scope
-----

The Sky keyboard API is intended to handle the following:

- reporting raw key down/up events from physical keyboards ("Alt"
  down, "E" down, "E" up, "Alt" up)

- reporting simulated raw key down/up events from virtual keyboards,
  if the keyboard provides them

- IME
   - reporting input text events from physical and virtual keyboards
     ("é", autorepeat)
   - inline editing of typed word
   - backspace
   - autocorrect
   - editing around app-provided chips
   - adjusting editor UI (line height, word spacing, etc)
   - replacing selection
   - providing per-phrase alternative interpretations
   - composing letters
   - composing words


API
---

TODO(ianh): Write API.
