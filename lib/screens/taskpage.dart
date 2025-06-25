import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'HomePage.dart';
import 'accuracy.dart';
import 'timeline_page.dart';
import '../provider/theme_provider.dart';

class TaskScreen extends StatefulWidget {
  final double accuracy;
  final String userPlantId;
  final DateTime selectedDate;

  const TaskScreen({
    Key? key,
    this.accuracy = 0.0,
    required this.userPlantId,
    required this.selectedDate,
  }) : super(key: key);

  @override
  _TaskScreenState createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  int _selectedIndex = 1;
  late double accuracy;
  bool isLoading = true;
  String plantName = "Tanaman";
  String userPlantId = "";
  String? userId;
  String? plantTypeId;
  DateTime? plantStartDate;

  // Task data
  List<Map<String, dynamic>> todayTasks = [];
  Map<String, bool> taskCompletionStatus = {};
  int currentDay = 1;
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    debugPrint("=== INIT STATE ===");
    accuracy = widget.accuracy;
    userPlantId = widget.userPlantId;
    selectedDate = widget.selectedDate;
    debugPrint("userPlantId from widget: $userPlantId");
    debugPrint("selectedDate from widget: $selectedDate");
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user != null) {
      setState(() {
        userId = user.id;
      });
      await _loadPlantInfo();
      await _generateAndLoadTasks();
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadPlantInfo() async {
    try {
      final supabase = Supabase.instance.client;

      final plantData =
          await supabase
              .from('user_plants')
              .select('''
            id,
            plant_name,
            start_date,
            plant_type_id,
            plant_types(
              id,
              name,
              description,
              growing_days
            )
          ''')
              .eq('id', userPlantId)
              .eq('user_id', userId!)
              .single();

      if (plantData != null) {
        final plantTypeData = plantData['plant_types'] as Map<String, dynamic>;
        final customName = plantData['plant_name'] as String?;
        final typeName = plantTypeData['name'] as String;
        final startDate = DateTime.parse(plantData['start_date']);

        // Hitung hari berdasarkan selectedDate, bukan hari ini
        final daysDiff = selectedDate.difference(startDate).inDays + 1;

        setState(() {
          plantName =
              (customName?.isNotEmpty == true && customName != typeName)
                  ? customName!
                  : typeName;
          plantTypeId = plantData['plant_type_id'] as String;
          plantStartDate = startDate; // Simpan start date
          currentDay = daysDiff > 0 ? daysDiff : 1;
        });
      }
    } catch (e) {
      debugPrint("Error loading plant info: $e");
    }
  }

  Future<void> _generateAndLoadTasks() async {
    if (userId == null || plantTypeId == null) return;

    try {
      await _generateDailyTasksForPlant();
      await _loadTodayTasks();
    } catch (e) {
      debugPrint("Error generating and loading tasks: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _generateDailyTasksForPlant() async {
    try {
      final supabase = Supabase.instance.client;

      final plant =
          await supabase
              .from('user_plants')
              .select('plant_type_id, start_date')
              .eq('id', userPlantId)
              .single();

      // DEBUG: Print plant data
      debugPrint("=== PLANT DATA ===");
      debugPrint("Plant data: $plant");
      debugPrint("Plant type ID: ${plant['plant_type_id']}");

      final templates = await supabase
          .from('task_templates')
          .select()
          .eq('plant_type_id', plant['plant_type_id']);

      // DEBUG: Print templates
      debugPrint("=== TEMPLATES ===");
      debugPrint("Templates found: ${templates.length}");
      debugPrint("Templates data: $templates");

      final startDate = DateTime.parse(plant['start_date']);
      final daysDiff = selectedDate.difference(startDate).inDays + 1;

      // DEBUG: Print date calculations
      debugPrint("=== DATE CALCULATIONS ===");
      debugPrint("Start date: $startDate");
      debugPrint("Selected date: $selectedDate");
      debugPrint("Days difference: $daysDiff");

      List<Map<String, dynamic>> tasksToInsert = [];

      for (var template in templates) {
        final dayNumber = template['day_number'] as int;
        final isDaily = template['is_daily'] as bool;

        debugPrint("=== TEMPLATE CHECK ===");
        debugPrint("Template: ${template['task_name']}");
        debugPrint("Day number: $dayNumber");
        debugPrint("Is daily: $isDaily");
        debugPrint("Current day: $daysDiff");

        if (isDaily) {
          if (daysDiff >= dayNumber) {
            debugPrint("✓ Daily task should be added");
            final selectedDateString =
                selectedDate.toIso8601String().split('T')[0];

            tasksToInsert.add({
              'id': '${template['id']}_${userPlantId}_day_$daysDiff',
              'user_plant_id': userPlantId,
              'task_template_id': template['id'],
              'task_date': selectedDateString,
              'is_completed': false,
            });
          } else {
            debugPrint("✗ Daily task not ready yet");
          }
        } else {
          if (dayNumber == daysDiff) {
            debugPrint("✓ One-time task should be added");
            final selectedDateString =
                selectedDate.toIso8601String().split('T')[0];

            tasksToInsert.add({
              'id': '${template['id']}_$userPlantId',
              'user_plant_id': userPlantId,
              'task_template_id': template['id'],
              'task_date': selectedDateString,
              'is_completed': false,
            });
          } else {
            debugPrint("✗ One-time task not for this day");
          }
        }
      }

      debugPrint("=== TASKS TO INSERT ===");
      debugPrint("Tasks to insert: ${tasksToInsert.length}");
      debugPrint("Tasks data: $tasksToInsert");

      if (tasksToInsert.isNotEmpty) {
        await supabase.from('daily_tasks').upsert(tasksToInsert);
        debugPrint("✓ Tasks inserted successfully");
      } else {
        debugPrint("✗ No tasks to insert");
      }
    } catch (e) {
      debugPrint("Error generating daily tasks: $e");
    }
  }

  Future<void> _loadTodayTasks() async {
    if (userId == null) return;

    try {
      final supabase = Supabase.instance.client;
      final selectedDateString = selectedDate.toIso8601String().split('T')[0];

      // DEBUG: Print semua parameter
      debugPrint("=== DEBUGGING LOAD TASKS ===");
      debugPrint("userPlantId: $userPlantId");
      debugPrint("selectedDate: $selectedDate");
      debugPrint("selectedDateString: $selectedDateString");
      debugPrint("userId: $userId");

      // Query utama dengan JOIN - TANPA ORDER BY
      final tasksResponse = await supabase
          .from('daily_tasks')
          .select('''
      id,
      task_date,
      is_completed,
      completed_at,
      notes,
      task_templates(
        id,
        task_name,
        task_description,
        day_number,
        is_daily
      )
    ''')
          .eq('user_plant_id', userPlantId)
          .eq('task_date', selectedDateString);
      // REMOVE .order() karena tidak bisa order by joined table

      debugPrint("Final query result: $tasksResponse");
      debugPrint("Tasks count: ${(tasksResponse as List).length}");

      // Cek apakah ada data null di task_templates
      for (var task in tasksResponse) {
        if (task['task_templates'] == null) {
          debugPrint("WARNING: task_templates is null for task: ${task['id']}");
          debugPrint(
            "This might be because task_template_id doesn't exist in task_templates table",
          );
        }
      }

      // MANUAL SORTING berdasarkan day_number dari task_templates
      List<Map<String, dynamic>> sortedTasks =
          (tasksResponse as List).cast<Map<String, dynamic>>();
      sortedTasks.sort((a, b) {
        final aTemplate = a['task_templates'] as Map<String, dynamic>?;
        final bTemplate = b['task_templates'] as Map<String, dynamic>?;

        if (aTemplate == null || bTemplate == null) return 0;

        final aDayNumber = aTemplate['day_number'] as int? ?? 0;
        final bDayNumber = bTemplate['day_number'] as int? ?? 0;

        return aDayNumber.compareTo(bDayNumber);
      });

      setState(() {
        todayTasks = sortedTasks;

        taskCompletionStatus.clear();
        for (var task in todayTasks) {
          final taskId = task['id'] as String;
          taskCompletionStatus[taskId] = task['is_completed'] as bool? ?? false;
        }

        isLoading = false;
      });

      _calculateAccuracy();
      await _updateDailyProgress();
    } catch (e) {
      debugPrint("Error loading tasks: $e");
      debugPrint("Error details: ${e.toString()}");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadTodayTasksAlternative() async {
    if (userId == null) return;

    try {
      final supabase = Supabase.instance.client;
      final selectedDateString = selectedDate.toIso8601String().split('T')[0];

      // Query daily_tasks dulu
      final dailyTasksResponse = await supabase
          .from('daily_tasks')
          .select('*')
          .eq('user_plant_id', userPlantId)
          .eq('task_date', selectedDateString);

      debugPrint("Daily tasks raw: $dailyTasksResponse");

      // Untuk setiap task, ambil template-nya
      List<Map<String, dynamic>> tasksWithTemplates = [];

      for (var task in dailyTasksResponse) {
        try {
          final template =
              await supabase
                  .from('task_templates')
                  .select('*')
                  .eq('id', task['task_template_id'])
                  .single();

          task['task_templates'] = template;
          tasksWithTemplates.add(task);
        } catch (e) {
          debugPrint("Error getting template for task ${task['id']}: $e");
          // Skip task jika template tidak ditemukan
        }
      }

      setState(() {
        todayTasks = tasksWithTemplates;

        taskCompletionStatus.clear();
        for (var task in todayTasks) {
          final taskId = task['id'] as String;
          taskCompletionStatus[taskId] = task['is_completed'] as bool? ?? false;
        }

        isLoading = false;
      });

      _calculateAccuracy();
      await _updateDailyProgress();
    } catch (e) {
      debugPrint("Error in alternative load: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _toggleTaskCompletion(String taskId, bool isCompleted) async {
    setState(() {
      taskCompletionStatus[taskId] = isCompleted;
    });

    try {
      final supabase = Supabase.instance.client;

      if (isCompleted) {
        await supabase
            .from('daily_tasks')
            .update({
              'is_completed': true,
              'completed_at': DateTime.now().toIso8601String(),
            })
            .eq('id', taskId);
      } else {
        await supabase
            .from('daily_tasks')
            .update({'is_completed': false, 'completed_at': null})
            .eq('id', taskId);
      }

      await _updateDailyProgress();
      _calculateAccuracy();

      debugPrint(
        'Task ${isCompleted ? "completed" : "unchecked"} successfully!',
      );
    } catch (e) {
      debugPrint('Error updating task: $e');
      setState(() {
        taskCompletionStatus[taskId] = !isCompleted;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update task: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateDailyProgress() async {
    try {
      final supabase = Supabase.instance.client;
      final selectedDateString = selectedDate.toIso8601String().split('T')[0];

      final completedTasks =
          taskCompletionStatus.values.where((completed) => completed).length;
      final totalTasks = taskCompletionStatus.length;
      final completionPercentage =
          totalTasks > 0 ? ((completedTasks / totalTasks) * 100).round() : 0;

      final progressId = '${userPlantId}_$selectedDateString';

      await supabase.from('daily_progress').upsert({
        'id': progressId,
        'user_plant_id': userPlantId,
        'progress_date': selectedDateString,
        'total_tasks': totalTasks,
        'completed_tasks': completedTasks,
        'total_accuracy_checks': 0,
        'completed_accuracy_checks': 0,
        'overall_completion_percentage': completionPercentage,
      });

      debugPrint('Daily progress updated successfully!');
    } catch (e) {
      debugPrint('Error updating daily progress: $e');
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
          MaterialPageRoute(builder: (context) => HomePage()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => TimelinePage(
                  userPlantId: userPlantId,
                  plantName: plantName ?? 'Tanaman',
                ),
          ),
        );
        break;
      default:
        break;
    }
  }

  void _calculateAccuracy() {
    if (taskCompletionStatus.isEmpty) {
      setState(() {
        accuracy = 0.0;
      });
      return;
    }

    final completedTasks =
        taskCompletionStatus.values.where((completed) => completed).length;
    final totalTasks = taskCompletionStatus.length;

    setState(() {
      accuracy = totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0.0;
    });
  }

  String _calculateAccuracyLevel(double accuracy) {
    if (accuracy == 100) return 'A';
    if (accuracy >= 75) return 'B';
    if (accuracy >= 50) return 'C';
    return 'D';
  }

  String _formatSelectedDate() {
    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    return '${selectedDate.day} ${months[selectedDate.month - 1]} ${selectedDate.year}';
  }

  Widget _buildTaskTable() {
    if (todayTasks.isEmpty) {
      return Center(
        child: Column(
          children: [
            Icon(Icons.task_alt, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Tidak ada tugas untuk hari ini',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? Colors.black26 : Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Table(
        columnWidths: {
          0: FixedColumnWidth(40),
          1: FlexColumnWidth(3),
          2: FlexColumnWidth(2),
          3: FixedColumnWidth(60),
        },
        children: [
          // Header
          TableRow(
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[700] : Colors.grey[100],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            children: [
              _buildTableHeader('No'),
              _buildTableHeader('Task'),
              _buildTableHeader('Type'),
              _buildTableHeader('Status'),
            ],
          ),
          // Data rows
          ...todayTasks.asMap().entries.map((entry) {
            final index = entry.key;
            final task = entry.value;
            final taskId = task['id'] as String;
            final isCompleted = taskCompletionStatus[taskId] ?? false;
            final taskTemplateData =
                task['task_templates'] as Map<String, dynamic>;
            final taskName = taskTemplateData['task_name'] as String;
            final isDaily = taskTemplateData['is_daily'] as bool;

            return TableRow(
              decoration: BoxDecoration(
                color:
                    isCompleted
                        ? (isDarkMode
                            ? Colors.green.withOpacity(0.1)
                            : Colors.green.withOpacity(0.05))
                        : (isDarkMode ? Colors.grey[800] : Colors.white),
              ),
              children: [
                _buildTableCell('${index + 1}', isDarkMode),
                _buildTableCell(taskName, isDarkMode),
                _buildTableCell(isDaily ? 'Harian' : 'Sekali', isDarkMode),
                GestureDetector(
                  onTap: () => _toggleTaskCompletion(taskId, !isCompleted),
                  child: Container(
                    height: 60,
                    alignment: Alignment.center,
                    child: Icon(
                      isCompleted
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color:
                          isCompleted
                              ? Colors.green
                              : (isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey[600]),
                      size: 24,
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Container(
      height: 50,
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTableCell(String text, bool isDarkMode) {
    return Container(
      height: 60,
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: isDarkMode ? Colors.white70 : Colors.black87,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    final backgroundColor = isDarkMode ? Colors.grey[900]! : Color(0xFFFFFCF5);
    final appBarColor = isDarkMode ? Colors.grey[850]! : Color(0xFFA7B59E);
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final buttonColor = isDarkMode ? Colors.green[800]! : Color(0xFF527A32);
    final cardColor = isDarkMode ? Colors.grey[800]! : Color(0xFFC4E9AB);
    final navBarColor = isDarkMode ? Colors.grey[850]! : Colors.white;
    final navIconColor = isDarkMode ? Colors.green[200]! : Colors.green;

    if (isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(buttonColor),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0,
        title: Text(
          "Task To Do",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.arrow_forward, color: textColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => AccuracyPage(
                        userPlantId: widget.userPlantId,
                        plantName: plantName,
                        plantTypeId: plantTypeId!,
                        selectedDate: widget.selectedDate,
                      ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                shape: StadiumBorder(),
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                elevation: 3,
                shadowColor: isDarkMode ? Colors.black : Colors.grey[400],
              ),
              child: Text(
                plantName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 30),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color:
                        isDarkMode
                            ? Colors.black54
                            : Colors.grey.withOpacity(0.3),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "DAY $currentDay - TASK PANEL",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                              color: textColor,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            _formatSelectedDate(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: textColor.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              accuracy > 75
                                  ? Colors.green
                                  : (accuracy > 40
                                      ? Colors.orange
                                      : Colors.red),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "${accuracy.toStringAsFixed(0)}%",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  _buildTaskTable(),
                  SizedBox(height: 15),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                    decoration: BoxDecoration(
                      color:
                          isDarkMode
                              ? Colors.grey[700]
                              : Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Progress: ${taskCompletionStatus.values.where((completed) => completed).length}/${taskCompletionStatus.length} tasks",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        Text(
                          "Grade: ${_calculateAccuracyLevel(accuracy)}",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color:
                                accuracy > 75
                                    ? Colors.green
                                    : (accuracy > 40
                                        ? Colors.orange
                                        : Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => AccuracyPage(
                          userPlantId: widget.userPlantId,
                          plantName: plantName,
                          plantTypeId: plantTypeId!,
                          selectedDate: widget.selectedDate,
                        ),
                  ),
                );
              },
              child: Text(
                "Check Your Hydroponic Ideal Condition >",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: navBarColor,
        selectedItemColor: navIconColor,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.note_add), label: "Tasks"),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: "Add"),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: "Timeline",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
