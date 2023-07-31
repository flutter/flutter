// termios.dart
//
// Dart representations of functions and constants used in termios.h

import 'dart:ffi';

// INPUT FLAGS
const int IGNBRK = 0x00000001; // ignore BREAK condition
const int BRKINT = 0x00000002; // map BREAK to SIGINTR
const int IGNPAR = 0x00000004; // ignore (discard) parity errors
const int PARMRK = 0x00000008; // mark parity and framing errors
const int INPCK = 0x00000010; // enable checking of parity errors
const int ISTRIP = 0x00000020; // strip 8th bit off chars
const int INLCR = 0x00000040; // map NL into CR
const int IGNCR = 0x00000080; // ignore CR
const int ICRNL = 0x00000100; // map CR to NL (ala CRMOD)
const int IXON = 0x00000200; // enable output flow control
const int IXOFF = 0x00000400; // enable input flow control
const int IXANY = 0x00000800; // any char will restart after stop
const int IMAXBEL = 0x00002000; // ring bell on input queue full
const int IUTF8 = 0x00004000; // maintain state for UTF-8 VERASE

// OUTPUT FLAGS
const int OPOST = 0x00000001; // enable following output processing
const int ONLCR = 0x00000002; // map NL to CR-NL (ala CRMOD)
const int OXTABS = 0x00000004; // expand tabs to spaces
const int ONOEOT = 0x00000008; // discard EOT's (^D) on output)

// CONTROL FLAGS
const int CIGNORE = 0x00000001; // ignore control flags
const int CSIZE = 0x00000300; // character size mask
const int CS5 = 0x00000000; // 5 bits (pseudo)
const int CS6 = 0x00000100; // 6 bits
const int CS7 = 0x00000200; // 7 bits
const int CS8 = 0x00000300; // 8 bits

// LOCAL FLAGS
const int ECHOKE = 0x00000001; // visual erase for line kill
const int ECHOE = 0x00000002; // visually erase chars
const int ECHOK = 0x00000004; // echo NL after line kill
const int ECHO = 0x00000008; // enable echoing
const int ECHONL = 0x00000010; // echo NL even if ECHO is off
const int ECHOPRT = 0x00000020; // visual erase mode for hardcopy
const int ECHOCTL = 0x00000040; // echo control chars as ^(Char)
const int ISIG = 0x00000080; // enable signals INTR, QUIT, [D]SUSP
const int ICANON = 0x00000100; // canonicalize input lines
const int ALTWERASE = 0x00000200; // use alternate WERASE algorithm
const int IEXTEN = 0x00000400; // enable DISCARD and LNEXT
const int EXTPROC = 0x00000800; // external processing
const int TOSTOP = 0x00400000; // stop background jobs from output
const int FLUSHO = 0x00800000; // output being flushed (state)
const int NOKERNINFO = 0x02000000; // no kernel output from VSTATUS
const int PENDIN = 0x20000000; // XXX retype pending input (state)
const int NOFLSH = 0x80000000; // don't flush after interrupt

const int TCSANOW = 0; // make change immediate
const int TCSADRAIN = 1; // drain output, then change
const int TCSAFLUSH = 2; // drain output, flush input

const int VMIN = 16; // minimum number of characters to receive
const int VTIME = 17; // time in 1/10s before returning

// typedef unsigned long   tcflag_t;
// typedef unsigned char   cc_t;
// typedef unsigned long   speed_t;
// #define NCCS            20

// struct termios {
// 	tcflag_t        c_iflag;        /* input flags */
// 	tcflag_t        c_oflag;        /* output flags */
// 	tcflag_t        c_cflag;        /* control flags */
// 	tcflag_t        c_lflag;        /* local flags */
// 	cc_t            c_cc[NCCS];     /* control chars */
// 	speed_t         c_ispeed;       /* input speed */
// 	speed_t         c_ospeed;       /* output speed */
// };
class TermIOS extends Struct {
  @Int64()
  external int c_iflag;
  @Int64()
  external int c_oflag;
  @Int64()
  external int c_cflag;
  @Int64()
  external int c_lflag;

  // This replaces c_cc[20]
  @Int8()
  external int c_cc0;
  @Int8()
  external int c_cc1;
  @Int8()
  external int c_cc2;
  @Int8()
  external int c_cc3;
  @Int8()
  external int c_cc4;
  @Int8()
  external int c_cc5;
  @Int8()
  external int c_cc6;
  @Int8()
  external int c_cc7;
  @Int8()
  external int c_cc8;
  @Int8()
  external int c_cc9;
  @Int8()
  external int c_cc10;
  @Int8()
  external int c_cc11;
  @Int8()
  external int c_cc12;
  @Int8()
  external int c_cc13;
  @Int8()
  external int c_cc14;
  @Int8()
  external int c_cc15;
  @Int8()
  external int c_cc16; // VMIN
  @Int8()
  external int c_cc17; // VTIME
  @Int8()
  external int c_cc18;
  @Int8()
  external int c_cc19;

  @Int64()
  external int c_ispeed;
  @Int64()
  external int c_ospeed;
}

// int tcgetattr(int, struct termios *);
typedef tcgetattrNative = Int32 Function(
    Int32 fildes, Pointer<TermIOS> termios);
typedef tcgetattrDart = int Function(int fildes, Pointer<TermIOS> termios);

// int tcsetattr(int, int, const struct termios *);
typedef tcsetattrNative = Int32 Function(
    Int32 fildes, Int32 optional_actions, Pointer<TermIOS> termios);
typedef tcsetattrDart = int Function(
    int fildes, int optional_actions, Pointer<TermIOS> termios);
