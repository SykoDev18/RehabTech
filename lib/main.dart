import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:myapp/screens/login_screen.dart';
import 'package:myapp/screens/main/main_nav_screen.dart';
import 'package:myapp/screens/main/ai_chat_screen.dart';
import 'package:myapp/services/progress_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await dotenv.load(fileName: ".env");
  await initializeDateFormatting('es_ES', null);
  await ProgressService().init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RehabTech',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: GoogleFonts.robotoTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: const LoginScreen(),
      routes: {
        '/main': (context) => const MainNavScreen(),
        '/ai_chat': (context) => const AiChatScreen(),
      },
    );
  }
}
