// app_router.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'sign_in.dart';
import 'reset_password.dart';
import 'lupa_password.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        // Cek apakah ada fragment token di URL untuk reset password
        return MaterialPageRoute(builder: (_) => const InitialRouteHandler());

      case '/sign-in':
        return MaterialPageRoute(builder: (_) => const SignIn());

      case '/lupa-password':
        return MaterialPageRoute(builder: (_) => const LupaPassword());

      case '/reset-password':
        return MaterialPageRoute(builder: (_) => const InitialRouteHandler());

      default:
        return MaterialPageRoute(builder: (_) => const InitialRouteHandler());
    }
  }
}

class InitialRouteHandler extends StatefulWidget {
  const InitialRouteHandler({super.key});

  @override
  State<InitialRouteHandler> createState() => _InitialRouteHandlerState();
}

class _InitialRouteHandlerState extends State<InitialRouteHandler> {
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleInitialRoute();
    });
  }

  void _handleInitialRoute() async {
    setState(() {
      _isProcessing = true;
    });

    // Tambahkan delay kecil untuk menampilkan loading
    await Future.delayed(const Duration(milliseconds: 500));

    // Ambil URL saat ini
    final uri = Uri.base;

    print('Current URL: $uri');
    print('Fragment: ${uri.fragment}');
    print('Query params: ${uri.queryParameters}');

    // Cek apakah ada query parameter 'code' (untuk email confirmation flow)
    final code = uri.queryParameters['code'];
    if (code != null) {
      print('Code detected: $code');
      // Navigate ke reset password dengan code
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResetPasswordWithCode(code: code),
        ),
      );
      return;
    }

    // Cek apakah ada fragment dengan token (untuk direct token flow)
    if (uri.fragment.isNotEmpty) {
      final fragmentParams = _parseUrlParams(uri.fragment);
      final accessToken = fragmentParams['access_token'];
      final type = fragmentParams['type'];

      print('Fragment detected: ${uri.fragment}');
      print('Access token: $accessToken');
      print('Type: $type');

      // Jika ada access token dan type adalah recovery
      if (accessToken != null && type == 'recovery') {
        // Navigate ke reset password
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => ResetPassword(
                  accessToken: accessToken,
                  refreshToken: fragmentParams['refresh_token'] ?? '',
                ),
          ),
        );
        return;
      }
    }

    // Jika tidak ada token atau code, ke halaman login
    setState(() {
      _isProcessing = false;
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SignIn()),
    );
  }

  Map<String, String> _parseUrlParams(String params) {
    final result = <String, String>{};
    final pairs = params.split('&');

    for (final pair in pairs) {
      final keyValue = pair.split('=');
      if (keyValue.length == 2) {
        result[keyValue[0]] = Uri.decodeComponent(keyValue[1]);
      }
    }

    return result;
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
              // Logo or icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  _isProcessing ? Icons.lock_reset : Icons.hourglass_empty,
                  size: 60,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 24),

              // Loading indicator
              const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),

              const SizedBox(height: 20),

              // Status text
              Text(
                _isProcessing
                    ? 'Memverifikasi Link Reset Password...'
                    : 'Memuat Aplikasi...',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // Subtitle
              Text(
                _isProcessing
                    ? 'Mohon tunggu sebentar'
                    : 'Menyiapkan halaman untuk Anda',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),

              if (_isProcessing) ...[
                const SizedBox(height: 20),

                // Progress dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 0; i < 3; i++)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Class untuk handle reset password dengan code
class ResetPasswordWithCode extends StatefulWidget {
  final String code;

  const ResetPasswordWithCode({super.key, required this.code});

  @override
  State<ResetPasswordWithCode> createState() => _ResetPasswordWithCodeState();
}

class _ResetPasswordWithCodeState extends State<ResetPasswordWithCode> {
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _processCode();
  }

  Future<void> _processCode() async {
    try {
      // Proses code untuk mendapatkan session
      final response = await Supabase.instance.client.auth
          .exchangeCodeForSession(widget.code);

      if (response.session != null) {
        // Jika berhasil, redirect ke reset password
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ResetPassword(
                    accessToken: response.session!.accessToken,
                    refreshToken: response.session!.refreshToken,
                  ),
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Gagal memproses link reset password';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Link reset password tidak valid atau sudah expired';
        _isLoading = false;
      });
    }
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
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    _isLoading ? Icons.lock_reset : Icons.error_outline,
                    size: 60,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 24),

                if (_isLoading) ...[
                  const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Memproses Link Reset Password...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  Text(
                    _errorMessage ?? 'Terjadi kesalahan',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const SignIn()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF49843E),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Kembali ke Login',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
