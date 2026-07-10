import 'package:firebase_core/firebase_core.dart';
import 'package:personal_training_app/utils/firebase_service.dart';

Future<void> main() async {
  print('Initializing Firebase...');
  await Firebase.initializeApp();
  print('Deleting all clients...');
  await FirebaseService.deleteAllClients();
  print('Deleting all workouts...');
  await FirebaseService.deleteAllWorkouts();
  print('✅ All clients and workouts deleted.');
}
