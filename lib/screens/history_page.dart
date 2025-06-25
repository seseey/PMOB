import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../provider/theme_provider.dart';
import '../services/user_statistics_service.dart';
import '../services/plant_history_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  User? currentUser;
  Map<String, dynamic>? userData;
  bool isLoading = false;
  String errorMessage = '';

  // Services
  final UserStatisticsService _userStatsService = UserStatisticsService();
  final PlantingHistoryService _plantingHistoryService =
      PlantingHistoryService();

  // Data
  Map<String, dynamic>? userStatistics;
  List<Map<String, dynamic>> recentPlantingHistory = [];

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserAndProfile();
    _loadHistoryData();
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
          final response =
              await Supabase.instance.client
                  .from('users')
                  .select()
                  .eq('id', currentUser!.id)
                  .single();

          userData = response;
        } catch (e) {
          userData = {
            'username': currentUser!.email?.split('@')[0] ?? 'User',
            'profile_photo': null,
          };
        }
      } else {
        errorMessage = 'Tidak ada user yang login';
      }
    } catch (e) {
      errorMessage = 'Error: ${e.toString()}';
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadHistoryData() async {
    if (currentUser == null) return;

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      // Load user statistics
      final stats = await _userStatsService.getUserStatistics(currentUser!.id);

      // Load recent planting history (from all user plants)
      final history = await _getRecentPlantingHistory();

      setState(() {
        userStatistics = stats;
        recentPlantingHistory = history;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading history data: $e';
        isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _getRecentPlantingHistory() async {
    try {
      final supabase = Supabase.instance.client;

      // First get user plants, then get history for each
      final userPlantsResponse = await supabase
          .from('user_plants')
          .select('id')
          .eq('user_id', currentUser!.id);

      List<Map<String, dynamic>> allHistory = [];

      for (var plant in userPlantsResponse as List) {
        final history = await _plantingHistoryService
            .getPlantingHistoryForPlant(plant['id']);
        allHistory.addAll(history);
      }

      // Sort by date and take recent entries
      allHistory.sort((a, b) => b['action_date'].compareTo(a['action_date']));
      return allHistory.take(10).toList();
    } catch (e) {
      debugPrint('Error getting recent planting history: $e');
      return [];
    }
  }

  Widget _buildStatisticsCard(Color textColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFA7B59E).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFA7B59E).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Plant Statistics",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  "Total Plants",
                  "${userStatistics?['total_plants'] ?? 0}",
                  Icons.local_florist,
                  textColor,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  "Active Plants",
                  "${userStatistics?['active_plants'] ?? 0}",
                  Icons.eco,
                  textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  "Completed",
                  "${userStatistics?['completed_plants'] ?? 0}",
                  Icons.check_circle,
                  textColor,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  "Success Rate",
                  "${userStatistics?['success_rate']?.toStringAsFixed(1) ?? '0.0'}%",
                  Icons.trending_up,
                  textColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFFED8B1).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFA7B59E), size: 24),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: textColor.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection(Color textColor) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Recent Activity",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Your latest planting activities",
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 15),
          if (recentPlantingHistory.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  "No recent activity",
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            )
          else
            ...recentPlantingHistory.map(
              (activity) => _buildActivityItem(activity, textColor),
            ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity, Color textColor) {
    IconData icon;
    Color iconColor;

    switch (activity['action_type']) {
      case 'planted':
        icon = Icons.local_florist;
        iconColor = Colors.green;
        break;
      case 'watered':
        icon = Icons.water_drop;
        iconColor = Colors.blue;
        break;
      case 'fertilized':
        icon = Icons.grass;
        iconColor = Colors.orange;
        break;
      case 'harvested':
        icon = Icons.check_circle;
        iconColor = Colors.purple;
        break;
      default:
        icon = Icons.notes;
        iconColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFED8B1).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatActionType(activity['action_type']),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                if (activity['description'] != null)
                  Text(
                    activity['description'],
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                Text(
                  _formatDate(activity['action_date']),
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatActionType(String actionType) {
    switch (actionType) {
      case 'planted':
        return 'Plant Started';
      case 'watered':
        return 'Watered';
      case 'fertilized':
        return 'Fertilized';
      case 'harvested':
        return 'Harvested';
      default:
        return actionType.toUpperCase();
    }
  }

  String _formatDate(dynamic date) {
    try {
      DateTime dateTime = DateTime.parse(date.toString());
      Duration difference = DateTime.now().difference(dateTime);

      if (difference.inDays > 0) {
        return '${difference.inDays} days ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hours ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return date.toString();
    }
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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: appBarColor,
        title: Text(
          "Your Plant Memory",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: textColor,
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            color: textColor,
            onPressed: _loadHistoryData,
          ),
        ],
      ),
      body: Container(
        color: backgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child:
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : errorMessage.isNotEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          errorMessage,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _loadHistoryData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                  : RefreshIndicator(
                    onRefresh: _loadHistoryData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "History Higrowers",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Modified user info section to match drawer
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundImage:
                                      userData != null &&
                                              userData!['profile_photo'] != null
                                          ? NetworkImage(
                                            userData!['profile_photo'],
                                          )
                                          : const AssetImage(
                                                'images/default.jpg',
                                              )
                                              as ImageProvider,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  userData?['username'] ??
                                      currentUser?.email?.split('@')[0] ??
                                      "User",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildStatisticsCard(textColor),
                          const SizedBox(height: 20),
                          _buildRecentActivitySection(textColor),
                        ],
                      ),
                    ),
                  ),
        ),
      ),
    );
  }
}
