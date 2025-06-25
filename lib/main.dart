import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:app_links/app_links.dart';
import 'constants/supabase_keys.dart';
import 'provider/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/reset_password.dart';
import 'screens/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize date formatting for Indonesian locale
  await initializeDateFormatting('id_ID', null);

  // Initialize Supabase with production configuration
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce, // PKCE flow for better security
      autoRefreshToken: true,
      // persistSession: true, // Removed - parameter doesn't exist in current version
    ),
    realtimeClientOptions: RealtimeClientOptions(
      logLevel: kDebugMode ? RealtimeLogLevel.info : RealtimeLogLevel.error,
    ),
  );

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => ThemeProvider())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  late AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  void _initDeepLinks() async {
    _appLinks = AppLinks();

    // Handle deep link saat app sudah berjalan
    _appLinks.uriLinkStream.listen((uri) {
      print('Received deep link: $uri');
      _handleDeepLink(uri);
    });

    // Handle deep link saat app pertama kali dibuka
    try {
      final initialUri = await _appLinks.getInitialAppLink();
      if (initialUri != null) {
        print('Initial deep link: $initialUri');
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleDeepLink(initialUri);
        });
      }
    } catch (e) {
      print('Failed to get initial app link: $e');
    }
  }

  void _handleDeepLink(Uri uri) {
    print('Handling deep link: $uri');
    print('Path: ${uri.path}');
    print('Query: ${uri.queryParameters}');
    print('Fragment: ${uri.fragment}');

    // Handle reset password dengan code (format baru)
    final code = uri.queryParameters['code'];
    if (code != null && code.isNotEmpty) {
      print('Found reset code: $code');
      _handlePasswordResetWithCode(code);
      return;
    }

    // Handle reset password dengan fragment (format lama)
    if (uri.path.contains('reset') || uri.fragment.contains('access_token')) {
      final fragment = uri.fragment;
      final accessToken = _getFragmentParam(fragment, 'access_token');
      final refreshToken = _getFragmentParam(fragment, 'refresh_token');
      final type = _getFragmentParam(fragment, 'type');

      print('Type: $type');
      print('Access token: $accessToken');

      if (type == 'recovery' && accessToken != null && accessToken.isNotEmpty) {
        _handlePasswordResetWithToken(accessToken, refreshToken);
      }
    }
  }

  void _handlePasswordResetWithCode(String code) {
    print('Handling password reset with code');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Show loading dan exchange code
      _exchangeCodeAndNavigate(code);
    });
  }

  void _handlePasswordResetWithToken(String accessToken, String? refreshToken) {
    print('Handling password reset with token');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(
          builder:
              (context) => ResetPassword(
                accessToken: accessToken,
                refreshToken: refreshToken,
              ),
        ),
        (route) => false,
      );
    });
  }

  Future<void> _exchangeCodeAndNavigate(String code) async {
    // Show loading dialog
    showDialog(
      context: navigatorKey.currentContext!,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Memverifikasi link reset password...'),
                SizedBox(height: 8),
                Text(
                  'Mohon tunggu sebentar',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
    );

    try {
      // Delay untuk UX yang lebih baik
      await Future.delayed(Duration(seconds: 2));

      final supabase = Supabase.instance.client;

      // Exchange code untuk session
      final response = await supabase.auth.verifyOTP(
        token: code,
        type: OtpType.recovery,
      );

      // Close loading dialog
      Navigator.of(navigatorKey.currentContext!).pop();

      if (response.session != null) {
        // Navigate ke reset password
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(
            builder:
                (context) => ResetPassword(
                  accessToken: response.session!.accessToken,
                  refreshToken: response.session!.refreshToken,
                ),
          ),
          (route) => false,
        );
      } else {
        throw Exception('Gagal mendapatkan session dari code');
      }
    } catch (e) {
      print('Error exchanging code: $e');

      // Close loading dialog jika masih ada
      if (Navigator.canPop(navigatorKey.currentContext!)) {
        Navigator.of(navigatorKey.currentContext!).pop();
      }

      // Show error
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        SnackBar(
          content: Text('Link reset password tidak valid atau sudah expired'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  String? _getFragmentParam(String fragment, String key) {
    if (fragment.isEmpty) return null;

    final pairs = fragment.split('&');
    for (final pair in pairs) {
      final keyValue = pair.split('=');
      if (keyValue.length == 2 && keyValue[0] == key) {
        return Uri.decodeComponent(keyValue[1]);
      }
    }
    return null;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false, // Show only in debug mode
      title: 'HydroponicGrow',
      themeMode: themeProvider.themeMode,

      // Light Theme
      theme: ThemeData(
        primarySwatch: Colors.green,
        primaryColor: const Color(0xFF49843E),
        brightness: Brightness.light,
        visualDensity: VisualDensity.adaptivePlatformDensity,

        // AppBar Theme
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF49843E),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),

        // Elevated Button Theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF49843E),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),

        // SnackBar Theme
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      ),

      // Dark Theme
      darkTheme: ThemeData(
        primarySwatch: Colors.green,
        primaryColor: const Color(0xFF49843E),
        brightness: Brightness.dark,
        visualDensity: VisualDensity.adaptivePlatformDensity,

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF49843E),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF49843E),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),

        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      ),

      home: const SplashScreen(),
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: '/',
    );
  }
}
