import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'package:hydroponicgrowv2/services/auth_service.dart';
import 'sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final isSmallScreen = screenWidth < 360;
    final isTablet = screenWidth > 600;

    // Responsive values
    final horizontalPadding =
        isTablet ? screenWidth * 0.25 : (isSmallScreen ? 20.0 : 40.0);
    final logoSize = isSmallScreen ? 40.0 : 50.0;
    final titleFontSize = isSmallScreen ? 18.0 : 20.0;
    final formPadding = isSmallScreen ? 15.0 : 20.0;
    final fieldHeight = isSmallScreen ? 45.0 : 50.0;
    final buttonWidth = isTablet ? 250.0 : (isSmallScreen ? 150.0 : 200.0);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF49843E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed:
              () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const SignIn()),
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
            physics: const ClampingScrollPhysics(),
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
                    SizedBox(height: screenHeight * 0.05),

                    // Logo and Title Section
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/logo.png',
                            width: logoSize,
                            height: logoSize,
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              "HidroponicGrow",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: titleFontSize,
                                fontFamily: 'PlaywriteITModerna',
                                fontStyle: FontStyle.italic,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.05),

                    // Form Container
                    Flexible(
                      child: Container(
                        width: double.infinity,
                        constraints: BoxConstraints(
                          maxWidth: isTablet ? 500 : double.infinity,
                        ),
                        padding: EdgeInsets.all(formPadding),
                        margin: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildEmailField(fieldHeight, isSmallScreen),
                              SizedBox(height: isSmallScreen ? 10 : 15),
                              _buildUsernameField(fieldHeight, isSmallScreen),
                              SizedBox(height: isSmallScreen ? 10 : 15),
                              _buildPasswordField(fieldHeight, isSmallScreen),
                              SizedBox(height: isSmallScreen ? 10 : 15),
                              _buildConfirmPasswordField(
                                fieldHeight,
                                isSmallScreen,
                              ),
                              SizedBox(height: isSmallScreen ? 15 : 20),

                              // Sign Up Button
                              SizedBox(
                                width: buttonWidth,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _signUp,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black.withOpacity(
                                      0.4,
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      vertical: isSmallScreen ? 12 : 15,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child:
                                      _isLoading
                                          ? SizedBox(
                                            height: isSmallScreen ? 20 : 24,
                                            width: isSmallScreen ? 20 : 24,
                                            child:
                                                const CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2,
                                                ),
                                          )
                                          : Text(
                                            "Sign Up",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: isSmallScreen ? 16 : 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                ),
                              ),

                              SizedBox(height: isSmallScreen ? 8 : 10),

                              // Sign In Link
                              TextButton(
                                onPressed:
                                    _isLoading
                                        ? null
                                        : () => Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const SignIn(),
                                          ),
                                        ),
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 12 : 14,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Already have an account? ',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      TextSpan(
                                        text: 'Sign In',
                                        style: TextStyle(color: Colors.yellow),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              SizedBox(height: screenHeight * 0.03),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField(double fieldHeight, bool isSmallScreen) {
    return _buildTextField(
      label: "Email",
      controller: _emailController,
      fieldHeight: fieldHeight,
      isSmallScreen: isSmallScreen,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Email is required';
        if (!EmailValidator.validate(value)) return 'Invalid email format';
        return null;
      },
    );
  }

  Widget _buildUsernameField(double fieldHeight, bool isSmallScreen) {
    return _buildTextField(
      label: "Username",
      controller: _usernameController,
      fieldHeight: fieldHeight,
      isSmallScreen: isSmallScreen,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Username is required';
        if (value.length < 3) return 'Minimum 3 characters';
        return null;
      },
    );
  }

  Widget _buildPasswordField(double fieldHeight, bool isSmallScreen) {
    return _buildPasswordFieldTemplate(
      label: "Password",
      controller: _passwordController,
      obscureText: _obscurePassword,
      fieldHeight: fieldHeight,
      isSmallScreen: isSmallScreen,
      toggleObscure: () {
        setState(() {
          _obscurePassword = !_obscurePassword;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) return 'Password is required';
        if (value.length < 6) return 'Minimum 6 characters';
        return null;
      },
    );
  }

  Widget _buildConfirmPasswordField(double fieldHeight, bool isSmallScreen) {
    return _buildPasswordFieldTemplate(
      label: "Confirm Password",
      controller: _confirmPasswordController,
      obscureText: _obscureConfirmPassword,
      fieldHeight: fieldHeight,
      isSmallScreen: isSmallScreen,
      toggleObscure: () {
        setState(() {
          _obscureConfirmPassword = !_obscureConfirmPassword;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please confirm password';
        if (value != _passwordController.text) return 'Passwords do not match';
        return null;
      },
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required double fieldHeight,
    required bool isSmallScreen,
    required String? Function(String?) validator,
  }) {
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
        const SizedBox(height: 5),
        Container(
          height: fieldHeight,
          decoration: BoxDecoration(
            color: const Color(0xFFD9D9D9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextFormField(
            controller: controller,
            validator: validator,
            style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 8 : 10,
                vertical: isSmallScreen ? 8 : 10,
              ),
              errorStyle: TextStyle(
                fontSize: isSmallScreen ? 10 : 12,
                color: Colors.red[300],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordFieldTemplate({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required double fieldHeight,
    required bool isSmallScreen,
    required VoidCallback toggleObscure,
    required String? Function(String?) validator,
  }) {
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
        const SizedBox(height: 5),
        Container(
          height: fieldHeight,
          decoration: BoxDecoration(
            color: const Color(0xFFD9D9D9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            validator: validator,
            style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 8 : 10,
                vertical: isSmallScreen ? 8 : 10,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                  size: isSmallScreen ? 20 : 24,
                ),
                onPressed: toggleObscure,
              ),
              errorStyle: TextStyle(
                fontSize: isSmallScreen ? 10 : 12,
                color: Colors.red[300],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _signUp() async {
    // Validasi manual untuk memberikan feedback yang lebih baik
    final email = _emailController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Validasi email
    if (email.isEmpty) {
      _showDialog("Email tidak boleh kosong");
      return;
    }
    if (!EmailValidator.validate(email)) {
      _showDialog("Format email tidak valid");
      return;
    }

    // Validasi username
    if (username.isEmpty) {
      _showDialog("Username tidak boleh kosong");
      return;
    }
    if (username.length < 3) {
      _showDialog("Username minimal 3 karakter");
      return;
    }

    // Validasi password
    if (password.isEmpty) {
      _showDialog("Password tidak boleh kosong");
      return;
    }
    if (password.length < 6) {
      _showDialog("Password minimal 6 karakter");
      return;
    }

    // Validasi confirm password
    if (confirmPassword.isEmpty) {
      _showDialog("Konfirmasi password tidak boleh kosong");
      return;
    }
    if (password != confirmPassword) {
      _showDialog("Password dan konfirmasi password tidak cocok");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check username existence first
      final usernameExists = await _authService.isUsernameExists(username);
      if (usernameExists) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showDialog("Username sudah digunakan. Silakan pilih username lain.");
        }
        return;
      }

      // Sign up user
      final response = await _authService.signUp(email, password);
      if (response.user == null) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showDialog("Registrasi gagal. Silakan coba lagi.");
        }
        return;
      }

      // Create user profile dengan delay untuk memastikan auth selesai
      await Future.delayed(const Duration(milliseconds: 500));

      await _authService.createUserProfile(
        userId: response.user!.id,
        username: username,
        email: email,
        password: password,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        _showDialog('Akun berhasil dibuat. Silakan login.', isError: false);
      }
    } on PostgrestException catch (e) {
      // Handle specific Supabase errors
      if (mounted) {
        setState(() => _isLoading = false);
        if (e.code == 'PGRST204') {
          // Data mungkin sudah tersimpan, tapi response error
          _showDialog('Akun berhasil dibuat. Silakan login.', isError: false);
        } else {
          _showDialog("Error database: ${e.message}");
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        String errorMessage = "Terjadi kesalahan: ${e.toString()}";

        // Handle common auth errors
        if (e.toString().contains("User already registered")) {
          errorMessage = "Email sudah terdaftar. Silakan gunakan email lain.";
        } else if (e.toString().contains("Invalid email")) {
          errorMessage = "Format email tidak valid.";
        }

        _showDialog(errorMessage);
      }
    }
  }

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
              onPressed: () {
                Navigator.of(context).pop();
                // Jika sukses, navigate ke SignIn
                if (!isError) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const SignIn()),
                  );
                }
              },
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
}
