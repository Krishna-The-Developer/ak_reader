import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/book_model.dart';
import 'screens/bookshelf_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Safe UI fallback (Grey screen prevention)
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1008),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.menu_book, color: Color(0xFFFFD59E), size: 48),
                const SizedBox(height: 14),
                const Text(
                  "AK Reader",
                  style: TextStyle(
                    color: Color(0xFFFFD59E),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: "serif",
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  details.exceptionAsString(),
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(color: Color(0xFFD7CCC8), fontSize: 12),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8D4E24),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => main(),
                  child: const Text("Reload AK Reader"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  };

  try {
    await Hive.initFlutter();
    final adapter = LocalBookAdapter();
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter(adapter);
    }
    await Hive.openBox<LocalBook>('books');
  } catch (e) {
    debugPrint("Hive initialization notice: $e");
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
        scaffoldBackgroundColor: const Color(0xFF1E1008),
        primaryColor: const Color(0xFF8D4E24),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF8D4E24),
          secondary: Color(0xFFFFD59E),
          surface: Color(0xFF2A1508),
        ),
        fontFamily: "serif",
      ),
      initialRoute: "/",
      routes: {
        "/": (context) => const BookshelfScreen(),
        "/bookshelf": (context) => const BookshelfScreen(),
        "/home": (context) => const HomeScreen(),
      },
    );
  }
}
