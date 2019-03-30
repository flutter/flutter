import 'package:android_embedding/default_flutter_app.dart';
import 'package:android_embedding/fragment_flutter_app.dart';
import 'package:android_embedding/fullscreen_flutter_app.dart';
import 'package:android_embedding/login_screen_app.dart';
import 'package:android_embedding/profile_screen_app.dart';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

@pragma('vm:entry-point')
void fullscreenFlutter() => runApp(FullscreenFlutterApp());

@pragma('vm:entry-point')
void fragmentFlutter() => runApp(FragmentFlutterApp());

@pragma('vm:entry-point')
void loginScreen() => runApp(LoginScreenApp());

void profileScreen() => runApp(ProfileScreenApp());
