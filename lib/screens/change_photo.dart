import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import 'dart:io';
import '../provider/theme_provider.dart';
import '../services/user_service.dart';
import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;

class ChangeProfilePhotoPage extends StatefulWidget {
  final String? currentPhotoUrl;

  const ChangeProfilePhotoPage({Key? key, this.currentPhotoUrl})
    : super(key: key);

  @override
  State<ChangeProfilePhotoPage> createState() => _ChangeProfilePhotoPageState();
}

class _ChangeProfilePhotoPageState extends State<ChangeProfilePhotoPage> {
  final UserService _userService = UserService();
  final ImagePicker _picker = ImagePicker();

  XFile? _selectedFile;
  Uint8List? _imageBytes;
  bool _isLoading = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentPhoto();
  }

  Future<void> _loadCurrentPhoto() async {
    if (widget.currentPhotoUrl != null && widget.currentPhotoUrl!.isNotEmpty) {
      try {
        setState(() => _isLoading = true);

        // Load image from URL
        final response = await HttpClient().getUrl(
          Uri.parse(widget.currentPhotoUrl!),
        );
        final httpResponse = await response.close();
        final bytes = await consolidateHttpClientResponseBytes(httpResponse);

        if (mounted) {
          setState(() {
            _imageBytes = bytes;
            _isLoading = false;
          });
        }
      } catch (e) {
        developer.log('Error loading current photo: $e');
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedFile = pickedFile;
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        _showError('Gagal memilih foto dari galeri: ${e.toString()}');
      }
    }

    if (mounted && Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _takePhoto() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedFile = pickedFile;
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        _showError('Gagal mengambil foto: ${e.toString()}');
      }
    }

    if (mounted && Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _removePhoto() async {
    setState(() {
      _selectedFile = null;
      _imageBytes = null;
    });

    if (mounted && Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  void _showImageOptions() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final textColor = isDarkMode ? Colors.white : Colors.black;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Pilih Foto Profil',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Icon(Icons.camera_alt, color: textColor),
                  title: Text('Ambil Foto', style: TextStyle(color: textColor)),
                  onTap: _takePhoto,
                ),
                ListTile(
                  leading: Icon(Icons.photo_library, color: textColor),
                  title: Text(
                    'Pilih dari Galeri',
                    style: TextStyle(color: textColor),
                  ),
                  onTap: _pickImageFromGallery,
                ),
                if (widget.currentPhotoUrl != null || _imageBytes != null)
                  ListTile(
                    leading: Icon(Icons.delete, color: Colors.red[600]),
                    title: Text(
                      'Hapus Foto',
                      style: TextStyle(color: Colors.red[600]),
                    ),
                    onTap: _removePhoto,
                  ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String?> _uploadProfilePhoto() async {
    if (_selectedFile == null) return null;

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final bytes = await _selectedFile!.readAsBytes();
      final userId = user.id;
      // Tambahkan timestamp untuk menghindari cache
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '$userId/profile_$timestamp.jpg';

      await Supabase.instance.client.storage
          .from('userprofile')
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      final publicUrl = Supabase.instance.client.storage
          .from('userprofile')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      throw Exception('Gagal mengupload foto: ${e.toString()}');
    }
  }

  Future<void> _saveProfilePhoto() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _showError('User tidak terautentikasi');
      return;
    }

    setState(() => _isUploading = true);

    try {
      String? newPhotoUrl;

      // If user selected a new photo, upload it
      if (_selectedFile != null) {
        newPhotoUrl = await _uploadProfilePhoto();
      } else if (_imageBytes == null) {
        // User removed the photo
        newPhotoUrl = null;
      } else {
        // No changes, keep current photo
        newPhotoUrl = widget.currentPhotoUrl;
      }

      // Update user profile using UserService
      await _userService.updateUserProfile(
        userId: user.id,
        profilePhoto: newPhotoUrl,
      );

      if (mounted) {
        _showSuccess('Foto profil berhasil diperbarui');
      }

      // Return the new photo URL to parent
      await Future.delayed(const Duration(seconds: 3));

      if (mounted) {
        Navigator.pop(context, newPhotoUrl);
      }
    } catch (e) {
      if (mounted) {
        _showError('Gagal menyimpan foto profil: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red[600]),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green[600]),
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
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
    final cardColor = isDarkMode ? Colors.grey[800] : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        centerTitle: true,
        title: Text('Change Profile Photo', style: TextStyle(color: textColor)),
        backgroundColor: appBarColor,
        iconTheme: IconThemeData(color: iconColor),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 40),

            // Profile Photo Section
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: _showImageOptions,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cardColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child:
                          _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : ClipOval(
                                child:
                                    _imageBytes != null
                                        ? Image.memory(
                                          _imageBytes!,
                                          width: 140,
                                          height: 140,
                                          fit: BoxFit.cover,
                                        )
                                        : Container(
                                          width: 140,
                                          height: 140,
                                          color: Colors.grey[300],
                                          child: Icon(
                                            Icons.person,
                                            size: 60,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                              ),
                    ),
                  ),

                  // Edit Icon
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _showImageOptions,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: buttonColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: backgroundColor, width: 3),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Tap to change photo',
              style: TextStyle(
                color: textColor.withValues(alpha: 0.7),
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 40),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isUploading ? null : _saveProfilePhoto,
                child:
                    _isUploading
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : const Text(
                          'Save Photo',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
              ),
            ),

            const SizedBox(height: 16),

            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tips:',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Gunakan foto dengan resolusi minimal 400x400px\n'
                    '• Format yang didukung: JPG, PNG\n'
                    '• Ukuran maksimal: 5MB',
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.7),
                      fontSize: 13,
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
