import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../services/plant_type_service.dart';
import '../services/user_plant_service.dart';
import '../services/daily_task_service.dart';
import '../provider/theme_provider.dart';
import '../screens/Homepage.dart';
import '../screens/progress.dart';
import '../screens/timeline_page.dart';
import '../screens/profil_page.dart';
import '../widgets/drawer.dart';

class OptionPage extends StatefulWidget {
  const OptionPage({Key? key}) : super(key: key);

  @override
  State<OptionPage> createState() => _OptionPageState();
}

class _OptionPageState extends State<OptionPage> with TickerProviderStateMixin {
  // Services
  final PlantService _plantTypeService = PlantService();
  final UserPlantService _userPlantService = UserPlantService();
  final DailyTaskService _dailyTaskService = DailyTaskService();
  final Uuid _uuid = Uuid();

  // Controllers
  final TextEditingController _searchController = TextEditingController();
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  // State variables
  int _selectedIndex = 2;
  bool _isLoading = false;
  bool _isLoadingPlants = true;
  String _errorMessage = '';
  List<Map<String, dynamic>> _plantTypes = [];
  List<Map<String, dynamic>> _filteredPlantTypes = [];
  String _searchQuery = '';

  // Constants
  static const Duration _animationDuration = Duration(milliseconds: 400);
  static const double _cardHeight = 140.0;
  static const double _searchBoxHeight = 56.0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeData();
    _setupListeners();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: _animationDuration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
  }

  void _initializeData() {
    _loadPlantTypes();
  }

  void _setupListeners() {
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    if (query != _searchQuery) {
      setState(() {
        _searchQuery = query;
        _filterPlants();
      });
    }
  }

  void _filterPlants() {
    if (_searchQuery.isEmpty) {
      _filteredPlantTypes = List.from(_plantTypes);
    } else {
      _filteredPlantTypes =
          _plantTypes.where((plant) {
            final name = (plant['name'] as String? ?? '').toLowerCase();
            final description =
                (plant['description'] as String? ?? '').toLowerCase();
            return name.contains(_searchQuery) ||
                description.contains(_searchQuery);
          }).toList();
    }
  }

  Future<void> _loadPlantTypes() async {
    try {
      setState(() {
        _isLoadingPlants = true;
        _errorMessage = '';
      });

      final plantTypes = await _plantTypeService.getAllPlantTypes();

      if (mounted) {
        setState(() {
          _plantTypes = plantTypes;
          _filteredPlantTypes = List.from(plantTypes);
          _isLoadingPlants = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _getErrorMessage(e);
          _isLoadingPlants = false;
        });
      }
    }
  }

  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('network') || errorStr.contains('connection')) {
      return 'Koneksi internet bermasalah. Silakan coba lagi.';
    } else if (errorStr.contains('timeout')) {
      return 'Waktu tunggu habis. Silakan coba lagi.';
    } else if (errorStr.contains('unauthorized')) {
      return 'Sesi Anda telah berakhir. Silakan login kembali.';
    } else {
      return 'Gagal memuat data tanaman. Silakan coba lagi.';
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() => _selectedIndex = index);

    Widget? destination;
    switch (index) {
      case 0:
        destination = HomePage();
        break;
      case 1:
        destination = const EnhancedProgress();
        break;
      case 3:
        destination = TimelinePage();
        break;
      case 4:
        destination = const ProfilPage();
        break;
      default:
        return;
    }

    if (destination != null) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => destination!,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeInOut),
              ),
              child: child,
            );
          },
          transitionDuration: _animationDuration,
        ),
      );
    }
  }

  Future<void> _savePlantSelection(
    Map<String, dynamic> plantType,
    String customName,
  ) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Generate unique ID
      final plantId = _uuid.v4();
      final plantTypeId = plantType['id'] as String;
      final startDate = DateTime.now();

      print('DEBUG: Starting plant creation with ID: $plantId'); // Debug log

      // Start planting using UserPlantService
      final result = await _userPlantService.startPlanting(
        id: plantId,
        userId: user.id,
        plantTypeId: plantTypeId,
        plantName: customName,
        startDate: startDate,
      );

      print('DEBUG: Plant created successfully: $result'); // Debug log

      // Generate daily tasks for the plant
      try {
        await _dailyTaskService.generateDailyTasksForPlant(plantId);
        print('DEBUG: Daily tasks generated successfully'); // Debug log
      } catch (e) {
        print('DEBUG: Error generating daily tasks: $e'); // Debug log
        // Jangan throw error jika daily tasks gagal, karena plant sudah tersimpan
        // Bisa ditangani secara terpisah atau diabaikan untuk sementara
      }

      if (mounted) {
        await _showSuccessDialog(customName, result);
      }
    } catch (e) {
      print('DEBUG: Error in _savePlantSelection: $e'); // Debug log
      print('DEBUG: Error type: ${e.runtimeType}'); // Debug log

      if (mounted) {
        setState(() {
          _errorMessage = _getPlantSelectionErrorMessage(e);
        });
        _showErrorDialog();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getPlantSelectionErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('duplicate') || errorStr.contains('already exists')) {
      return 'Tanaman dengan nama ini sudah ada dalam daftar Anda.';
    } else if (errorStr.contains('foreign key') ||
        errorStr.contains('not found')) {
      return 'Data tanaman tidak valid. Silakan refresh halaman.';
    } else if (errorStr.contains('unauthorized') ||
        errorStr.contains('not authenticated')) {
      return 'Sesi Anda telah berakhir. Silakan login kembali.';
    } else {
      return 'Gagal menambahkan tanaman. Silakan coba lagi.';
    }
  }

  Future<void> _showSuccessDialog(
    String plantName,
    Map<String, dynamic> plantData,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final isDarkMode =
            Provider.of<ThemeProvider>(context, listen: false).themeMode ==
            ThemeMode.dark;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 48,
            ),
          ),
          title: const Text(
            'Penanaman Dimulai!',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tanaman "$plantName" telah berhasil ditambahkan ke daftar tanam Anda.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Tanggal Mulai: ${DateTime.now().toString().split(' ')[0]}',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 16, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(
                          'Perkiraan Panen: ${plantData['expected_harvest_date']}',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Nanti'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EnhancedProgress(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Lihat Progress'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline, color: Colors.red, size: 48),
          ),
          title: const Text('Gagal Menambahkan Tanaman'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_errorMessage, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              const Text(
                'Silakan coba lagi atau hubungi support jika masalah berlanjut.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _loadPlantTypes();
              },
              child: const Text('Muat Ulang'),
            ),
          ],
        );
      },
    );
  }

  void _showPlantConfirmationDialog(Map<String, dynamic> plantType) {
    final TextEditingController _plantNameController = TextEditingController();
    _plantNameController.text = plantType['name'] as String;

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        final isDarkMode =
            Provider.of<ThemeProvider>(context, listen: false).themeMode ==
            ThemeMode.dark;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.eco, color: Colors.green, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Konfirmasi Penanaman',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Apakah Anda yakin ingin memulai penanaman ${plantType['name']}?',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),

                // Custom plant name input
                TextField(
                  controller: _plantNameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Tanaman Anda',
                    hintText: 'Berikan nama khusus untuk tanaman ini',
                    prefixIcon: Icon(Icons.local_florist),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 16),

                // Plant information card
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
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Informasi Tanaman',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (plantType['description'] != null) ...[
                        _buildInfoRow(
                          Icons.description,
                          'Deskripsi',
                          plantType['description'] as String,
                          isDarkMode,
                        ),
                        const SizedBox(height: 8),
                      ],

                      _buildInfoRow(
                        Icons.schedule,
                        'Masa Tanam',
                        '${plantType['growing_days'] ?? 30} hari',
                        isDarkMode,
                      ),
                      const SizedBox(height: 8),

                      _buildInfoRow(
                        Icons.calendar_today,
                        'Perkiraan Panen',
                        DateTime.now()
                            .add(
                              Duration(days: plantType['growing_days'] ?? 30),
                            )
                            .toString()
                            .split(' ')[0],
                        isDarkMode,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed:
                  _isLoading
                      ? null
                      : () {
                        if (_plantNameController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Nama tanaman tidak boleh kosong',
                              ),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          );
                          return;
                        }

                        Navigator.of(context).pop();
                        _savePlantSelection(
                          plantType,
                          _plantNameController.text.trim(),
                        );
                      },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child:
                  _isLoading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : const Text('Mulai Penanaman'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    bool isDarkMode,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
        final colorScheme = _getColorScheme(isDarkMode);

        return Scaffold(
          appBar: _buildAppBar(colorScheme, isDarkMode),
          drawer: DrawerPage(),
          body: _buildBody(colorScheme, isDarkMode),
          bottomNavigationBar: _buildBottomNavigationBar(
            colorScheme,
            isDarkMode,
          ),
        );
      },
    );
  }

  Map<String, Color> _getColorScheme(bool isDarkMode) {
    if (isDarkMode) {
      return {
        'appBar': Colors.grey[850]!,
        'background': Colors.grey[900]!,
        'surface': Colors.grey[800]!,
        'primary': Colors.green[400]!,
        'onPrimary': Colors.black,
        'onSurface': Colors.white,
        'onBackground': Colors.white,
        'searchBox': Colors.grey[700]!,
        'cardBackground': Colors.grey[800]!,
        'cardText': Colors.yellow[200]!,
        'accent': Colors.green[300]!,
      };
    } else {
      return {
        'appBar': const Color(0xFFA7B59E),
        'background': const Color(0xFFFFFFED),
        'surface': Colors.white,
        'primary': const Color(0xFF4CAF50),
        'onPrimary': Colors.white,
        'onSurface': Colors.black87,
        'onBackground': Colors.black87,
        'searchBox': const Color(0xFFD9D9D9),
        'cardBackground': const Color(0xFF49843E),
        'cardText': const Color(0xFFFFE880),
        'accent': const Color(0xFF66BB6A),
      };
    }
  }

  PreferredSizeWidget _buildAppBar(Map<String, Color> colors, bool isDarkMode) {
    return AppBar(
      backgroundColor: colors['appBar'],
      elevation: 0,
      iconTheme: IconThemeData(color: colors['onSurface']),
      centerTitle: true,
      title: Text(
        "Pilih Tanaman Anda",
        style: TextStyle(
          color: colors['onSurface'],
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _isLoadingPlants ? null : _loadPlantTypes,
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  Widget _buildBody(Map<String, Color> colors, bool isDarkMode) {
    return Container(
      color: colors['background'],
      child: Column(
        children: [
          _buildSearchSection(colors),
          Expanded(child: _buildPlantsSection(colors, isDarkMode)),
        ],
      ),
    );
  }

  Widget _buildSearchSection(Map<String, Color> colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Container(
        height: _searchBoxHeight,
        decoration: BoxDecoration(
          color: colors['searchBox'],
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: "Cari tanaman yang ingin ditanam...",
            hintStyle: TextStyle(
              color: colors['onSurface']?.withValues(alpha: 0.6),
              fontSize: 16,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: colors['onSurface']?.withValues(alpha: 0.6),
              size: 24,
            ),
            suffixIcon:
                _searchQuery.isNotEmpty
                    ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: colors['onSurface']?.withValues(alpha: 0.6),
                      ),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                    : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
          style: TextStyle(color: colors['onSurface'], fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildPlantsSection(Map<String, Color> colors, bool isDarkMode) {
    if (_isLoadingPlants) {
      return _buildLoadingWidget(colors);
    }

    if (_errorMessage.isNotEmpty) {
      return _buildErrorWidget(colors);
    }

    if (_filteredPlantTypes.isEmpty) {
      return _buildEmptyWidget(colors);
    }

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _filteredPlantTypes.length,
          itemBuilder: (context, index) {
            return AnimatedContainer(
              duration: Duration(milliseconds: 100 + (index * 50)),
              child: _buildPlantCard(
                _filteredPlantTypes[index],
                colors,
                isDarkMode,
                index,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingWidget(Map<String, Color> colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: colors['primary'], strokeWidth: 3),
          const SizedBox(height: 24),
          Text(
            'Memuat data tanaman...',
            style: TextStyle(color: colors['onBackground'], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(Map<String, Color> colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, size: 64, color: Colors.red),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Ada Masalah',
              style: TextStyle(
                color: colors['onBackground'],
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors['onBackground']?.withValues(alpha: 0.8),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadPlantTypes,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors['primary'],
                foregroundColor: colors['onPrimary'],
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget(Map<String, Color> colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors['primary']?.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _searchQuery.isEmpty ? Icons.eco : Icons.search_off,
                size: 64,
                color: colors['primary'],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isEmpty
                  ? 'Belum Ada Data Tanaman'
                  : 'Tidak Ditemukan',
              style: TextStyle(
                color: colors['onBackground'],
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isEmpty
                  ? 'Belum ada tanaman yang tersedia untuk ditanam'
                  : 'Tidak ada tanaman yang cocok dengan pencarian "${_searchQuery}"',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors['onBackground']?.withValues(alpha: 0.7),
                fontSize: 16,
              ),
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: () {
                  _searchController.clear();
                },
                icon: const Icon(Icons.clear),
                label: const Text('Hapus Pencarian'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build individual plant card
  Widget _buildPlantCard(
    Map<String, dynamic> plantType,
    Map<String, Color> colors,
    bool isDarkMode,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        elevation: isDarkMode ? 0 : 2,
        borderRadius: BorderRadius.circular(16),
        color: colors['cardBackground'],
        child: InkWell(
          onTap: () => _showPlantConfirmationDialog(plantType),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: _cardHeight,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildPlantIcon(plantType, colors, isDarkMode),
                const SizedBox(width: 16),
                Expanded(child: _buildPlantInfo(plantType, colors)),
                Icon(
                  Icons.arrow_forward_ios,
                  color: colors['cardText']?.withValues(alpha: 0.7),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build plant icon
  Widget _buildPlantIcon(
    Map<String, dynamic> plantType,
    Map<String, Color> colors,
    bool isDarkMode,
  ) {
    final imageUrl = plantType['image_url'] as String?;

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: colors['cardText']?.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child:
            imageUrl != null && imageUrl.isNotEmpty
                ? Image.asset(
                  'assets/images/$imageUrl', // Path ke folder assets
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback ke icon jika gambar tidak ditemukan
                    return Icon(Icons.eco, color: colors['cardText'], size: 28);
                  },
                )
                : Icon(Icons.eco, color: colors['cardText'], size: 28),
      ),
    );
  }

  /// Build plant information
  Widget _buildPlantInfo(
    Map<String, dynamic> plantType,
    Map<String, Color> colors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          plantType['name'] as String? ?? 'Unknown Plant',
          style: TextStyle(
            color: colors['cardText'],
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (plantType['description'] != null) ...[
          const SizedBox(height: 4),
          Text(
            plantType['description'] as String,
            style: TextStyle(
              color: colors['cardText']?.withValues(alpha: 0.8),
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 4),
        Text(
          "Masa tanam: ${plantType['growing_days'] ?? 30} hari",
          style: TextStyle(
            color: colors['cardText']?.withValues(alpha: 0.6),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Build bottom navigation bar
  Widget _buildBottomNavigationBar(Map<String, Color> colors, bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        backgroundColor: colors['surface'],
        selectedItemColor: colors['primary'],
        unselectedItemColor: colors['onSurface']?.withValues(alpha: 0.6),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
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
}
