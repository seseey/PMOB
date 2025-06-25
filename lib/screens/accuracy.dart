import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/theme_provider.dart';
import '../services/accuracy_check_service.dart';
import '../services/accuracy_parameter_service.dart';
import '../services/farmer_massage_service.dart';
import '../services/daily_progress_service.dart';

class AccuracyPage extends StatefulWidget {
  // 🔥 SUPPORT BOTH: UUID dan String ID biasa
  final String userPlantId; // Bisa UUID atau string biasa
  final String plantName;
  final String plantTypeId; // Bisa UUID atau string biasa (plant_001, etc)
  final DateTime selectedDate;

  const AccuracyPage({
    Key? key,
    required this.userPlantId,
    required this.plantName,
    required this.plantTypeId,
    required this.selectedDate,
  }) : super(key: key);

  @override
  _AccuracyPageState createState() => _AccuracyPageState();
}

class _AccuracyPageState extends State<AccuracyPage>
    with SingleTickerProviderStateMixin {
  final AccuracyParameterService _parameterService = AccuracyParameterService();
  final AccuracyCheckService _checkService = AccuracyCheckService();
  final FarmerMessageService _messageService = FarmerMessageService();
  final DailyProgressService _progressService = DailyProgressService();

  late TabController _tabController;
  List<Map<String, dynamic>> accuracyParameters = [];
  List<Map<String, dynamic>> accuracyChecks = [];
  List<Map<String, dynamic>> dailyProgress = [];
  Map<String, dynamic>? farmerMessage;

  Map<String, dynamic> userResponses = {};
  double overallAccuracy = 0.0;
  bool isLoading = true;
  int currentDay = 1;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // 🔍 DEBUG: Print parameter yang diterima
    debugPrint('🔍 AccuracyPage initialized with:');
    debugPrint(
      '   userPlantId: ${widget.userPlantId} (${widget.userPlantId.runtimeType})',
    );
    debugPrint('   plantName: ${widget.plantName}');
    debugPrint(
      '   plantTypeId: ${widget.plantTypeId} (${widget.plantTypeId.runtimeType})',
    );
    debugPrint('   selectedDate: ${widget.selectedDate}');

    // 🔥 FLEXIBLE VALIDATION: Accept both UUID and regular strings
    if (!_isValidId(widget.userPlantId)) {
      debugPrint('🚨 Invalid userPlantId format: ${widget.userPlantId}');
      setState(() {
        errorMessage = 'Invalid plant ID format: ${widget.userPlantId}';
        isLoading = false;
      });
      return;
    }

    if (!_isValidId(widget.plantTypeId)) {
      debugPrint('🚨 Invalid plantTypeId format: ${widget.plantTypeId}');
      setState(() {
        errorMessage = 'Invalid plant type ID format: ${widget.plantTypeId}';
        isLoading = false;
      });
      return;
    }

    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 🔍 FLEXIBLE ID VALIDATION: UUID atau string biasa
  static bool _isValidId(String value) {
    if (value.isEmpty) return false;

    // Check if it's a UUID format
    final uuidPattern = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );

    // Check if it's a regular ID format (letters, numbers, underscore, dash)
    final regularIdPattern = RegExp(r'^[a-zA-Z0-9_-]+$');

    bool isUuid = uuidPattern.hasMatch(value);
    bool isRegularId = regularIdPattern.hasMatch(value);

    debugPrint(
      '🔍 ID Validation for "$value": UUID=$isUuid, Regular=$isRegularId',
    );

    return isUuid || isRegularId;
  }

  // 🛡️ SAFE PARSING - Support multiple ID formats
  static String safeParse(dynamic value, [String defaultValue = '']) {
    if (value == null) return defaultValue;
    try {
      if (value is String) return value.trim();
      return value.toString().trim();
    } catch (e) {
      debugPrint('⚠️ Error parsing string: $e');
      return defaultValue;
    }
  }

  static int safeParseInt(dynamic value, [int defaultValue = 0]) {
    if (value == null) return defaultValue;

    try {
      // Jika sudah int, return langsung
      if (value is int) return value;

      // Jika double, convert ke int
      if (value is double) {
        if (value.isFinite) return value.round();
        return defaultValue;
      }

      // Jika string, proses dengan hati-hati
      if (value is String) {
        String cleanValue = value.trim();

        // Cek jika kosong
        if (cleanValue.isEmpty) return defaultValue;

        // 🔥 IMPROVED: Jangan parse ID strings sebagai int!
        if (_isValidId(cleanValue) && !_isNumericString(cleanValue)) {
          debugPrint('🚨 Attempted to parse ID as int: $cleanValue - SKIPPING');
          return defaultValue;
        }

        // Hapus semua karakter non-digit kecuali minus dan titik
        cleanValue = cleanValue.replaceAll(RegExp(r'[^\d.-]'), '');
        if (cleanValue.isEmpty) return defaultValue;

        // Gunakan tryParse yang aman
        final result = int.tryParse(cleanValue);
        if (result != null) return result;

        // Coba parse sebagai double dulu
        final doubleResult = double.tryParse(cleanValue);
        if (doubleResult != null && doubleResult.isFinite) {
          return doubleResult.round();
        }
      }

      return defaultValue;
    } catch (e) {
      debugPrint('⚠️ Error parsing int: $e, value: $value');
      return defaultValue;
    }
  }

  // Helper to check if string contains only numbers
  static bool _isNumericString(String value) {
    return RegExp(r'^\d+$').hasMatch(value);
  }

  static double safeParseDouble(dynamic value, [double defaultValue = 0.0]) {
    if (value == null) return defaultValue;

    try {
      if (value is double) {
        return value.isFinite ? value : defaultValue;
      }

      if (value is int) return value.toDouble();

      if (value is String) {
        String cleanValue = value.trim();
        if (cleanValue.isEmpty) return defaultValue;

        // 🔥 IMPROVED: Jangan parse ID strings sebagai double!
        if (_isValidId(cleanValue) && !_isNumericString(cleanValue)) {
          debugPrint(
            '🚨 Attempted to parse ID as double: $cleanValue - SKIPPING',
          );
          return defaultValue;
        }

        cleanValue = cleanValue.replaceAll(RegExp(r'[^\d.-]'), '');
        if (cleanValue.isEmpty) return defaultValue;

        final result = double.tryParse(cleanValue);
        if (result != null && result.isFinite) return result;
      }

      return defaultValue;
    } catch (e) {
      debugPrint('⚠️ Error parsing double: $e, value: $value');
      return defaultValue;
    }
  }

  static bool safeParseBool(dynamic value, [bool defaultValue = false]) {
    if (value == null) return defaultValue;
    try {
      if (value is bool) return value;
      if (value is String) {
        String cleanValue = value.toLowerCase().trim();
        return cleanValue == 'true' || cleanValue == '1' || cleanValue == 'yes';
      }
      if (value is int) return value == 1;
      return defaultValue;
    } catch (e) {
      debugPrint('⚠️ Error parsing bool: $e');
      return defaultValue;
    }
  }

  static DateTime safeParseDateTime(dynamic value, [DateTime? defaultValue]) {
    defaultValue ??= DateTime.now();
    try {
      if (value == null) return defaultValue;
      if (value is DateTime) return value;
      if (value is String) {
        String cleanValue = value.trim();
        if (cleanValue.isEmpty) return defaultValue;

        DateTime? parsed = DateTime.tryParse(cleanValue);
        if (parsed != null) return parsed;
      }
      return defaultValue;
    } catch (e) {
      debugPrint('⚠️ Error parsing datetime: $e');
      return defaultValue;
    }
  }

  Map<String, dynamic> _sanitizeDataMap(dynamic rawData) {
    try {
      if (rawData == null) {
        debugPrint('🔍 _sanitizeDataMap: rawData is null');
        return <String, dynamic>{};
      }

      if (rawData is! Map) {
        debugPrint(
          '🔍 _sanitizeDataMap: rawData is not a Map, type: ${rawData.runtimeType}',
        );
        return <String, dynamic>{};
      }

      Map<String, dynamic> sanitized = <String, dynamic>{};
      final Map<dynamic, dynamic> rawMap = rawData;

      debugPrint('🔍 _sanitizeDataMap: Processing ${rawMap.length} keys');

      rawMap.forEach((key, value) {
        try {
          String safeKey = safeParse(key);
          if (safeKey.isNotEmpty) {
            // 🔥 SPECIAL HANDLING: Keep ID fields as strings (both UUID and regular)
            if (safeKey.endsWith('_id') || safeKey == 'id') {
              sanitized[safeKey] = safeParse(value);
              debugPrint('🔍 Added ID field: $safeKey = ${sanitized[safeKey]}');
            } else {
              sanitized[safeKey] = value;
              debugPrint(
                '🔍 Added field: $safeKey = $value (${value.runtimeType})',
              );
            }
          } else {
            debugPrint('⚠️ Skipped empty key for value: $value');
          }
        } catch (e) {
          debugPrint('⚠️ Error processing map key: $key, error: $e');
        }
      });

      debugPrint('✅ _sanitizeDataMap: Sanitized ${sanitized.length} items');
      return sanitized;
    } catch (e) {
      debugPrint('🚨 Critical error in _sanitizeDataMap: $e');
      return <String, dynamic>{};
    }
  }

  List<Map<String, dynamic>> _sanitizeDataList(dynamic rawData) {
    try {
      if (rawData == null) {
        debugPrint('🔍 _sanitizeDataList: rawData is null');
        return [];
      }

      if (rawData is! List) {
        debugPrint(
          '🔍 _sanitizeDataList: rawData is not a List, type: ${rawData.runtimeType}',
        );
        if (rawData is Map) {
          debugPrint('🔧 Converting single Map to List');
          return [_sanitizeDataMap(rawData)];
        }
        return [];
      }

      List<Map<String, dynamic>> sanitized = [];
      final List<dynamic> rawList = rawData;

      debugPrint('🔍 _sanitizeDataList: Processing ${rawList.length} items');

      for (int i = 0; i < rawList.length; i++) {
        try {
          Map<String, dynamic> sanitizedItem = _sanitizeDataMap(rawList[i]);
          if (sanitizedItem.isNotEmpty) {
            sanitized.add(sanitizedItem);
            debugPrint('✅ Added item $i: ${sanitizedItem.keys.toList()}');
          } else {
            debugPrint('⚠️ Skipped empty item at index $i');
          }
        } catch (e) {
          debugPrint('⚠️ Error processing list item $i: $e');
        }
      }

      debugPrint('✅ _sanitizeDataList: Sanitized ${sanitized.length} items');
      return sanitized;
    } catch (e) {
      debugPrint('🚨 Critical error in _sanitizeDataList: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadChecksWithErrorHandling() async {
    try {
      debugPrint(
        '🔍 Loading accuracy checks for userPlantId: ${widget.userPlantId}...',
      );
      debugPrint('🔍 userPlantId type: ${widget.userPlantId.runtimeType}');
      debugPrint('🔍 userPlantId valid: ${_isValidId(widget.userPlantId)}');

      final response = await _checkService.getAccuracyChecksForPlant(
        widget.userPlantId, // Support both UUID and regular string
      );

      debugPrint('📥 Service response type: ${response.runtimeType}');
      debugPrint(
        '📥 Service response length: ${response is List ? response.length : 'not a list'}',
      );

      if (response is List && response.isNotEmpty) {
        debugPrint('🔍 First item type: ${response.first.runtimeType}');
        debugPrint('🔍 First item: ${response.first}');

        if (response.first is Map) {
          final firstMap = response.first as Map;
          debugPrint('🔍 First item keys: ${firstMap.keys.toList()}');
        }
      }

      return _sanitizeDataList(response);
    } catch (e, stackTrace) {
      debugPrint('🚨 ERROR loading accuracy checks: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadParametersWithErrorHandling() async {
    try {
      debugPrint(
        '🔍 Loading parameters for plantTypeId: ${widget.plantTypeId}...',
      );
      debugPrint('🔍 plantTypeId type: ${widget.plantTypeId.runtimeType}');
      debugPrint('🔍 plantTypeId valid: ${_isValidId(widget.plantTypeId)}');

      final response = await _parameterService
          .getAccuracyParametersForPlantType(
            widget.plantTypeId,
          ); // Support both formats

      debugPrint('📥 Parameters response type: ${response.runtimeType}');
      debugPrint('📥 Parameters response: $response');

      return _sanitizeDataList(response);
    } catch (e, stackTrace) {
      debugPrint('🚨 ERROR loading parameters: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadProgressWithErrorHandling() async {
    try {
      debugPrint(
        '🔍 Loading progress for userPlantId: ${widget.userPlantId}...',
      );

      final response = await _progressService.getDailyProgressForPlant(
        widget.userPlantId, // Support both formats
      );

      debugPrint('📥 Progress response type: ${response.runtimeType}');
      debugPrint('📥 Progress response: $response');

      return _sanitizeDataList(response);
    } catch (e, stackTrace) {
      debugPrint('🚨 ERROR loading progress: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      return [];
    }
  }

  void _processExistingChecks() {
    try {
      debugPrint('🔄 Processing ${accuracyChecks.length} existing checks...');
      userResponses.clear();

      for (int i = 0; i < accuracyChecks.length; i++) {
        try {
          final check = accuracyChecks[i];
          if (check.isEmpty) {
            debugPrint('⚠️ Skipping empty check at index $i');
            continue;
          }

          debugPrint('🔍 Processing check $i: ${check.keys.toList()}');

          final parameterId = safeParse(check['accuracy_parameter_id']);
          final userValue = safeParse(check['user_value']);
          final accuracy = safeParseInt(check['accuracy_percentage']);

          debugPrint(
            '🔍 Check $i - parameterId: "$parameterId", userValue: "$userValue", accuracy: $accuracy',
          );

          if (parameterId.isNotEmpty && _isValidId(parameterId)) {
            userResponses[parameterId] = {
              'value': userValue,
              'accuracy': accuracy,
            };
            debugPrint('✅ Added response for parameter: $parameterId');
          } else {
            debugPrint(
              '⚠️ Skipping check with invalid parameterId: $parameterId',
            );
          }
        } catch (e) {
          debugPrint('🚨 Error processing check $i: $e');
        }
      }

      debugPrint(
        '✅ Processed ${userResponses.length} responses from ${accuracyChecks.length} checks',
      );
    } catch (e) {
      debugPrint('🚨 Critical error in _processExistingChecks: $e');
      userResponses.clear();
    }
  }

  Future<void> _loadFarmerMessage() async {
    if (accuracyParameters.isEmpty || !mounted) {
      debugPrint('🔍 Skipping farmer message - no parameters or not mounted');
      return;
    }

    try {
      int accuracyLevel = _getAccuracyLevel(overallAccuracy);
      debugPrint(
        '🔍 Loading farmer message for accuracy level: $accuracyLevel',
      );

      final parameterId = safeParse(accuracyParameters.first['id']);
      if (parameterId.isEmpty || !_isValidId(parameterId)) {
        debugPrint(
          '⚠️ Cannot load farmer message - invalid parameterId: $parameterId',
        );
        return;
      }

      final message = await _messageService.getFarmerMessage(
        accuracyParameterId: parameterId,
        accuracyPercentage: accuracyLevel,
      );

      if (mounted && message != null) {
        setState(() {
          farmerMessage = _sanitizeDataMap(message);
        });
        debugPrint('✅ Farmer message loaded successfully');
      }
    } catch (e) {
      debugPrint('🚨 Error loading farmer message: $e');
    }
  }

  Future<void> _loadAllData() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      debugPrint('🚀 Starting comprehensive data load...');

      await Future.wait([
        _loadParametersData().timeout(Duration(seconds: 15)),
        _loadChecksData().timeout(Duration(seconds: 15)),
        _loadProgressData().timeout(Duration(seconds: 15)),
      ]).timeout(Duration(seconds: 45));

      _processExistingChecks();
      _calculateOverallAccuracy();
      await _loadFarmerMessage();

      debugPrint('✅ All data loaded successfully');
    } catch (e, stackTrace) {
      debugPrint('🚨 CRITICAL ERROR in _loadAllData: $e');
      debugPrint('📍 Stack trace: $stackTrace');

      if (mounted) {
        setState(() {
          errorMessage = 'Failed to load data: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadParametersData() async {
    try {
      debugPrint('🔍 Loading parameters data...');
      final parameters = await _loadParametersWithErrorHandling();
      if (mounted) {
        setState(() {
          accuracyParameters = parameters;
        });
        debugPrint('✅ Parameters loaded: ${parameters.length} items');
      }
    } catch (e) {
      debugPrint('🚨 Error in _loadParametersData: $e');
      rethrow;
    }
  }

  Future<void> _loadChecksData() async {
    try {
      debugPrint('🔍 Loading checks data...');
      final checks = await _loadChecksWithErrorHandling();
      if (mounted) {
        setState(() {
          accuracyChecks = checks;
          currentDay = checks.length + 1;
        });
        debugPrint(
          '✅ Checks loaded: ${checks.length} items, currentDay: $currentDay',
        );
      }
    } catch (e) {
      debugPrint('🚨 Error in _loadChecksData: $e');
      rethrow;
    }
  }

  Future<void> _loadProgressData() async {
    try {
      debugPrint('🔍 Loading progress data...');
      final progress = await _loadProgressWithErrorHandling();
      if (mounted) {
        setState(() {
          dailyProgress = progress;
        });
        debugPrint('✅ Progress loaded: ${progress.length} items');
      }
    } catch (e) {
      debugPrint('🚨 Error in _loadProgressData: $e');
      rethrow;
    }
  }

  int _getAccuracyLevel(double accuracy) {
    if (accuracy >= 88) return 100;
    if (accuracy >= 63) return 75;
    if (accuracy >= 38) return 50;
    return 25;
  }

  void _calculateOverallAccuracy() {
    try {
      debugPrint(
        '🔍 Calculating overall accuracy from ${userResponses.length} responses...',
      );

      if (userResponses.isEmpty) {
        if (mounted) {
          setState(() => overallAccuracy = 0.0);
        }
        debugPrint('📊 Overall accuracy: 0.0% (no responses)');
        return;
      }

      double total = 0.0;
      int count = 0;

      userResponses.forEach((key, response) {
        try {
          if (response != null && response is Map<String, dynamic>) {
            if (response.containsKey('accuracy')) {
              final accuracy = safeParseDouble(response['accuracy']);
              if (accuracy >= 0 && accuracy <= 100) {
                total += accuracy;
                count++;
                debugPrint('📊 Response $key: $accuracy%');
              }
            }
          }
        } catch (e) {
          debugPrint('⚠️ Error processing response $key: $e');
        }
      });

      final calculatedAccuracy = count > 0 ? total / count : 0.0;

      if (mounted) {
        setState(() {
          overallAccuracy = calculatedAccuracy;
        });
      }

      debugPrint(
        '📊 Overall accuracy: ${calculatedAccuracy.toStringAsFixed(1)}% from $count responses',
      );
    } catch (e) {
      debugPrint('🚨 Error calculating accuracy: $e');
      if (mounted) {
        setState(() => overallAccuracy = 0.0);
      }
    }
  }

  Future<void> _submitAccuracyCheck(
    String parameterId,
    String userValue,
    int accuracyPercentage,
  ) async {
    if (parameterId.isEmpty || !_isValidId(parameterId)) {
      _showErrorSnackBar('Invalid parameter ID: $parameterId');
      return;
    }

    try {
      debugPrint(
        '🔍 Submitting accuracy check: $parameterId = $userValue ($accuracyPercentage%)',
      );

      await _checkService.submitAccuracyCheck(
        userPlantId: widget.userPlantId,
        accuracyParameterId: parameterId,
        checkDate: DateTime.now(),
        userValue: userValue,
        accuracyPercentage: accuracyPercentage,
        isAccurate: accuracyPercentage >= 75,
      );

      if (mounted) {
        setState(() {
          userResponses[parameterId] = {
            'value': userValue,
            'accuracy': accuracyPercentage,
          };
        });

        _calculateOverallAccuracy();
        await _loadFarmerMessage();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Accuracy check saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        debugPrint('✅ Accuracy check submitted successfully');
      }
    } catch (e) {
      debugPrint('🚨 Error submitting accuracy check: $e');
      _showErrorSnackBar('Error saving accuracy check: ${e.toString()}');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 75) return Colors.green;
    if (accuracy >= 50) return Colors.orange;
    if (accuracy >= 25) return Colors.yellow[700]!;
    return Colors.red;
  }

  String _getAccuracyGrade(double accuracy) {
    if (accuracy >= 88) return 'A';
    if (accuracy >= 63) return 'B';
    if (accuracy >= 38) return 'C';
    return 'D';
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Color(0xFFF6F6E9),
      appBar: _buildAppBar(isDarkMode),
      body: _buildBody(isDarkMode),
    );
  }

  // Rest of the UI building methods remain the same...
  // Implementing the key UI components:

  PreferredSizeWidget _buildAppBar(bool isDarkMode) {
    return AppBar(
      backgroundColor: isDarkMode ? Colors.grey[850] : Color(0xFFA7B59E),
      title: Text(
        'Accuracy Check',
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      elevation: 0,
      iconTheme: IconThemeData(color: isDarkMode ? Colors.white : Colors.black),
    );
  }

  Widget _buildBody(bool isDarkMode) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading accuracy data...'),
            SizedBox(height: 8),
            Text(
              'userPlantId: ${widget.userPlantId}\nplantTypeId: ${widget.plantTypeId}',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                errorMessage!,
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(onPressed: _loadAllData, child: Text('Retry')),
            SizedBox(height: 8),
            Text(
              'Debug Info:\nParameters: ${accuracyParameters.length}\nChecks: ${accuracyChecks.length}\nProgress: ${dailyProgress.length}',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildPlantHeader(isDarkMode),
        _buildOverallAccuracyCard(isDarkMode),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildCheckTab(isDarkMode),
              _buildHistoryTab(isDarkMode),
              _buildProgressTab(isDarkMode),
            ],
          ),
        ),
        Container(
          color: isDarkMode ? Colors.grey[850] : Color(0xFFA7B59E),
          child: TabBar(
            controller: _tabController,
            labelColor: isDarkMode ? Colors.white : Colors.black,
            unselectedLabelColor:
                isDarkMode ? Colors.grey[400] : Colors.grey[600],
            indicatorColor: isDarkMode ? Colors.green[300] : Colors.green[700],
            tabs: [
              Tab(icon: Icon(Icons.check_circle), text: 'Check'),
              Tab(icon: Icon(Icons.history), text: 'History'),
              Tab(icon: Icon(Icons.trending_up), text: 'Progress'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlantHeader(bool isDarkMode) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.green[800] : Color(0xFF527A32),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.eco, color: Colors.white),
          SizedBox(width: 8),
          Text(
            widget.plantName,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: 12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Day $currentDay',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallAccuracyCard(bool isDarkMode) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Overall Accuracy',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${overallAccuracy.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: _getAccuracyColor(overallAccuracy),
                ),
              ),
              SizedBox(width: 12),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getAccuracyColor(overallAccuracy),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getAccuracyGrade(overallAccuracy),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          LinearProgressIndicator(
            value: overallAccuracy / 100,
            backgroundColor: isDarkMode ? Colors.grey[600] : Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              _getAccuracyColor(overallAccuracy),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckTab(bool isDarkMode) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          if (accuracyParameters.isEmpty)
            _buildEmptyState(isDarkMode, 'No parameters to check today')
          else
            ...accuracyParameters
                .map(
                  (parameter) =>
                      _buildParameterCheckCard(parameter, isDarkMode),
                )
                .toList(),

          if (farmerMessage != null) ...[
            SizedBox(height: 20),
            _buildFarmerMessageCard(isDarkMode),
          ],
        ],
      ),
    );
  }

  Widget _buildParameterCheckCard(
    Map<String, dynamic> parameter,
    bool isDarkMode,
  ) {
    final parameterId = safeParse(parameter['id']);
    final parameterName = safeParse(
      parameter['parameter_name'],
      'Unknown Parameter',
    );
    final description = safeParse(parameter['parameter_description']);
    final expectedValue = safeParse(parameter['expected_value']);

    final currentResponse = userResponses[parameterId];

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      color: isDarkMode ? Colors.grey[800] : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              parameterName,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            if (description.isNotEmpty) ...[
              SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                ),
              ),
            ],
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    isDarkMode
                        ? Colors.blue[900]?.withValues(alpha: 0.3)
                        : Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDarkMode ? Colors.blue[700]! : Colors.blue[200]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: isDarkMode ? Colors.blue[300] : Colors.blue[700],
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Expected: $expectedValue',
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: isDarkMode ? Colors.blue[300] : Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Text(
              'How does your plant condition compare?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 12),
            ...[
              'Perfect (100%)',
              'Good (75%)',
              'Fair (50%)',
              'Poor (25%)',
            ].map((option) {
              final percentage = _extractPercentageFromOption(option);
              final currentAccuracy =
                  currentResponse != null
                      ? safeParseInt(currentResponse['accuracy'])
                      : 0;
              final isSelected = currentAccuracy == percentage;

              return GestureDetector(
                onTap:
                    parameterId.isNotEmpty && _isValidId(parameterId)
                        ? () => _submitAccuracyCheck(
                          parameterId,
                          option,
                          percentage,
                        )
                        : null,
                child: Container(
                  margin: EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? (isDarkMode
                                ? Colors.green[800]
                                : Colors.green[100])
                            : (isDarkMode ? Colors.grey[700] : Colors.grey[50]),
                    border: Border.all(
                      color:
                          isSelected
                              ? Colors.green
                              : (isDarkMode
                                  ? Colors.grey[600]!
                                  : Colors.grey[300]!),
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: isSelected ? Colors.green : Colors.grey,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          option,
                          style: TextStyle(
                            fontWeight:
                                isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check, color: Colors.green, size: 20),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  int _extractPercentageFromOption(String option) {
    try {
      final match = RegExp(r'\((\d+)%\)').firstMatch(option);
      if (match != null) {
        return int.tryParse(match.group(1)!) ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint('⚠️ Error extracting percentage: $e');
      return 0;
    }
  }

  Widget _buildFarmerMessageCard(bool isDarkMode) {
    final message = safeParse(farmerMessage!['message']);
    final tips = safeParse(farmerMessage!['tips']);

    return Card(
      color:
          isDarkMode
              ? Colors.amber[900]?.withValues(alpha: 0.3)
              : Colors.amber[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person,
                  color: isDarkMode ? Colors.amber[300] : Colors.amber[700],
                ),
                SizedBox(width: 8),
                Text(
                  'Farmer\'s Message',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.amber[300] : Colors.amber[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.amber[100] : Colors.amber[800],
              ),
            ),
            if (tips.isNotEmpty) ...[
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      isDarkMode
                          ? Colors.amber[800]?.withValues(alpha: 0.3)
                          : Colors.amber[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 16,
                      color: isDarkMode ? Colors.amber[300] : Colors.amber[700],
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Tip: $tips',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color:
                              isDarkMode
                                  ? Colors.amber[200]
                                  : Colors.amber[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab(bool isDarkMode) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          if (accuracyChecks.isEmpty)
            _buildEmptyState(isDarkMode, 'No accuracy checks yet')
          else
            ...accuracyChecks
                .map((check) => _buildHistoryCard(check, isDarkMode))
                .toList(),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> check, bool isDarkMode) {
    if (check.isEmpty) return SizedBox.shrink();

    final checkDate = safeParseDateTime(check['check_date']);
    final userValue = safeParse(check['user_value']);
    final accuracyPercentage = safeParseInt(check['accuracy_percentage']);
    final isAccurate = safeParseBool(check['is_accurate']);

    String parameterName = 'Unknown Parameter';
    try {
      final parameterInfo = check['accuracy_parameters'];
      if (parameterInfo is Map<String, dynamic> &&
          parameterInfo.containsKey('parameter_name')) {
        parameterName = safeParse(
          parameterInfo['parameter_name'],
          'Unknown Parameter',
        );
      }
    } catch (e) {
      debugPrint('Error parsing parameter info: $e');
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      color: isDarkMode ? Colors.grey[800] : Colors.white,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isAccurate ? Colors.green : Colors.orange,
          child: Icon(
            isAccurate ? Icons.check : Icons.warning,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          parameterName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Response: $userValue',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
              ),
            ),
            Text(
              'Date: ${checkDate.day}/${checkDate.month}/${checkDate.year}',
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getAccuracyColor(accuracyPercentage.toDouble()),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$accuracyPercentage%',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressTab(bool isDarkMode) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          if (dailyProgress.isEmpty)
            _buildEmptyState(isDarkMode, 'No progress data available')
          else
            ...dailyProgress
                .map((progress) => _buildProgressCard(progress, isDarkMode))
                .toList(),
        ],
      ),
    );
  }

  Widget _buildProgressCard(Map<String, dynamic> progress, bool isDarkMode) {
    final progressDate = safeParseDateTime(progress['progress_date']);
    final totalTasks = safeParseInt(progress['total_tasks']);
    final completedTasks = safeParseInt(progress['completed_tasks']);
    final totalAccuracyChecks = safeParseInt(progress['total_accuracy_checks']);
    final completedAccuracyChecks = safeParseInt(
      progress['completed_accuracy_checks'],
    );
    final overallCompletion = safeParseInt(
      progress['overall_completion_percentage'],
    );

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      color: isDarkMode ? Colors.grey[800] : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${progressDate.day}/${progressDate.month}/${progressDate.year}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getAccuracyColor(overallCompletion.toDouble()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$overallCompletion%',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            _buildProgressRow('Tasks', completedTasks, totalTasks, isDarkMode),
            SizedBox(height: 8),
            _buildProgressRow(
              'Accuracy Checks',
              completedAccuracyChecks,
              totalAccuracyChecks,
              isDarkMode,
            ),
            SizedBox(height: 12),
            LinearProgressIndicator(
              value: overallCompletion / 100,
              backgroundColor: isDarkMode ? Colors.grey[600] : Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getAccuracyColor(overallCompletion.toDouble()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressRow(
    String label,
    int completed,
    int total,
    bool isDarkMode,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
          ),
        ),
        Text(
          '$completed/$total',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDarkMode, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: 64,
            color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
