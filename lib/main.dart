import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/book_model.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(LocalBookAdapter());
    }
    // Crucial: Open Hive box here to prevent HiveError Grey Screen crash
    await Hive.openBox<LocalBook>("books");
  } catch (e) {
    debugPrint("Hive initialization error: $e");
  }

  runApp(const AKReaderApp());
}

class AKReaderApp extends StatelessWidget {
  const AKReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "AK Reader",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF2C1609),
        scaffoldBackgroundColor: const Color(0xFF190D04),
        fontFamily: "serif",
      ),
      home: const HomeScreen(),
    );
  }
}
