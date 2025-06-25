import 'package:flutter/material.dart';
import 'package:hydroponicgrowv2/screens/option_page.dart';
import 'package:hydroponicgrowv2/screens/profil_page.dart';
import 'HomePage.dart';
import 'package:provider/provider.dart';
import 'package:hydroponicgrowv2/provider/theme_provider.dart';
import 'package:hydroponicgrowv2/widgets/drawer.dart';
import 'package:hydroponicgrowv2/screens/progress.dart';
import 'package:hydroponicgrowv2/services/timeline_service.dart';

class TimelinePage extends StatefulWidget {
  final String? userPlantId;
  final String? plantName;

  TimelinePage({Key? key, this.userPlantId, this.plantName}) : super(key: key);

  @override
  _TimelinePageState createState() => _TimelinePageState();
}

class _TimelinePageState extends State<TimelinePage> {
  int _selectedIndex = 3;
  int _selectedDay = -1;
  bool _isLoading = true;
  String _error = '';

  List<Map<String, dynamic>> _userPlants = [];
  String? _selectedPlantId;
  bool _isLoadingPlants = false;

  // Timeline data
  Map<String, dynamic> _timelineMetrics = {};
  List<Map<String, dynamic>> _dailyProgress = [];
  Map<int, Map<String, dynamic>> _progressMap = {};

  final TimelineService _timelineService = TimelineService();

  @override
  void initState() {
    super.initState();
    _loadUserPlants();
  }

  Future<void> _loadUserPlants() async {
    try {
      setState(() {
        _isLoadingPlants = true;
        _error = '';
      });

      // Get current user ID
      String? userId = await _timelineService.getCurrentUserId();
      if (userId == null) {
        // Fallback untuk testing
        userId = "a1b2c3d4-e5f6-7890-abcd-ef1234567890";
      }

      print('Loading plants for user: $userId');

      // Load all user plants using TimelineService
      _userPlants = await _timelineService.getUserPlantsForTimeline(userId);

      print('Found ${_userPlants.length} user plants');
      for (var plant in _userPlants) {
        print(
          'Plant: ${plant['id']} - ${plant['plant_types']?['name']} - Status: ${plant['status']}', // GANTI 'plants' menjadi 'plant_types'
        );
      }

      if (_userPlants.isNotEmpty) {
        // Set selected plant - prioritas widget.userPlantId jika ada
        if (widget.userPlantId != null && widget.userPlantId!.isNotEmpty) {
          // Cek apakah userPlantId ada di list
          bool plantExists = _userPlants.any(
            (plant) => plant['id'] == widget.userPlantId,
          );
          if (plantExists) {
            _selectedPlantId = widget.userPlantId;
            print('Using provided plant ID: $_selectedPlantId');
          } else {
            print('Provided plant ID not found in user plants, using fallback');
            _selectedPlantId = _userPlants.first['id'];
          }
        } else {
          // Get most recent active plant
          String? activePlantId = await _timelineService
              .getMostRecentActivePlant(userId);
          _selectedPlantId = activePlantId ?? _userPlants.first['id'];
          print('Using most recent/first plant: $_selectedPlantId');
        }

        setState(() {
          _isLoadingPlants = false;
        });

        await _loadTimelineData();
      } else {
        print('No user plants found');
        setState(() {
          _isLoading = false;
          _isLoadingPlants = false;
          _error = 'Belum ada tanaman yang ditanam';
        });
      }
    } catch (e) {
      print('Error loading user plants: $e');
      setState(() {
        _isLoading = false;
        _isLoadingPlants = false;
        _error = 'Gagal memuat data tanaman: ${e.toString()}';
      });
    }
  }

  Future<void> _onPlantChanged(String? newPlantId) async {
    if (newPlantId == null || newPlantId == _selectedPlantId) return;

    setState(() {
      _selectedPlantId = newPlantId;
      _selectedDay = -1; // Reset selected day
      _isLoading = true;
    });

    await _loadTimelineData();
  }

  Future<void> _loadTimelineData() async {
    if (_selectedPlantId == null) {
      print('No selected plant ID');
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      print('Loading timeline for Plant ID: $_selectedPlantId');

      // Use TimelineService to get all data efficiently
      final timelineData = await _timelineService.getTimelineData(
        _selectedPlantId!,
      );

      print('Raw timeline data received:');
      print('UserPlant: ${timelineData['userPlant']}');
      print(
        'DailyProgress count: ${timelineData['dailyProgress']?.length ?? 0}',
      );

      final userPlant = timelineData['userPlant'];
      _dailyProgress = List<Map<String, dynamic>>.from(
        timelineData['dailyProgress'] ?? [],
      );

      // Calculate metrics using TimelineService
      _timelineMetrics = _timelineService.calculateTimelineMetrics(
        userPlant,
        _dailyProgress,
      );
      _progressMap = Map<int, Map<String, dynamic>>.from(
        _timelineMetrics['progressMap'] ?? {},
      );

      print('Timeline metrics calculated:');
      print('Current Day: ${_timelineMetrics['currentDay']}');
      print('Total Days: ${_timelineMetrics['totalDays']}');
      print('Status: ${_timelineMetrics['status']}');
      print('Plant Name: ${_timelineMetrics['plantName']}');
      print('Progress Map Keys: ${_progressMap.keys.toList()}');

      print('Loaded ${_dailyProgress.length} progress records');

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error in _loadTimelineData: $e');
      print('Stack trace: ${StackTrace.current}');
      setState(() {
        _isLoading = false;
        _error = 'Gagal memuat data timeline: ${e.toString()}';
      });
    }
  }

  Color _getDayColor(int dayNumber, bool isDarkMode) {
    final hasProgress = _progressMap.containsKey(dayNumber);
    final currentDay = _timelineMetrics['currentDay'] ?? 1;
    final status = _timelineMetrics['status'] ?? 'planting';
    final totalDays = _timelineMetrics['totalDays'] ?? 30;

    final isCurrentDay = dayNumber == currentDay;
    final isPastDay = dayNumber < currentDay;
    final isFutureDay = dayNumber > currentDay;

    // Special handling for harvested/failed plants
    if (status == 'harvested' && dayNumber <= totalDays) {
      if (hasProgress) {
        final progress = _progressMap[dayNumber]!;
        final completionPercentage =
            progress['overall_completion_percentage'] ?? 0;

        if (completionPercentage >= 80) {
          return isDarkMode ? Colors.green[600]! : Colors.green[600]!;
        } else if (completionPercentage >= 50) {
          return isDarkMode ? Colors.orange[600]! : Colors.orange[600]!;
        } else {
          return isDarkMode ? Colors.red[600]! : Colors.red[600]!;
        }
      } else {
        return isDarkMode ? Colors.grey[700]! : Colors.grey[600]!;
      }
    }

    if (status == 'failed') {
      return isDarkMode ? Colors.red[800]! : Colors.red[700]!;
    }

    if (isCurrentDay && status == 'planting') {
      return isDarkMode ? Colors.green[600]! : Colors.green[700]!;
    } else if (isPastDay && hasProgress) {
      final progress = _progressMap[dayNumber]!;
      final completionPercentage =
          progress['overall_completion_percentage'] ?? 0;

      if (completionPercentage >= 80) {
        return isDarkMode ? Colors.green[600]! : Colors.green[600]!;
      } else if (completionPercentage >= 50) {
        return isDarkMode ? Colors.orange[600]! : Colors.orange[600]!;
      } else {
        return isDarkMode ? Colors.red[600]! : Colors.red[600]!;
      }
    } else if (isPastDay) {
      return isDarkMode ? Colors.grey[700]! : Colors.grey[600]!;
    } else {
      return isDarkMode ? Colors.grey[600]! : Colors.grey[500]!;
    }
  }

  String _getDayStatus(int dayNumber) {
    final hasProgress = _progressMap.containsKey(dayNumber);
    final currentDay = _timelineMetrics['currentDay'] ?? 1;
    final status = _timelineMetrics['status'] ?? 'planting';
    final totalDays = _timelineMetrics['totalDays'] ?? 30;

    final isCurrentDay = dayNumber == currentDay;
    final isPastDay = dayNumber < currentDay;

    if (status == 'harvested' && dayNumber <= totalDays) {
      if (hasProgress) {
        final progress = _progressMap[dayNumber]!;
        final completionPercentage =
            progress['overall_completion_percentage'] ?? 0;
        return "Selesai $completionPercentage%";
      } else {
        return "Tidak Ada Data";
      }
    }

    if (status == 'failed') {
      return "Gagal";
    }

    if (isCurrentDay && status == 'planting') {
      return "Hari Ini";
    } else if (isPastDay && hasProgress) {
      final progress = _progressMap[dayNumber]!;
      final completionPercentage =
          progress['overall_completion_percentage'] ?? 0;
      return "Selesai $completionPercentage%";
    } else if (isPastDay) {
      return "Tidak Ada Data";
    } else {
      return "Akan Datang";
    }
  }

  Widget _buildPlantDropdown() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.eco, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text(
                "Pilih Tanaman",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${_userPlants.length} tanaman",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          // Dropdown dengan styling sederhana
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(
                color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
              ),
              borderRadius: BorderRadius.circular(8),
              color: isDarkMode ? Colors.grey[700] : Colors.grey[50],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedPlantId,
                isExpanded: true,
                hint: Text(
                  "Pilih tanaman...",
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                dropdownColor: isDarkMode ? Colors.grey[700] : Colors.white,
                menuMaxHeight: 300,
                items:
                    _userPlants.map<DropdownMenuItem<String>>((plant) {
                      final plantName =
                          plant['plant_types']?['name'] ?? 'Tanaman';
                      final customName = plant['plant_name'];
                      final startDate = DateTime.parse(plant['start_date']);
                      final status = plant['status'] ?? 'planting';

                      String displayName =
                          customName != null && customName.isNotEmpty
                              ? customName
                              : plantName;

                      // Hitung hari
                      final daysSinceStart =
                          DateTime.now().difference(startDate).inDays + 1;
                      String statusText;
                      Color statusColor;

                      switch (status) {
                        case 'harvested':
                          statusText = 'Dipanen';
                          statusColor = Colors.green;
                          break;
                        case 'failed':
                          statusText = 'Gagal';
                          statusColor = Colors.red;
                          break;
                        default:
                          statusText = 'Hari $daysSinceStart';
                          statusColor = Colors.blue;
                      }

                      return DropdownMenuItem<String>(
                        value: plant['id'],
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              // Status indicator (bulat kecil)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 10),

                              // Plant name
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      displayName,
                                      style: TextStyle(
                                        color:
                                            isDarkMode
                                                ? Colors.white
                                                : Colors.black87,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (customName != null &&
                                        customName.isNotEmpty &&
                                        customName != plantName) ...[
                                      SizedBox(height: 1),
                                      Text(
                                        plantName,
                                        style: TextStyle(
                                          color:
                                              isDarkMode
                                                  ? Colors.grey[400]
                                                  : Colors.grey[600],
                                          fontSize: 11,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              SizedBox(width: 8),

                              // Status text
                              Text(
                                statusText,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                onChanged: _isLoadingPlants ? null : _onPlantChanged,
              ),
            ),
          ),

          // Info tanaman terpilih
          if (_selectedPlantId != null) ...[
            SizedBox(height: 12),
            _buildSelectedPlantInfo(),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectedPlantInfo() {
    final selectedPlant = _userPlants.firstWhere(
      (plant) => plant['id'] == _selectedPlantId,
      orElse: () => {},
    );

    if (selectedPlant.isEmpty) return SizedBox.shrink();

    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    final startDate = DateTime.parse(selectedPlant['start_date']);
    final expectedHarvestDate = selectedPlant['expected_harvest_date'];
    final actualHarvestDate = selectedPlant['actual_harvest_date'];
    final status = selectedPlant['status'] ?? 'planting';

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[750] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header simpel
          Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: Colors.blue),
              SizedBox(width: 6),
              Text(
                "Info Tanaman",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),

          // Info rows sederhana
          _buildSimpleInfoRow(
            "Mulai tanam",
            _formatDate(startDate),
            isDarkMode,
          ),
          if (expectedHarvestDate != null)
            _buildSimpleInfoRow(
              "Target panen",
              _formatDate(DateTime.parse(expectedHarvestDate)),
              isDarkMode,
            ),
          if (status == 'harvested' && actualHarvestDate != null)
            _buildSimpleInfoRow(
              "Dipanen",
              _formatDate(DateTime.parse(actualHarvestDate)),
              isDarkMode,
              Colors.green,
            ),
        ],
      ),
    );
  }

  Widget _buildSimpleInfoRow(
    String label,
    String value,
    bool isDarkMode, [
    Color? valueColor,
  ]) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              "$label:",
              style: TextStyle(
                fontSize: 11,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                color:
                    valueColor ??
                    (isDarkMode ? Colors.grey[300] : Colors.grey[700]),
                fontWeight:
                    valueColor != null ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantStatusCard() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final buttonColor = isDarkMode ? Colors.green[800]! : Color(0xFF527A32);

    final status = _timelineMetrics['status'] ?? 'planting';
    final currentDay = _timelineMetrics['currentDay'] ?? 1;
    final totalDays = _timelineMetrics['totalDays'] ?? 30;
    final plantName =
        _timelineMetrics['plantName'] ?? widget.plantName ?? 'Tanaman';
    final expectedHarvestDate = _timelineMetrics['expectedHarvestDate'];

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'harvested':
        statusColor = Colors.green;
        statusText = 'Sudah Dipanen';
        statusIcon = Icons.agriculture;
        break;
      case 'failed':
        statusColor = Colors.red;
        statusText = 'Gagal';
        statusIcon = Icons.error;
        break;
      default:
        statusColor = Colors.blue;
        statusText = 'Sedang Ditanam';
        statusIcon = Icons.eco;
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: buttonColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(statusIcon, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  plantName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            status == 'planting'
                ? "Hari $currentDay dari $totalDays"
                : status == 'harvested'
                ? "Dipanen pada hari $totalDays"
                : "Gagal pada hari $currentDay",
            style: TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          if (expectedHarvestDate != null) ...[
            SizedBox(height: 4),
            Text(
              "Target panen: ${_formatDate(DateTime.parse(expectedHarvestDate))}",
              style: TextStyle(color: Colors.white70, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
          // HAPUS bagian Plant ID - tidak ditampilkan lagi
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ags',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return "${date.day} ${months[date.month - 1]} ${date.year}";
  }

  Widget _buildDayProgressDetail() {
    if (_selectedDay == -1) {
      return Container(
        padding: EdgeInsets.all(16),
        child: Text(
          "Pilih hari untuk melihat detail progress",
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      );
    }

    final hasProgress = _progressMap.containsKey(_selectedDay);
    final currentDay = _timelineMetrics['currentDay'] ?? 1;
    final status = _timelineMetrics['status'] ?? 'planting';
    final isCurrentDay = _selectedDay == currentDay && status == 'planting';

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Hari $_selectedDay",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Chip(
                label: Text(
                  _getDayStatus(_selectedDay),
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
                backgroundColor: _getDayColor(
                  _selectedDay,
                  Theme.of(context).brightness == Brightness.dark,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          if (hasProgress) ...[
            _buildProgressStats(_progressMap[_selectedDay]!),
          ] else if (isCurrentDay) ...[
            Text(
              "Hari ini belum ada progress yang tercatat.",
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                _navigateToTasks();
              },
              child: Text("Mulai Aktivitas Hari Ini"),
            ),
          ] else ...[
            Text(
              _getNoProgressMessage(_selectedDay),
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }

  String _getNoProgressMessage(int dayNumber) {
    final status = _timelineMetrics['status'] ?? 'planting';
    final currentDay = _timelineMetrics['currentDay'] ?? 1;

    if (status == 'failed') {
      return "Tanaman gagal tumbuh.";
    } else if (status == 'harvested') {
      return "Tanaman sudah dipanen.";
    } else if (dayNumber < currentDay) {
      return "Tidak ada data untuk hari ini.";
    } else {
      return "Hari ini belum tiba.";
    }
  }

  Widget _buildProgressStats(Map<String, dynamic> progress) {
    final totalTasks = progress['total_tasks'] ?? 0;
    final completedTasks = progress['completed_tasks'] ?? 0;
    final totalAccuracy = progress['total_accuracy_checks'] ?? 0;
    final completedAccuracy = progress['completed_accuracy_checks'] ?? 0;
    final overallCompletion = progress['overall_completion_percentage'] ?? 0;
    final notes = progress['notes'] as String?;
    final progressDate = progress['progress_date'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (progressDate != null) ...[
          Text(
            "Tanggal: ${_formatDate(DateTime.parse(progressDate))}",
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          SizedBox(height: 8),
        ],

        // Overall Progress
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Progress Keseluruhan",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              "$overallCompletion%",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        SizedBox(height: 4),
        LinearProgressIndicator(
          value: overallCompletion / 100,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            overallCompletion >= 80
                ? Colors.green
                : overallCompletion >= 50
                ? Colors.orange
                : Colors.red,
          ),
        ),
        SizedBox(height: 16),

        // Task Progress
        Row(
          children: [
            Icon(Icons.task_alt, size: 20, color: Colors.blue),
            SizedBox(width: 8),
            Text("Tugas: $completedTasks/$totalTasks selesai"),
          ],
        ),
        SizedBox(height: 8),

        // Accuracy Check Progress
        Row(
          children: [
            Icon(Icons.check_circle, size: 20, color: Colors.green),
            SizedBox(width: 8),
            Text("Pengecekan: $completedAccuracy/$totalAccuracy selesai"),
          ],
        ),

        if (notes != null && notes.isNotEmpty) ...[
          SizedBox(height: 16),
          Text("Catatan:", style: TextStyle(fontWeight: FontWeight.w600)),
          SizedBox(height: 4),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(notes),
          ),
        ],
      ],
    );
  }

  void _navigateToTasks() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EnhancedProgress()),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => EnhancedProgress()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => OptionPage()),
        );
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProfilPage()),
        );
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    final backgroundColor = isDarkMode ? Colors.grey[900]! : Color(0xFFF6F6E9);
    final appBarColor = isDarkMode ? Colors.grey[850]! : Color(0xFFA7B59E);
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final timelineBgColor = isDarkMode ? Colors.grey[800]! : Color(0xFFF2D275);
    final navBarColor = isDarkMode ? Colors.grey[850]! : Colors.white;
    final navIconColor = isDarkMode ? Colors.green[200]! : Colors.green;

    if (_isLoadingPlants || _isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: appBarColor,
          title: Text("Timeline", style: TextStyle(color: textColor)),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                _isLoadingPlants
                    ? "Memuat daftar tanaman..."
                    : "Memuat data timeline...",
              ),
            ],
          ),
        ),
      );
    }

    if (_error.isNotEmpty) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: appBarColor,
          title: Text("Timeline", style: TextStyle(color: textColor)),
          centerTitle: true,
          actions: [
            IconButton(icon: Icon(Icons.refresh), onPressed: _loadUserPlants),
          ],
        ),
        drawer: DrawerPage(),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  _error,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadUserPlants,
                  child: Text("Coba Lagi"),
                ),
                SizedBox(height: 8),
                Text(
                  "Debug Info:",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Selected Plant ID: $_selectedPlantId",
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
                Text(
                  "User Plants Count: ${_userPlants.length}",
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentDay = _timelineMetrics['currentDay'] ?? 1;
    final totalDays = _timelineMetrics['totalDays'] ?? 30;
    final plantName =
        _timelineMetrics['plantName'] ?? widget.plantName ?? 'Tanaman';

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        title: Text("Timeline $plantName", style: TextStyle(color: textColor)),
        centerTitle: true,
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _loadTimelineData),
        ],
      ),
      drawer: DrawerPage(),
      body: RefreshIndicator(
        onRefresh: _loadTimelineData,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (_userPlants.length > 1) _buildPlantDropdown(),

              // Enhanced Plant Status Card
              _buildPlantStatusCard(),

              SizedBox(height: 24),

              // Timeline Calendar
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: timelineBgColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      "Timeline Progress",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 8.0,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: totalDays,
                      itemBuilder: (context, index) {
                        final dayNumber = index + 1;
                        final isSelected = _selectedDay == dayNumber;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDay = dayNumber;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: _getDayColor(dayNumber, isDarkMode),
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  isSelected
                                      ? Border.all(
                                        color: Colors.white,
                                        width: 3,
                                      )
                                      : null,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                dayNumber.toString(),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Day Progress Detail
              _buildDayProgressDetail(),

              SizedBox(height: 24),

              // Enhanced Legend
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Keterangan:",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    if (_timelineMetrics['status'] == 'planting') ...[
                      _buildLegendItem(Colors.green[700]!, "Hari Ini"),
                    ],
                    _buildLegendItem(Colors.green[600]!, "Berhasil (≥80%)"),
                    _buildLegendItem(Colors.orange[600]!, "Sedang (50-79%)"),
                    _buildLegendItem(Colors.red[600]!, "Kurang (<50%)"),
                    _buildLegendItem(Colors.grey[600]!, "Belum Ada Data"),
                    if (_timelineMetrics['status'] == 'failed') ...[
                      _buildLegendItem(Colors.red[800]!, "Tanaman Gagal"),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: navBarColor,
        selectedItemColor: navIconColor,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
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

  Widget _buildLegendItem(Color color, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            color: color,
            margin: EdgeInsets.only(right: 8),
          ),
          Text(text),
        ],
      ),
    );
  }
}
