import 'package:flutter/material.dart';
import 'package:hydroponicgrowv2/screens/option_page.dart';
import 'package:hydroponicgrowv2/screens/progress.dart';
import 'package:hydroponicgrowv2/screens/timeline_page.dart';
import 'package:provider/provider.dart';
import '../widgets/drawer.dart';
import 'HomePage.dart';
import 'change_username.dart';
import 'change_password.dart';
import 'sign_in.dart';
import '../provider/theme_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import 'change_photo.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({Key? key}) : super(key: key);

  @override
  _ProfilPageState createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  final Map<int, Color> colorCodes = {
    50: Color.fromRGBO(76, 175, 80, 0.1),
    100: Color.fromRGBO(76, 175, 80, 0.2),
    200: Color.fromRGBO(68, 177, 72, 0.302),
    300: Color.fromRGBO(76, 175, 80, 0.4),
    400: Color.fromRGBO(76, 175, 80, 0.5),
    500: Color.fromRGBO(76, 175, 80, 0.6),
    600: Color.fromRGBO(76, 175, 80, 0.7),
    700: Color.fromRGBO(76, 175, 80, 0.8),
    800: Color.fromRGBO(76, 175, 80, 0.9),
    900: Color.fromRGBO(76, 175, 80, 1.0),
  };

  bool isLoading = false;
  String errorMessage = '';
  int _selectedIndex = 4;

  User? currentUser;
  String? currentPhotoUrl;
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserAndProfile();
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
                Navigator.of(context).pop();
                await Supabase.instance.client.auth.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const SignIn()),
                );
              },
              child: Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
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

          userData = response as Map<String, dynamic>;

          if (userData != null) {
            currentPhotoUrl = userData!['profile_photo'] as String?;
          }
        } catch (e) {
          // Jika user tidak ditemukan di database
          if (e.toString().contains('0 rows') ||
              e.toString().contains('PGRST116')) {
            errorMessage =
                'User profile not found. Please contact support or try logging in again.';
          } else {
            throw e;
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomePage()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const EnhancedProgress()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => OptionPage()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => TimelinePage()),
        );
        break;
      case 4:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final customMaterialColor = MaterialColor(0xFF4CAF50, colorCodes);

    final backgroundColor =
        isDarkMode ? Colors.grey[900]! : const Color(0xFFF9F6EE);
    final appBarColor =
        isDarkMode ? Colors.grey[850]! : const Color(0xFFA7B59E);
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final boxColor = isDarkMode ? Colors.grey[800]! : const Color(0xCC2E8B57);
    final errorColor = isDarkMode ? Colors.red[300]! : Colors.red;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: appBarColor,
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      drawer: DrawerPage(),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : errorMessage.isNotEmpty
              ? Center(
                child: Text(errorMessage, style: TextStyle(color: errorColor)),
              )
              : Container(
                color: backgroundColor,
                child: Column(
                  children: [
                    const SizedBox(height: 56),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => ChangeProfilePhotoPage(
                                      currentPhotoUrl: currentPhotoUrl,
                                    ),
                              ),
                            ).then((result) {
                              // Panggil fetch data
                              _fetchCurrentUserAndProfile();

                              // Update currentPhotoUrl jika ada hasil
                              if (result != null) {
                                setState(() {
                                  currentPhotoUrl = result;
                                });
                              }
                            });
                          },
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundImage:
                                    userData != null &&
                                            userData!['profile_photo'] != null
                                        ? NetworkImage(
                                          userData!['profile_photo'],
                                        )
                                        : const AssetImage('images/default.jpg')
                                            as ImageProvider,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                userData?['username'] ?? 'Belum ada username',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          _buildEmailBox(boxColor, textColor),
                          const SizedBox(height: 32),
                          _buildUsernameBox(boxColor, textColor),
                          const SizedBox(height: 32),
                          _buildPasswordBox(boxColor, textColor),
                          const SizedBox(height: 32),
                          _buildLogoutBox(boxColor, textColor),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
        selectedItemColor: customMaterialColor,
        unselectedItemColor: isDarkMode ? Colors.grey[400] : Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.note_add), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ""),
        ],
      ),
    );
  }

  Widget _buildEmailBox(Color boxColor, Color textColor) {
    return Container(
      width: double.infinity,
      height: 90,
      decoration: BoxDecoration(
        color: boxColor,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Email",
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            userData?['email'] ?? currentUser?.email ?? "No email",
            style: TextStyle(color: textColor, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildUsernameBox(Color boxColor, Color textColor) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChangeUsernamePage()),
        ).then((_) => _fetchCurrentUserAndProfile());
      },
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          color: boxColor,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(
              "Change Username",
              style: TextStyle(color: textColor, fontSize: 16),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, color: textColor, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordBox(Color boxColor, Color textColor) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChangePasswordPage()),
        );
      },
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          color: boxColor,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(
              "Change Password",
              style: TextStyle(color: textColor, fontSize: 16),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, color: textColor, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutBox(Color boxColor, Color textColor) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showLogoutDialog(), // Ubah ini - panggil dialog
        splashColor: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            color: boxColor,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text("Logout", style: TextStyle(color: textColor, fontSize: 16)),
              const Spacer(),
              Icon(Icons.logout, color: textColor),
            ],
          ),
        ),
      ),
    );
  }
}
