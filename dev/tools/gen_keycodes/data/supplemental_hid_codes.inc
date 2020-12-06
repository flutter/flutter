  // These are supplemental key codes to be added to those that Chromium
  // defines. Since the web doesn't have game controller buttons defined in the
  // same way, these map USB HID codes for game controller buttons to
  // Android/Linux button names.
  //
  // The HID codes here are not real USB HID codes, because the USB HID standard
  // doesn't define game controller buttons in this way. It defines only two
  // button "collections" (fire/jump and trigger), with the button number for
  // each collection sent as extra data. Since we're just using USB HID as a
  // convenient namespace, and not using these HID codes for interfacing with a
  // USB protocol, we can define new ones to enumerate the buttons. These don't
  // collide with any currently defined HID codes.
  //
  //        USB HID    evdev    XKB     Win    Mac  DOMKey         Code
  DOM_CODE(0x05ff01, 0x0000, 0x0000, 0x0000, 0xffff, "GameButton1", BUTTON_1),
  DOM_CODE(0x05ff02, 0x0000, 0x0000, 0x0000, 0xffff, "GameButton2", BUTTON_2),
  DOM_CODE(0x05ff03, 0x0000, 0x0000, 0x0000, 0xffff, "GameButton3", BUTTON_3),
  DOM_CODE(0x05ff04, 0x0000, 0x0000, 0x0000, 0xffff, "GameButton4", BUTTON_4),
  DOM_CODE(0x05ff05, 0x0000, 0x0000, 0x0000, 0xffff, "GameButton5", BUTTON_5),
  DOM_CODE(0x05ff06, 0x0000, 0x0000, 0x0000, 0xffff, "GameButton6", BUTTON_6),
  DOM_CODE(0x05ff07, 0x0000, 0x0000, 0x0000, 0xffff, "GameButton7", BUTTON_7),
  DOM_CODE(0x05ff08, 0x0000, 0x0000, 0x0000, 0xffff, "GameButton8", BUTTON_8),
  DOM_CODE(0x05ff09, 0x0000, 0x0000, 0x0000, 0xffff, "GameButton9", BUTTON_9),
  DOM_CODE(0x05ff0a, 0x0000, 0x0000, 0x0000, 0xffff, "GameButton10", BUTTON_10),
  DOM_CODE(0x05ff0b, 0x0000, 0x0000, 0x0000, 0xffff, "GameButton11", BUTTON_11),
  DOM_CODE(0x05ff0c, 0x0000, 0x0000, 0x0000, 0xffff, "GameButton12", BUTTON_12),
  DOM_CODE(0x05ff0d, 0x0000, 0x0000, 0x0000, 0xffff, "GameButton13", BUTTON_13),
  DOM_CODE(0x05ff0e, 0x0000, 0x0000, 0x0000, 0xffff, "GameButton14", BUTTON_14),
  DOM_CODE(0x05ff0f, 0x0000, 0x0000, 0x0000, 0xffff, "GameButton15", BUTTON_15),
  DOM_CODE(0x05ff10, 0x0000, 0x0000, 0x0000, 0xffff, "GameButton16", BUTTON_16),
  DOM_CODE(0x05ff11, 0x0000, 0x0000, 0x0000, 0xffff, "GameButtonA", BUTTON_A),
  DOM_CODE(0x05ff12, 0x0000, 0x0000, 0x0000, 0xffff, "GameButtonB", BUTTON_B),
  DOM_CODE(0x05ff13, 0x0000, 0x0000, 0x0000, 0xffff, "GameButtonC", BUTTON_C),
  DOM_CODE(0x05ff14, 0x0000, 0x0000, 0x0000, 0xffff, "GameButtonLeft1", BUTTON_L1),
  DOM_CODE(0x05ff15, 0x0000, 0x0000, 0x0000, 0xffff, "GameButtonLeft2", BUTTON_L2),
  DOM_CODE(0x05ff16, 0x0000, 0x0000, 0x0000, 0xffff, "GameButtonMode", BUTTON_MODE),
  DOM_CODE(0x05ff17, 0x0000, 0x0000, 0x0000, 0xffff, "GameButtonRight1", BUTTON_R1),
  DOM_CODE(0x05ff18, 0x0000, 0x0000, 0x0000, 0xffff, "GameButtonRight2", BUTTON_R2),
  DOM_CODE(0x05ff19, 0x0000, 0x0000, 0x0000, 0xffff, "GameButtonSelect", BUTTON_SELECT),
  DOM_CODE(0x05ff1a, 0x0000, 0x0000, 0x0000, 0xffff, "GameButtonStart", BUTTON_START),
  DOM_CODE(0x05ff1b, 0x0000, 0x0000, 0x0000, 0xffff, "GameButtonThumbLeft", BUTTON_THUMBL),
  DOM_CODE(0x05ff1c, 0x0000, 0x0000, 0x0000, 0xffff, "GameButtonThumbRight", BUTTON_THUMBR),
  DOM_CODE(0x05ff1d, 0x0000, 0x0000, 0x0000, 0xffff, "GameButtonX", BUTTON_X),
  DOM_CODE(0x05ff1e, 0x0000, 0x0000, 0x0000, 0xffff, "GameButtonY", BUTTON_Y),
  DOM_CODE(0x05ff1f, 0x0000, 0x0000, 0x0000, 0xffff, "GameButtonZ", BUTTON_Z),

  // The Mac defines a key code for the Fn key on Mac keyboards, but it's not
  // defined on other platforms. Chromium does define an "Fn" row, but doesn't
  // give it a Mac keycode. This overrides their definition.
  //        USB HID    evdev    XKB     Win    Mac  DOMKey         Code
   DOM_CODE(0x000012, 0x0000, 0x0000, 0x0000, 0x003f, "Fn", FN),
