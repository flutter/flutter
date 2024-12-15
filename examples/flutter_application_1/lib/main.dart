import 'package:flutter/material.dart';
import 'view/loading_screen.dart';
import 'view/home_screen.dart';
import 'view/camera_screen.dart';
import 'view/select_photo_screen.dart';
import 'view/select_frame_screen.dart';
// import 'view/result_screen.dart';
import 'view/instruction_screen.dart';
import 'view/qr_code_screen.dart';
import 'view/pose_guide_mode_screen.dart';
import 'view/timer_setting_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lopes 4 Cuts',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color.fromARGB(255, 224, 202, 254),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 54, 10, 93)),
        useMaterial3: true,
      ),
      initialRoute: '/loading',
      routes: {
        '/': (context) => const InstructionScreen(),
        '/home': (context) => const HomeScreen(),
        '/camera': (context) => const CameraScreen(),
        '/select-photo': (context) => const SelectPhotoScreen(),
        '/select-frame': (context) => const SelectFrameScreen(),
        '/qr-code': (context) => const QRCodeScreen(),
        '/pose-guide-mode': (context) => const PoseGuideModeScreen(),
        '/timer-setting': (context) => const TimerSettingScreen(),
        '/loading': (context) => const LoadingScreen(),
      },
    );
  }
}
