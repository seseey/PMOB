import 'package:flutter/material.dart';
import 'progress.dart';
import 'timeline_page.dart';
import 'history_page.dart';
import 'package:provider/provider.dart';
import '../widgets/drawer.dart';
import 'option_page.dart';
import 'profil_page.dart';
import '../provider/theme_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sign_in.dart';
import 'package:url_launcher/url_launcher.dart'; // Add this import

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final supabase = Supabase.instance.client;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;

      if (index == 2) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => OptionPage()),
        );
      }
      if (index == 1) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => EnhancedProgress()),
        );
      }
      if (index == 3) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TimelinePage()),
        );
      }
      if (index == 4) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProfilPage()),
        );
      }
    });
  }

  Future<void> logout(BuildContext context) async {
    try {
      // Logout dari Supabase
      await supabase.auth.signOut();

      // Hapus login time dari SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('login_time');

      // Navigasi ke SignIn
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SignIn()),
        );
      }
    } catch (e) {
      print("Error saat logout: $e");
    }
  }

  // Fungsi untuk check session validity (opsional)
  Future<bool> isSessionValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final loginTime = prefs.getInt('login_time') ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final sessionDuration = 120 * 60 * 1000; // 120 menit

      return currentTime - loginTime < sessionDuration;
    } catch (e) {
      return false;
    }
  }

  // Add this function to launch URL
  Future<void> _launchURL() async {
    final Uri url = Uri.parse('https://hydroponicgrow.my.id/');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        // Show error message if URL can't be launched
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tidak dapat membuka website'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Handle any errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: Tidak dapat membuka website'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final customMaterialColor = MaterialColor(0xFF4CAF50, colorCodes);

    // Get screen dimensions
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final isSmallScreen = screenWidth < 360;
    final isMediumScreen = screenWidth >= 360 && screenWidth < 600;

    final backgroundColor = isDarkMode ? Colors.grey[900]! : Color(0xFFF9F6EE);
    final appBarColor = isDarkMode ? Colors.grey[850]! : Color(0xFFA7B59E);
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final buttonColor = isDarkMode ? Colors.blueGrey : Colors.yellow[700]!;
    final gradientStart =
        isDarkMode ? Colors.blueGrey[800]! : Color(0xFFFFC300);
    final gradientEnd = isDarkMode ? Colors.blueGrey[600]! : Color(0xFFFFEA00);

    // Responsive sizing
    final headerFontSize =
        isSmallScreen ? 16.0 : (isMediumScreen ? 18.0 : 20.0);
    final subtitleFontSize = isSmallScreen ? 12.0 : 14.0;
    final imageHeight = screenHeight * 0.2;
    final buttonWidth = screenWidth * 0.25;
    final buttonHeight = screenHeight * 0.12;
    final horizontalPadding = screenWidth * 0.04;

    return Scaffold(
      backgroundColor: backgroundColor, // Add this line
      appBar: AppBar(
        backgroundColor: appBarColor,
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      drawer: DrawerPage(),
      body: Container(
        color: backgroundColor,
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header Section
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: isSmallScreen ? 25 : 30,
                    backgroundImage: AssetImage("assets/images/logo.png"),
                  ),
                  title: Text(
                    "Hello Higrowers!",
                    style: TextStyle(
                      fontSize: headerFontSize,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  subtitle: Text(
                    "Welcome to Hydroponic Grow",
                    style: TextStyle(
                      fontSize: subtitleFontSize,
                      fontStyle: FontStyle.italic,
                      color: textColor,
                    ),
                  ),
                ),

                SizedBox(height: screenHeight * 0.02),

                // Main Image
                Center(
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: imageHeight,
                      maxWidth: screenWidth * 0.8,
                    ),
                    child: Image.asset(
                      'assets/images/nature1.png',
                      fit: BoxFit.contain,
                      color: isDarkMode ? Colors.white.withOpacity(0.8) : null,
                      colorBlendMode: BlendMode.modulate,
                    ),
                  ),
                ),

                SizedBox(height: screenHeight * 0.03),

                // Menu Buttons
                LayoutBuilder(
                  builder: (context, constraints) {
                    final availableWidth = constraints.maxWidth;
                    final buttonSpacing = isSmallScreen ? 10.0 : 30.0;
                    final runSpacing = isSmallScreen ? 10.0 : 15.0;

                    return Wrap(
                      spacing: buttonSpacing,
                      runSpacing: runSpacing,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildMenuButton(
                          context: context,
                          width: buttonWidth,
                          height: buttonHeight,
                          gradientStart: gradientStart,
                          gradientEnd: gradientEnd,
                          textColor: textColor,
                          icon: Icons.add,
                          label: "Tambah Tanaman",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OptionPage(),
                              ),
                            );
                          },
                          isSmallScreen: isSmallScreen,
                        ),
                        _buildMenuButton(
                          context: context,
                          width: buttonWidth,
                          height: buttonHeight,
                          gradientStart: gradientStart,
                          gradientEnd: gradientEnd,
                          textColor: textColor,
                          icon: Icons.calendar_month,
                          label: "Kalender Panen",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TimelinePage(),
                              ),
                            );
                          },
                          isSmallScreen: isSmallScreen,
                        ),
                        _buildMenuButton(
                          context: context,
                          width: buttonWidth,
                          height: buttonHeight,
                          gradientStart: gradientStart,
                          gradientEnd: gradientEnd,
                          textColor: textColor,
                          icon: Icons.history,
                          label: "History tanaman",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HistoryPage(),
                              ),
                            );
                          },
                          isSmallScreen: isSmallScreen,
                        ),
                      ],
                    );
                  },
                ),

                SizedBox(height: screenHeight * 0.05),

                // Description Text
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                  child: Text(
                    "Baca Artikel, Tonton Video, Sharing Komunitas Seputar Metode Menanam Hidroponik",
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14.0 : 16.0,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                  ),
                ),

                SizedBox(height: screenHeight * 0.03),

                // Website Button - Updated with URL functionality
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.05,
                        vertical: 12,
                      ),
                    ),
                    onPressed: _launchURL, // Updated to call the URL function
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            "Kunjungi Website",
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: isSmallScreen ? 12.0 : 14.0,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward,
                          color: isDarkMode ? Colors.white : Colors.black,
                          size: isSmallScreen ? 16.0 : 20.0,
                        ),
                      ],
                    ),
                  ),
                ),

                // Removed the extra SizedBox here that caused white space
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
        selectedItemColor: customMaterialColor,
        unselectedItemColor: isDarkMode ? Colors.grey[400] : Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        iconSize: isSmallScreen ? 20.0 : 24.0,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.note_add), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ""),
        ],
      ),
    );
  }

  Widget _buildMenuButton({
    required BuildContext context,
    required double width,
    required double height,
    required Color gradientStart,
    required Color gradientEnd,
    required Color textColor,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isSmallScreen,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        padding: EdgeInsets.symmetric(
          vertical: isSmallScreen ? 8 : 15,
          horizontal: 8,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [gradientStart, gradientEnd],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: isSmallScreen ? 28 : 35, color: textColor),
            SizedBox(height: isSmallScreen ? 4 : 8),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isSmallScreen ? 10 : 12,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                maxLines: 2,
                softWrap: true,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
