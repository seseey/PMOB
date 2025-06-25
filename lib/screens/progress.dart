import 'package:flutter/material.dart';
import 'package:hydroponicgrowv2/screens/option_page.dart';
import 'package:hydroponicgrowv2/screens/profil_page.dart';
import 'package:hydroponicgrowv2/screens/HomePage.dart';
import 'package:hydroponicgrowv2/screens/timeline_page.dart';
import 'package:hydroponicgrowv2/screens/taskpage.dart';
import 'package:hydroponicgrowv2/screens/accuracy.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import '../provider/theme_provider.dart';
import '../widgets/drawer.dart';
import '../services/daily_task_service.dart';
import '../services/user_plant_service.dart';
import '../services/daily_progress_service.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class EnhancedProgress extends StatefulWidget {
  const EnhancedProgress({super.key});

  @override
  State<EnhancedProgress> createState() => _EnhancedProgressState();
}

class _EnhancedProgressState extends State<EnhancedProgress>
    with TickerProviderStateMixin {
  // Services
  final DailyTaskService _dailyTaskService = DailyTaskService();
  final UserPlantService _userPlantService = UserPlantService();
  final DailyProgressService _dailyProgressService = DailyProgressService();
  AnimationController? _progressController;
  Animation<double>? progressAnimation;

  final supabase = Supabase.instance.client;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Uuid _uuid = const Uuid();

  // Animation Controllers
  late AnimationController _progressAnimationController;
  late AnimationController _cardAnimationController;
  late AnimationController _chartAnimationController;
  late AnimationController _menuAnimationController;
  late Animation<double> _progressAnimation;
  late Animation<double> _cardAnimation;
  late Animation<double> _chartAnimation;
  late Animation<double> _menuAnimation;

  // State variables
  int _selectedIndex = 1;
  bool _isLoading = true;
  bool _isRefreshing = false;
  List<Map<String, dynamic>> _todayTasks = [];
  List<Map<String, dynamic>> _userPlants = [];
  List<Map<String, dynamic>> _weeklyProgress = [];
  List<Map<String, dynamic>> _monthlyProgress = [];
  String? _selectedPlantId;
  String _errorMessage = '';
  DateTime _selectedDate = DateTime.now();
  bool _isDatePickerVisible = false;

  // Progress tracking
  int _totalTasks = 0;
  int _completedTasks = 0;
  double _completionPercentage = 0.0;
  int _streakDays = 0;
  int _weeklyAverage = 0;
  int _monthlyAverage = 0;
  int _totalAccuracyChecks = 0;
  int _completedAccuracyChecks = 0;
  double _accuracyPercentage = 0.0;
  bool _isUpdatingTask = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeData();
  }

  void _initializeAnimations() {
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    progressAnimation = Tween<double>(
      begin: 0.0,
      end: 0.75, // 75% progress as example
    ).animate(
      CurvedAnimation(parent: _progressController!, curve: Curves.easeInOut),
    );

    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _chartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _menuAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _cardAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _cardAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _chartAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _chartAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _menuAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _menuAnimationController,
        curve: Curves.bounceOut,
      ),
    );
  }

  @override
  void dispose() {
    _progressAnimationController.dispose();
    _cardAnimationController.dispose();
    _chartAnimationController.dispose();
    _menuAnimationController.dispose();
    super.dispose();
    _progressController?.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage =
              'User tidak ditemukan. Silakan login terlebih dahulu.';
          _isLoading = false;
        });
        return;
      }

      await _loadUserPlants(user.id);
      if (_selectedPlantId != null) {
        await _generateDailyTasksForDate(
          _selectedDate,
        ); // CHANGED: gunakan _selectedDate
        await _loadTasksForDate(
          user.id,
          _selectedDate,
        ); // CHANGED: gunakan method baru
        await _loadWeeklyProgress();
        await _loadMonthlyProgress();
        await _updateProgressCalculationsForDate(
          _selectedDate,
        ); // CHANGED: gunakan method baru
        await _calculateStreakAndAverage();
        await _loadAccuracyDataForDate(
          _selectedDate,
        ); // CHANGED: gunakan method baru

        // Start animations sequentially
        _cardAnimationController.forward();
        await Future.delayed(const Duration(milliseconds: 200));
        _progressAnimationController.forward();
        await Future.delayed(const Duration(milliseconds: 200));
        _chartAnimationController.forward();
        await Future.delayed(const Duration(milliseconds: 200));
        _menuAnimationController.forward();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAccuracyDataForDate(DateTime selectedDate) async {
    if (_selectedPlantId == null) return;

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
      final accuracyResponse = await supabase
          .from('accuracy_checks')
          .select('*')
          .eq('user_plant_id', _selectedPlantId!)
          .eq('check_date', dateStr);

      final accuracyData = List<Map<String, dynamic>>.from(accuracyResponse);

      _totalAccuracyChecks = accuracyData.length;
      _completedAccuracyChecks =
          accuracyData.where((check) => check['is_completed'] == true).length;
      _accuracyPercentage =
          _totalAccuracyChecks > 0
              ? (_completedAccuracyChecks / _totalAccuracyChecks) * 100
              : 0.0;

      setState(() {});
    } catch (e) {
      debugPrint('Error loading accuracy data for date: $e');
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);

    try {
      final user = supabase.auth.currentUser;
      if (user != null && _selectedPlantId != null) {
        await _loadTasksForDate(user.id, _selectedDate); // CHANGED
        await _loadWeeklyProgress();
        await _loadMonthlyProgress();
        await _updateProgressCalculationsForDate(_selectedDate); // CHANGED
        await _calculateStreakAndAverage();
        await _loadAccuracyDataForDate(_selectedDate); // CHANGED

        _progressAnimationController.reset();
        _chartAnimationController.reset();
        _menuAnimationController.reset();
        _progressAnimationController.forward();
        _chartAnimationController.forward();
        _menuAnimationController.forward();
        _progressController!.forward();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isRefreshing = false);
    }
  }

  Future<void> _loadUserPlants(String userId) async {
    try {
      final plants = await _userPlantService.getUserPlants(
        userId,
        status: 'planting',
      );
      setState(() {
        _userPlants = plants;
        _selectedPlantId = plants.isNotEmpty ? plants.first['id'] : null;
      });

      if (_userPlants.isEmpty) {
        setState(() {
          _errorMessage =
              'Tidak ada tanaman aktif. Silakan tambah tanaman terlebih dahulu.';
          _isLoading = false;
        });
      }
    } catch (e) {
      throw Exception('Gagal memuat data tanaman: $e');
    }
  }

  Future<void> _generateDailyTasksForSelectedPlant() async {
    if (_selectedPlantId == null) return;
    try {
      await _dailyTaskService.generateDailyTasksForPlant(_selectedPlantId!);
    } catch (e) {
      debugPrint('Error generating daily tasks: $e');
    }
  }

  Future<void> _loadTasksForDate(String userId, DateTime selectedDate) async {
    try {
      final userPlants = await _userPlantService.getUserPlants(userId);
      final userPlantIds = userPlants.map((plant) => plant['id']).toList();

      if (userPlantIds.isEmpty) {
        setState(() {
          _todayTasks = [];
          _isLoading = false;
        });
        return;
      }

      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);

      final response = await supabase
          .from('daily_tasks')
          .select('''
          *,
          user_plants!inner(
            id,
            plant_name,
            plant_types(name)
          )
        ''')
          .inFilter('user_plant_id', userPlantIds)
          .eq('task_date', dateStr)
          .order('created_at');

      List<Map<String, dynamic>> tasks = List<Map<String, dynamic>>.from(
        response,
      );

      if (_selectedPlantId != null) {
        tasks =
            tasks
                .where((task) => task['user_plant_id'] == _selectedPlantId)
                .toList();
      }

      setState(() {
        _todayTasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      throw Exception('Gagal memuat task untuk tanggal yang dipilih: $e');
    }
  }

  Future<void> _loadWeeklyProgress() async {
    if (_selectedPlantId == null) return;
    try {
      final progress = await _dailyProgressService.getDailyProgressForPlant(
        _selectedPlantId!,
      );
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));

      final weeklyData =
          progress.where((p) {
            final date = DateTime.parse(p['progress_date']);
            return date.isAfter(weekAgo) &&
                date.isBefore(now.add(const Duration(days: 1)));
          }).toList();

      weeklyData.sort(
        (a, b) => DateTime.parse(
          a['progress_date'],
        ).compareTo(DateTime.parse(b['progress_date'])),
      );

      setState(() {
        _weeklyProgress = weeklyData;
      });
    } catch (e) {
      debugPrint('Error loading weekly progress: $e');
    }
  }

  Future<void> _loadMonthlyProgress() async {
    if (_selectedPlantId == null) return;
    try {
      final progress = await _dailyProgressService.getDailyProgressForPlant(
        _selectedPlantId!,
      );
      final now = DateTime.now();
      final monthAgo = now.subtract(const Duration(days: 30));

      final monthlyData =
          progress.where((p) {
            final date = DateTime.parse(p['progress_date']);
            return date.isAfter(monthAgo) &&
                date.isBefore(now.add(const Duration(days: 1)));
          }).toList();

      setState(() {
        _monthlyProgress = monthlyData;
      });
    } catch (e) {
      debugPrint('Error loading monthly progress: $e');
    }
  }

  Future<void> _calculateStreakAndAverage() async {
    int streak = 0;
    if (_weeklyProgress.isNotEmpty) {
      for (int i = _weeklyProgress.length - 1; i >= 0; i--) {
        if (_weeklyProgress[i]['overall_completion_percentage'] == 100) {
          streak++;
        } else {
          break;
        }
      }
    }

    int weeklyTotal = 0;
    if (_weeklyProgress.isNotEmpty) {
      for (var progress in _weeklyProgress) {
        weeklyTotal += progress['overall_completion_percentage'] as int;
      }
    }
    int weeklyAvg =
        _weeklyProgress.isNotEmpty
            ? (weeklyTotal / _weeklyProgress.length).round()
            : 0;

    int monthlyTotal = 0;
    if (_monthlyProgress.isNotEmpty) {
      for (var progress in _monthlyProgress) {
        monthlyTotal += progress['overall_completion_percentage'] as int;
      }
    }
    int monthlyAvg =
        _monthlyProgress.isNotEmpty
            ? (monthlyTotal / _monthlyProgress.length).round()
            : 0;

    setState(() {
      _streakDays = streak;
      _weeklyAverage = weeklyAvg;
      _monthlyAverage = monthlyAvg;
    });
  }

  Future<void> _updateProgressCalculationsForDate(DateTime selectedDate) async {
    if (_selectedPlantId == null) return;

    try {
      _totalTasks = _todayTasks.length;
      _completedTasks =
          _todayTasks.where((task) => task['is_completed'] == true).length;
      _completionPercentage =
          _totalTasks > 0 ? (_completedTasks / _totalTasks) * 100 : 0.0;

      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
      final progressId = '${_selectedPlantId}_$dateStr';

      await _dailyProgressService.updateDailyProgress(
        id: progressId,
        userPlantId: _selectedPlantId!,
        progressDate: selectedDate,
        totalTasks: _totalTasks,
        completedTasks: _completedTasks,
        totalAccuracyChecks: _totalAccuracyChecks,
        completedAccuracyChecks: _completedAccuracyChecks,
        overallCompletionPercentage: _completionPercentage.round(),
      );

      setState(() {});
    } catch (e) {
      debugPrint('Error updating progress calculations for date: $e');
    }
  }

  Future<void> _generateDailyTasksForDate(DateTime selectedDate) async {
    if (_selectedPlantId == null) return;
    try {
      await _dailyTaskService.generateDailyTasksForPlant(
        _selectedPlantId!,
        targetDate: selectedDate,
      );
    } catch (e) {
      debugPrint('Error generating daily tasks for date: $e');
    }
  }

  Future<void> _refreshDataForSelectedDate() async {
    setState(() => _isRefreshing = true);

    try {
      final user = supabase.auth.currentUser;
      if (user != null && _selectedPlantId != null) {
        await _generateDailyTasksForDate(_selectedDate);
        await _loadTasksForDate(user.id, _selectedDate);
        await _loadAccuracyDataForDate(_selectedDate);
        await _updateProgressCalculationsForDate(_selectedDate);

        _progressAnimationController.reset();
        _chartAnimationController.reset();
        _menuAnimationController.reset();
        _progressAnimationController.forward();
        _chartAnimationController.forward();
        _menuAnimationController.forward();
        _progressController!.forward();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isRefreshing = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(
        const Duration(days: 365),
      ), // 1 tahun ke belakang
      lastDate: DateTime.now().add(
        const Duration(days: 365),
      ), // 1 tahun ke depan
      builder: (context, child) {
        final themeProvider = Provider.of<ThemeProvider>(context);
        final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme:
                isDarkMode
                    ? const ColorScheme.dark(primary: Colors.green)
                    : const ColorScheme.light(primary: Color(0xFF527A32)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      await _refreshDataForSelectedDate();
    }
  }

  void _navigateToDate(int dayOffset) async {
    final newDate = _selectedDate.add(Duration(days: dayOffset));
    setState(() {
      _selectedDate = newDate;
    });
    await _refreshDataForSelectedDate();
  }

  Future<void> _completeTask(String taskId, bool isCompleted) async {
    setState(() => _isUpdatingTask = true);

    try {
      // Update the task completion status in Supabase
      await supabase
          .from('daily_tasks')
          .update({'is_completed': isCompleted})
          .eq('id', taskId);

      // Update the local task list
      setState(() {
        final taskIndex = _todayTasks.indexWhere(
          (task) => task['id'] == taskId,
        );
        if (taskIndex != -1) {
          _todayTasks[taskIndex]['is_completed'] = isCompleted;
        }
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isCompleted ? 'Task berhasil diselesaikan!' : 'Task dibatalkan',
            ),
            backgroundColor: isCompleted ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Trigger progress animation refresh
      _progressAnimationController.reset();
      _progressAnimationController.forward();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui task: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }

      // Revert the local change if database update failed
      setState(() {
        final taskIndex = _todayTasks.indexWhere(
          (task) => task['id'] == taskId,
        );
        if (taskIndex != -1) {
          _todayTasks[taskIndex]['is_completed'] = !isCompleted;
        }
      });
    } finally {
      setState(() => _isUpdatingTask = false);
    }
  }

  Future<void> _onPlantChanged(String? plantId) async {
    if (plantId == null || plantId == _selectedPlantId) return;

    setState(() {
      _selectedPlantId = plantId;
      _isLoading = true;
    });

    _progressAnimationController.reset();
    _cardAnimationController.reset();
    _chartAnimationController.reset();
    _menuAnimationController.reset();

    try {
      await _generateDailyTasksForDate(_selectedDate); // CHANGED
      final user = supabase.auth.currentUser;
      if (user != null) {
        await _loadTasksForDate(user.id, _selectedDate); // CHANGED
        await _loadWeeklyProgress();
        await _loadMonthlyProgress();
        await _updateProgressCalculationsForDate(_selectedDate); // CHANGED
        await _calculateStreakAndAverage();
        await _loadAccuracyDataForDate(_selectedDate); // CHANGED

        _cardAnimationController.forward();
        await Future.delayed(const Duration(milliseconds: 200));
        _progressAnimationController.forward();
        await Future.delayed(const Duration(milliseconds: 200));
        _chartAnimationController.forward();
        await Future.delayed(const Duration(milliseconds: 200));
        _menuAnimationController.forward();
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'Gagal memuat data untuk tanaman yang dipilih: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomePage()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => OptionPage()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TimelinePage()),
        );
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfilPage()),
        );
        break;
    }
  }

  String _getPlantDisplayName(Map<String, dynamic> plant) {
    final plantName = plant['plant_name'] as String?;
    final plantTypeData = plant['plant_types'] as Map<String, dynamic>?;
    final plantTypeName = plantTypeData?['name'] as String?;

    if (plantName == null || plantName.trim().isEmpty) {
      return 'Tanaman ${plantTypeName ?? 'Tidak Dikenal'}';
    }

    if (plantName.toLowerCase().contains('tanaman')) {
      return plantName;
    }

    return 'Tanaman $plantName';
  }

  // Navigation to Task Page
  void _navigateToTaskPage() async {
    if (_selectedPlantId != null) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => TaskScreen(
                accuracy: _accuracyPercentage,
                userPlantId: _selectedPlantId!,
                selectedDate: _selectedDate, // TAMBAHKAN ini
              ),
        ),
      );

      // Refresh data when returning from task page
      if (result == true) {
        _refreshDataForSelectedDate(); // CHANGED
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih tanaman terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  // GANTI _navigateToAccuracyPage() dengan ini:
  void _navigateToAccuracyPage() async {
    if (_selectedPlantId != null && _userPlants.isNotEmpty) {
      final selectedPlant = _userPlants.firstWhere(
        (plant) => plant['id'] == _selectedPlantId,
        orElse: () => _userPlants.first,
      );

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => AccuracyPage(
                userPlantId: _selectedPlantId!,
                plantName: selectedPlant['plant_name'] ?? 'Unknown Plant',
                plantTypeId: selectedPlant['plant_type_id'] ?? 1,
                selectedDate: _selectedDate,
              ),
        ),
      );

      // Refresh data when returning from accuracy page
      if (result == true) {
        _refreshDataForSelectedDate(); // CHANGED
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih tanaman terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Widget _buildDateNavigationBar(
    bool isDarkMode,
    Color textColor,
    Color buttonColor,
  ) {
    final isToday =
        _selectedDate.year == DateTime.now().year &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.day == DateTime.now().day;

    final dateFormatter = DateFormat(
      'EEEE, dd MMMM yyyy',
      'id_ID',
    ).format(_selectedDate);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            buttonColor.withValues(alpha: 0.1),
            buttonColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: buttonColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: buttonColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header dengan indikator hari ini
          Row(
            children: [
              Icon(Icons.calendar_today, color: buttonColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tanggal Dipilih',
                      style: TextStyle(
                        fontSize: 14,
                        color: textColor.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      dateFormatter,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (isToday)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'HARI INI',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Navigation buttons
          Row(
            children: [
              // Previous day button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isRefreshing ? null : () => _navigateToDate(-1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor.withValues(alpha: 0.1),
                    foregroundColor: buttonColor,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: buttonColor.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.chevron_left, size: 20),
                  label: const Text('Sebelum', style: TextStyle(fontSize: 10)),
                ),
              ),

              const SizedBox(width: 8),

              // Date picker button
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _isRefreshing ? null : () => _selectDate(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.date_range, size: 20),
                  label: const Text(
                    'Pilih Tanggal',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Next day button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isRefreshing ? null : () => _navigateToDate(1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor.withValues(alpha: 0.1),
                    foregroundColor: buttonColor,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: buttonColor.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.chevron_right, size: 20),
                  label: const Text('Sesudah', style: TextStyle(fontSize: 10)),
                ),
              ),
            ],
          ),

          // Quick access buttons untuk hari ini
          if (!isToday) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed:
                    _isRefreshing
                        ? null
                        : () {
                          setState(() {
                            _selectedDate = DateTime.now();
                          });
                          _refreshDataForSelectedDate();
                        },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                icon: const Icon(Icons.today, size: 16),
                label: const Text(
                  'Kembali ke Hari Ini',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuNavigation(
    bool isDarkMode,
    Color textColor,
    Color buttonColor,
  ) {
    return AnimatedBuilder(
      animation: _menuAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _menuAnimation.value,
          child: Container(
            margin: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildMenuButton(
                    title: 'Task Hari Ini',
                    subtitle: 'Kelola & selesaikan task',
                    icon: Icons.task_alt,
                    color: Colors.blue,
                    onTap: () {},
                    isDarkMode: isDarkMode,
                    textColor: textColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMenuButton(
                    title: 'Cek Akurasi',
                    subtitle: 'Verifikasi dengan foto',
                    icon: Icons.camera_alt,
                    color: Colors.purple,
                    onTap: () {},
                    isDarkMode: isDarkMode,
                    textColor: textColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isDarkMode,
    required Color textColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: textColor.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsOverview(
    bool isDarkMode,
    Color textColor,
    Color buttonColor,
  ) {
    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _cardAnimation.value,
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  buttonColor.withValues(alpha: 0.1),
                  buttonColor.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: buttonColor.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: buttonColor.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _navigateToTaskPage,
                        child: _buildStatCard(
                          'Task Hari Ini',
                          '${_completionPercentage.round()}%',
                          Icons.today,
                          buttonColor,
                          textColor,
                          isClickable: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: _navigateToAccuracyPage,
                        child: _buildStatCard(
                          'Akurasi',
                          '${_accuracyPercentage.round()}%',
                          Icons.verified,
                          Colors.green,
                          textColor,
                          isClickable: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Streak',
                        '$_streakDays hari',
                        Icons.local_fire_department,
                        Colors.orange,
                        textColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Mingguan',
                        '$_weeklyAverage%',
                        Icons.trending_up,
                        Colors.blue,
                        textColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    Color textColor, {
    bool isClickable = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(isClickable ? 0.5 : 0.3),
          width: isClickable ? 2 : 1,
        ),
        boxShadow:
            isClickable
                ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
                : null,
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: textColor.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          if (isClickable) ...[
            const SizedBox(height: 4),
            Text(
              'Tap untuk buka',
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressRing(
    bool isDarkMode,
    Color textColor,
    Color buttonColor,
  ) {
    // Check if animation is initialized
    if (progressAnimation == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return AnimatedBuilder(
      animation: progressAnimation!,
      builder: (context, child) {
        return GestureDetector(
          onTap: _navigateToTaskPage,
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 8,
            shadowColor: buttonColor.withValues(alpha: 0.3),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    isDarkMode ? Colors.grey[800]! : Colors.grey[50]!,
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'Task',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Tap untuk buka Task',
                      style: TextStyle(
                        fontSize: 12,
                        color: buttonColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    SizedBox(
                      width: 150,
                      height: 150,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Background circle
                          CircularProgressIndicator(
                            value: 1.0,
                            strokeWidth: 12,
                            backgroundColor:
                                isDarkMode
                                    ? Colors.grey[700]
                                    : Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isDarkMode
                                  ? Colors.grey[700]!
                                  : Colors.grey[300]!,
                            ),
                          ),
                          // Animated progress circle
                          CircularProgressIndicator(
                            value: progressAnimation!.value,
                            strokeWidth: 12,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              buttonColor,
                            ),
                            strokeCap: StrokeCap.round,
                          ),
                          // Progress percentage text
                          Text(
                            '${(progressAnimation!.value * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Completing your task...',
                      style: TextStyle(
                        fontSize: 16,
                        color: textColor.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: progressAnimation!.value,
                      backgroundColor:
                          isDarkMode ? Colors.grey[700] : Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(buttonColor),
                      minHeight: 8,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildWeeklyBars(
    Color textColor,
    Color buttonColor,
    bool isDarkMode,
  ) {
    final List<String> dayNames = [
      'Sen',
      'Sel',
      'Rab',
      'Kam',
      'Jum',
      'Sab',
      'Min',
    ];
    final now = DateTime.now();

    return List.generate(7, (index) {
      final targetDate = now.subtract(Duration(days: 6 - index));
      final dateStr = DateFormat('yyyy-MM-dd').format(targetDate);

      // Cari data untuk tanggal ini
      final dayData = _weeklyProgress.firstWhere(
        (progress) => progress['progress_date'] == dateStr,
        orElse: () => {'overall_completion_percentage': 0},
      );

      final percentage =
          (dayData['overall_completion_percentage'] as num?)?.toDouble() ?? 0.0;
      final barHeight =
          (percentage / 100) * 120 + 20; // Minimal height 20, max 140

      // Tentukan warna berdasarkan persentase
      Color barColor;
      if (percentage >= 80) {
        barColor = Colors.green;
      } else if (percentage >= 60) {
        barColor = Colors.orange;
      } else if (percentage > 0) {
        barColor = Colors.red;
      } else {
        barColor = Colors.grey.withValues(alpha: 0.3);
      }

      final isToday =
          targetDate.day == now.day &&
          targetDate.month == now.month &&
          targetDate.year == now.year;

      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Percentage label
              Text(
                '${percentage.round()}%',
                style: TextStyle(
                  fontSize: 10,
                  color: textColor.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),

              // Bar
              AnimatedContainer(
                duration: Duration(milliseconds: 500 + (index * 100)),
                width: 24,
                height: barHeight,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: barColor.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Day label
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      isToday
                          ? buttonColor.withValues(alpha: 0.2)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  dayNames[index],
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        isToday
                            ? buttonColor
                            : textColor.withValues(alpha: 0.7),
                    fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // Tambahkan method helper ini juga:
  Widget _buildWeeklyStatItem(
    String title,
    String value,
    IconData icon,
    Color color,
    Color textColor,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: textColor.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildAccuracyPanel(
    bool isDarkMode,
    Color textColor,
    Color buttonColor,
  ) {
    return AnimatedBuilder(
      animation: _chartAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _chartAnimation.value,
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 8,
            shadowColor: Colors.purple.withValues(alpha: 0.3),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    isDarkMode ? Colors.grey[800]! : Colors.grey[50]!,
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with icon
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.purple,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Accuracy Checks',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                'Verifikasi dengan foto',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textColor.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: _navigateToAccuracyPage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.purple.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.purple,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Accuracy Progress Circle
                    Center(
                      child: SizedBox(
                        width: 120,
                        height: 120,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Background circle
                            CircularProgressIndicator(
                              value: 1.0,
                              strokeWidth: 8,
                              backgroundColor:
                                  isDarkMode
                                      ? Colors.grey[700]
                                      : Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isDarkMode
                                    ? Colors.grey[700]!
                                    : Colors.grey[300]!,
                              ),
                            ),
                            // Progress circle
                            CircularProgressIndicator(
                              value: _accuracyPercentage / 100,
                              strokeWidth: 8,
                              backgroundColor: Colors.transparent,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.purple,
                              ),
                              strokeCap: StrokeCap.round,
                            ),
                            // Percentage text
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${_accuracyPercentage.round()}%',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                Text(
                                  'Akurasi',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textColor.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Stats Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildAccuracyStatItem(
                            'Total Checks',
                            _totalAccuracyChecks.toString(),
                            Icons.assignment,
                            Colors.blue,
                            textColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildAccuracyStatItem(
                            'Completed',
                            _completedAccuracyChecks.toString(),
                            Icons.check_circle,
                            Colors.green,
                            textColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildAccuracyStatItem(
                            'Pending',
                            (_totalAccuracyChecks - _completedAccuracyChecks)
                                .toString(),
                            Icons.pending,
                            Colors.orange,
                            textColor,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _navigateToAccuracyPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.camera_alt, size: 20),
                        label: const Text(
                          'Mulai Verifikasi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccuracyStatItem(
    String title,
    String value,
    IconData icon,
    Color color,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 10, color: textColor.withOpacity(0.7)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(
    bool isDarkMode,
    Color textColor,
    Color buttonColor,
  ) {
    return AnimatedBuilder(
      animation: _chartAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _chartAnimation.value,
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 8,
            shadowColor: buttonColor.withOpacity(0.3),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    isDarkMode ? Colors.grey[800]! : Colors.grey[50]!,
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.trending_up, color: buttonColor, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          'Progress 7 Hari Terakhir',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Chart container
                    Container(
                      height: 180,
                      child:
                          _weeklyProgress.isEmpty
                              ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.bar_chart_outlined,
                                      color: textColor.withOpacity(0.5),
                                      size: 48,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Belum ada data progress mingguan',
                                      style: TextStyle(
                                        color: textColor.withOpacity(0.7),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              : Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: _buildWeeklyBars(
                                  textColor,
                                  buttonColor,
                                  isDarkMode,
                                ),
                              ),
                    ),

                    const SizedBox(height: 16),

                    // Summary
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: buttonColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: buttonColor.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildWeeklyStatItem(
                            'Rata-rata',
                            '$_weeklyAverage%',
                            Icons.analytics,
                            buttonColor,
                            textColor,
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: buttonColor.withOpacity(0.3),
                          ),
                          _buildWeeklyStatItem(
                            'Streak',
                            '$_streakDays hari',
                            Icons.local_fire_department,
                            Colors.orange,
                            textColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    final backgroundColor =
        isDarkMode ? Colors.grey[900]! : const Color(0xFFF6F6E9);
    final appBarColor =
        isDarkMode ? Colors.grey[850]! : const Color(0xFFA7B59E);
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final buttonColor =
        isDarkMode ? Colors.green[800]! : const Color(0xFF527A32);
    final navBarColor = isDarkMode ? Colors.grey[850]! : Colors.white;
    final navIconColor = isDarkMode ? Colors.green[200]! : Colors.green;
    final errorColor = isDarkMode ? Colors.red[300]! : Colors.red;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        title: Text(
          "Progress Dashboard",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.menu, color: textColor),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: textColor),
            onPressed: _initializeData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      drawer: DrawerPage(),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: errorColor, size: 64),
                      const SizedBox(height: 16),
                      Text(
                        'Kesalahan',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage,
                        style: TextStyle(color: textColor),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        onPressed: _initializeData,
                        child: const Text(
                          "Coba Lagi",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              : SingleChildScrollView(
                child: Column(
                  children: [
                    // Plant Selection Dropdown
                    if (_userPlants.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: buttonColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: buttonColor.withOpacity(0.3),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: DropdownButton<String>(
                              value: _selectedPlantId,
                              isExpanded: true,
                              underline: Container(),
                              hint: Text(
                                'Pilih Tanaman',
                                style: TextStyle(color: textColor),
                              ),
                              items:
                                  _userPlants.map<DropdownMenuItem<String>>((
                                    plant,
                                  ) {
                                    return DropdownMenuItem<String>(
                                      value: plant['id'],
                                      child: Text(
                                        _getPlantDisplayName(plant),
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: textColor,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                              onChanged: _onPlantChanged,
                            ),
                          ),
                        ),
                      ),

                      _buildDateNavigationBar(
                        isDarkMode,
                        textColor,
                        buttonColor,
                      ),

                      // Stats Overview
                      _buildStatsOverview(isDarkMode, textColor, buttonColor),

                      // Progress Ring
                      _buildProgressRing(isDarkMode, textColor, buttonColor),

                      const SizedBox(height: 24),

                      _buildAccuracyPanel(isDarkMode, textColor, buttonColor),

                      const SizedBox(height: 24),

                      // Weekly Chart
                      _buildWeeklyChart(isDarkMode, textColor, buttonColor),
                    ],
                  ],
                ),
              ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: navBarColor,
        selectedItemColor: navIconColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
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
}
