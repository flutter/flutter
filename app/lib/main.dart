import 'package:app/app.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
      .then((_) => runApp(const ScholesaApp()));
}
