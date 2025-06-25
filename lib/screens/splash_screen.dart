import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'HomePage.dart';
import 'sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // Tunggu sebentar untuk splash effect
    await Future.delayed(const Duration(seconds: 2));

    try {
      final session = supabase.auth.currentSession;

      if (session != null) {
        // Cek apakah session masih valid dalam 120 menit
        final prefs = await SharedPreferences.getInstance();
        final loginTime = prefs.getInt('login_time') ?? 0;
        final currentTime = DateTime.now().millisecondsSinceEpoch;
        final sessionDuration = 120 * 60 * 1000; // 120 menit dalam milliseconds

        if (currentTime - loginTime < sessionDuration) {
          // Session masih valid, langsung ke HomePage
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
          }
          return;
        } else {
          // Session expired, logout
          await _logout();
        }
      }

      // Tidak ada session atau session expired, ke SignIn
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SignIn()),
        );
      }
    } catch (e) {
      // Error, arahkan ke SignIn
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SignIn()),
        );
      }
    }
  }

  Future<void> _logout() async {
    await supabase.auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('login_time');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [Color(0xFFF8F6DF), Color(0xFF49843E)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'images/logo.png',
                width: 80,
                height: 80,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.eco, size: 80, color: Colors.white);
                },
              ),
              const SizedBox(height: 20),
              const Text(
                "HidroponicGrow",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontFamily: 'PlaywriteITModerna',
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
