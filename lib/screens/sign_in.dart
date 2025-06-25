import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'HomePage.dart';
import 'sign_up.dart';
import 'lupa_password.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  SignInState createState() => SignInState(); // Made public
}

class SignInState extends State<SignIn> {
  // Made public
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  final supabase = Supabase.instance.client;

  void _showDialog(String message, {bool isError = true}) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: isError ? Colors.red : Colors.green,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                isError ? "Error" : "Berhasil",
                style: TextStyle(
                  color: isError ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Text(message, style: TextStyle(fontSize: 16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                backgroundColor: isError ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showDialog("Email dan password tidak boleh kosong");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.user != null) {
        // Simpan waktu login untuk session management
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('login_time', DateTime.now().millisecondsSinceEpoch);

        if (kDebugMode) {
          print("Login berhasil: ${res.user!.id}");
        }
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } else {
        if (!mounted) return;
        _showDialog("Login gagal, pengguna tidak ditemukan.");
      }
    } on AuthException catch (e) {
      String errorMessage = e.message;
      if (errorMessage.toLowerCase().contains("invalid login credentials")) {
        errorMessage = "Email atau password salah";
      }
      _showDialog(errorMessage);
    } catch (e) {
      if (kDebugMode) {
        print("Error saat login: $e");
      }
      _showDialog("Terjadi kesalahan saat login.");
    }
  }

  Future<void> _sendResetPasswordEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showDialog("Masukkan email terlebih dahulu");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Kirim email reset password dengan redirect URL
      await supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'hydroponicgrow://reset-callback', // Deep link scheme Anda
      );

      _showDialog(
        "Email reset password telah dikirim ke $email. Silakan cek email Anda dan klik link yang diberikan.",
        isError: false,
      );
    } on AuthException catch (e) {
      String errorMessage = e.message;
      if (errorMessage.toLowerCase().contains("user not found")) {
        errorMessage = "Email tidak ditemukan";
      }
      _showDialog(errorMessage);
    } catch (e) {
      if (kDebugMode) {
        print("Error saat reset password: $e");
      }
      _showDialog("Terjadi kesalahan saat reset password.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 600;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF49843E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed:
              () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const SignUp()),
              ),
        ),
      ),
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
        child: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    screenHeight -
                    MediaQuery.of(context).padding.top -
                    kToolbarHeight,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    SizedBox(
                      height:
                          isSmallScreen
                              ? screenHeight * 0.03
                              : screenHeight * 0.05,
                    ),

                    // Logo and Title Section
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.1,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/logo.png',
                            width: isSmallScreen ? 40 : 50,
                            height: isSmallScreen ? 40 : 50,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "HidroponicGrow",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isSmallScreen ? 16 : 20,
                              fontFamily: 'PlaywriteITModerna',
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Fixed spacing instead of Expanded
                    SizedBox(
                      height:
                          isSmallScreen
                              ? screenHeight * 0.06
                              : screenHeight * 0.1,
                    ),

                    // Form Container
                    Container(
                      padding: EdgeInsets.all(screenWidth * 0.05),
                      margin: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildTextField("Email", _emailController),
                          SizedBox(height: screenHeight * 0.02),
                          _buildPasswordField(),
                          SizedBox(height: screenHeight * 0.015),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LupaPassword(),
                                ),
                              );
                            },
                            child: Text(
                              "Forget Password?",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isSmallScreen ? 12 : 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.04),

                    // Sign In Button
                    SizedBox(
                      width: screenWidth * 0.5,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.4),
                          padding: EdgeInsets.symmetric(
                            vertical: screenHeight * 0.02,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child:
                            _isLoading
                                ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : Text(
                                  "Sign In",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isSmallScreen ? 16 : 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                      ),
                    ),

                    // Bottom flexible spacing (keep this to push content up)
                    Expanded(flex: 1, child: Container()),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: screenHeight * 0.008),
        Container(
          height: isSmallScreen ? 45 : 50,
          decoration: BoxDecoration(
            color: const Color(0xFFD9D9D9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType:
                label == "Email"
                    ? TextInputType.emailAddress
                    : TextInputType.text,
            style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Password",
          style: TextStyle(
            color: Colors.white,
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: screenHeight * 0.008),
        Container(
          height: isSmallScreen ? 45 : 50,
          decoration: BoxDecoration(
            color: const Color(0xFFD9D9D9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 12,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                  size: isSmallScreen ? 20 : 24,
                ),
                onPressed:
                    () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
