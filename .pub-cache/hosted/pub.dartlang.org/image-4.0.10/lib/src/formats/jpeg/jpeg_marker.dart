import '../../util/_internal.dart';

@internal
class JpegMarker {
  static const sof0 = 0xc0;
  static const sof1 = 0xc1;
  static const sof2 = 0xc2;
  static const sof3 = 0xc3;
  static const sof5 = 0xc5;
  static const sof6 = 0xc6;
  static const sof7 = 0xc7;

  static const jpg = 0xc8;
  static const sof9 = 0xc9;
  static const sof10 = 0xca;
  static const sof11 = 0xcb;

  static const sof13 = 0xcd;
  static const sof14 = 0xce;
  static const sof15 = 0xcf;

  static const dht = 0xc4;

  static const dac = 0xcc;

  static const rst0 = 0xd0;
  static const rst1 = 0xd1;
  static const rst2 = 0xd2;
  static const rst3 = 0xd3;
  static const rst4 = 0xd4;
  static const rst5 = 0xd5;
  static const rst6 = 0xd6;
  static const rst7 = 0xd7;

  static const soi = 0xd8;
  static const eoi = 0xd9;
  static const sos = 0xda;
  static const dqt = 0xdb;
  static const dnl = 0xdc;
  static const dri = 0xdd;
  static const dhp = 0xde;
  static const exp = 0xdf;

  static const app0 = 0xe0; // JFIF, JFXX, CIFF, AVI1, Ocad
  static const app1 = 0xe1; // EXIF, ExtendedXMP, XMP, QVCI, FLIR
  static const app2 = 0xe2; // ICC_Profile, FPXR, MPF, PreviewImage
  static const app3 = 0xe3; // Meta, Stim, PreviewImage
  static const app4 = 0xe4; // Scalado, FPXR, PreviewImage
  static const app5 = 0xe5; // RMETA, PreviewImage
  static const app6 = 0xe6; // EPPIM, NITF, HP_TDHD, GoPro
  static const app7 = 0xe7; // Pentax, Qualcomm
  static const app8 = 0xe8; // SPIFF
  static const app9 = 0xe9; // MediaJukebox
  static const app10 = 0xea; // Comment
  static const app11 = 0xeb; // Jpeg-HDR
  static const app12 = 0xec; // PictureInfo, Ducky
  static const app13 = 0xed; // Photoshop, Adobe_CM
  static const app14 = 0xee; // ADOBE
  static const app15 = 0xef; // GraphicConverter

  static const jpg0 = 0xf0;
  static const jpg13 = 0xfd;
  static const com = 0xfe;

  static const tem = 0x01;

  static const error = 0x100;

  const JpegMarker(this.value);
  final int value;
}
