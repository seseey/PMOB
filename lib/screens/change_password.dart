import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../provider/theme_provider.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({Key? key}) : super(key: key);

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isSaving = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  String? _validatePassword(String password) {
    if (password.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    if (password.length < 6) {
      return 'Password minimal 6 karakter';
    }
    return null;
  }

  bool _validateForm() {
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (currentPassword.isEmpty) {
      _showError('Password saat ini harus diisi');
      return false;
    }

    final passwordError = _validatePassword(newPassword);
    if (passwordError != null) {
      _showError(passwordError);
      return false;
    }

    if (newPassword != confirmPassword) {
      _showError('Konfirmasi password tidak sesuai');
      return false;
    }

    if (currentPassword == newPassword) {
      _showError('Password baru harus berbeda dengan password saat ini');
      return false;
    }

    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red[600]),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green[600]),
    );
  }

  Future<void> _changePassword() async {
    if (!_validateForm()) return;

    setState(() => _isSaving = true);

    try {
      final supabase = Supabase.instance.client;
      final newPassword = _newPasswordController.text.trim();

      // Update password menggunakan Supabase Auth
      final response = await supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (response.user == null) {
        throw Exception('Gagal memperbarui password');
      }

      _showSuccess('Password berhasil diperbarui');

      // Clear form
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      // Delay sebentar untuk user melihat success message
      await Future.delayed(const Duration(milliseconds: 1500));

      if (mounted) {
        Navigator.pop(context);
      }
    } on AuthException catch (e) {
      _showError('Auth error: ${e.message}');
    } catch (e) {
      _showError('Gagal mengganti password: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required Color textColor,
    required Color inputBorderColor,
    TextInputAction? textInputAction,
    VoidCallback? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: textColor.withValues(alpha: 0.6)),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: inputBorderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: inputBorderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: inputBorderColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility : Icons.visibility_off,
            color: textColor.withValues(alpha: 0.7),
          ),
          onPressed: onToggleVisibility,
        ),
      ),
      style: TextStyle(fontSize: 16, color: textColor),
      textInputAction: textInputAction,
      onSubmitted: onSubmitted != null ? (_) => onSubmitted() : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    final backgroundColor =
        isDarkMode ? Colors.grey[900]! : const Color(0xFFF9F6EE);
    final appBarColor =
        isDarkMode ? Colors.grey[850]! : const Color(0xFFA7B59E);
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final buttonColor = isDarkMode ? Colors.blueGrey : const Color(0xCC2E8B57);
    final iconColor = isDarkMode ? Colors.white : Colors.black;
    final inputBorderColor = isDarkMode ? Colors.grey[600]! : Colors.grey[400]!;
    final disabledButtonColor = buttonColor.withValues(alpha: 0.6);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        centerTitle: true,
        title: Text('Change Password', style: TextStyle(color: textColor)),
        backgroundColor: appBarColor,
        iconTheme: IconThemeData(color: iconColor),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),

            // Current Password Field
            _buildPasswordField(
              controller: _currentPasswordController,
              hintText: "Current password",
              obscureText: _obscureCurrentPassword,
              onToggleVisibility:
                  () => setState(
                    () => _obscureCurrentPassword = !_obscureCurrentPassword,
                  ),
              textColor: textColor,
              inputBorderColor: inputBorderColor,
              textInputAction: TextInputAction.next,
            ),

            const SizedBox(height: 16),

            // New Password Field
            _buildPasswordField(
              controller: _newPasswordController,
              hintText: "New password (min. 6 characters)",
              obscureText: _obscureNewPassword,
              onToggleVisibility:
                  () => setState(
                    () => _obscureNewPassword = !_obscureNewPassword,
                  ),
              textColor: textColor,
              inputBorderColor: inputBorderColor,
              textInputAction: TextInputAction.next,
            ),

            const SizedBox(height: 16),

            // Confirm Password Field
            _buildPasswordField(
              controller: _confirmPasswordController,
              hintText: "Confirm new password",
              obscureText: _obscureConfirmPassword,
              onToggleVisibility:
                  () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  ),
              textColor: textColor,
              inputBorderColor: inputBorderColor,
              textInputAction: TextInputAction.done,
              onSubmitted: _changePassword,
            ),

            const SizedBox(height: 24),

            // Save Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 80.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isSaving ? disabledButtonColor : buttonColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isSaving ? null : _changePassword,
                  child:
                      _isSaving
                          ? const SizedBox(
                            height: 20,
                            width: 30,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : const Text(
                            'Save new password',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Password Requirements Info
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Password Requirements:',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• Minimal 6 karakter\n• Berbeda dari password saat ini',
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
