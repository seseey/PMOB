import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../provider/theme_provider.dart';
import '../screens/sign_in.dart';
import '../screens/history_page.dart';

class DrawerPage extends StatefulWidget {
  const DrawerPage({super.key}); // Fixed: Added key parameter

  @override
  DrawerPageState createState() => DrawerPageState(); // Fixed: Removed underscore to make it public
}

class DrawerPageState extends State<DrawerPage> {
  // Fixed: Made public
  User? currentUser;
  Map<String, dynamic>? userData;
  bool isLoading = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserAndProfile();
  }

  Future<void> _fetchCurrentUserAndProfile() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      currentUser = Supabase.instance.client.auth.currentUser;

      if (currentUser != null) {
        try {
          // Try to get existing user data
          final response =
              await Supabase.instance.client
                  .from('users')
                  .select()
                  .eq('id', currentUser!.id)
                  .single();

          userData = response;
        } catch (e) {
          // Jika user tidak ditemukan di database
          if (e.toString().contains('0 rows') ||
              e.toString().contains('PGRST116')) {
            // JANGAN buat user record otomatis lagi
            // Karena seharusnya sudah dibuat saat sign up
            errorMessage = 'User profile not found. Please contact support.';
          } else {
            rethrow;
          }
        }
      } else {
        errorMessage = 'No user logged in';
      }
    } catch (e) {
      errorMessage = 'Failed to load profile: ${e.toString()}';
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout'),
          content: Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Tutup dialog dulu
                try {
                  await Supabase.instance.client.auth.signOut();
                  if (mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const SignIn()),
                      (Route<dynamic> route) => false,
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Sign out error: $e')),
                    );
                  }
                }
              },
              child: Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[850]! : const Color(0xFFA7B59E),
            ),
            child:
                isLoading
                    ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                    : errorMessage.isNotEmpty
                    ? Center(
                      child: Text(
                        errorMessage,
                        style: const TextStyle(color: Colors.white),
                      ),
                    )
                    : Row(
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundImage:
                              userData != null &&
                                      userData!['profile_photo'] != null
                                  ? NetworkImage(userData!['profile_photo'])
                                  : const AssetImage('images/default.jpg')
                                      as ImageProvider,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            userData?['username'] ?? "User",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed:
                              () =>
                                  _showLogoutDialog(), // Ubah dari async function jadi panggil dialog
                          icon: const Icon(Icons.logout, color: Colors.white),
                        ),
                      ],
                    ),
          ),
          ListTile(
            leading: const Icon(Icons.timelapse),
            title: const Text("History"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HistoryPage()),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Dark Mode",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Switch(
                  value: isDarkMode,
                  onChanged: (value) {
                    themeProvider.toggleTheme(value);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
