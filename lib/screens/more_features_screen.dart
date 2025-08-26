import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/database_service.dart';
import '../services/stats_service.dart';
import '../services/breed_data_service.dart';
import '../utils/theme.dart';
import '../widgets/cat_paw_button.dart';
import 'debug_screen.dart';
import 'model_demo_screen.dart';

class MoreFeaturesScreen extends StatefulWidget {
  const MoreFeaturesScreen({super.key});

  @override
  State<MoreFeaturesScreen> createState() => _MoreFeaturesScreenState();
}

class _MoreFeaturesScreenState extends State<MoreFeaturesScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final StatsService _statsService = StatsService();
  final BreedDataService _breedDataService = BreedDataService();
  
  Map<String, int> _stats = {};
  bool _isLoading = true;
  bool _notificationsEnabled = true;
  bool _analyticsEnabled = true;
  String _selectedLanguage = 'English';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Initialize services
      if (!_databaseService.isInitialized) {
        await _databaseService.initialize();
      }
      if (!_statsService.isInitialized) {
        await _statsService.initialize();
      }

      // Load stats
      final stats = await _databaseService.getStatistics();
      
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ MoreFeaturesScreen: Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(
              Icons.eco,
              color: Colors.green,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              'More Features',
              style: AppTextStyles.headline2.copyWith(
                color: Colors.green,
                fontSize: 24,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading ? _buildLoadingView() : _buildContent(),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LoadingPawAnimation(
            message: 'Loading features...',
            size: 60,
          ),
          SizedBox(height: 16),
          Text(
            'Preparing amazing features for you...',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsOverview(),
          const SizedBox(height: 24),
          _buildToolsSection(),
          const SizedBox(height: 24),
          _buildDataManagementSection(),
          const SizedBox(height: 24),
          _buildSettingsSection(),
          const SizedBox(height: 24),
          _buildAboutSection(),
        ],
      ),
    );
  }

  Widget _buildStatsOverview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.analytics,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Your MeowAI Stats',
                style: AppTextStyles.headline3.copyWith(
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Recognitions',
                '${_stats['total_recognitions'] ?? 0}',
                Icons.camera_alt,
              ),
              _buildStatItem(
                'Breeds Found',
                '${_stats['unique_breeds'] ?? 0}',
                Icons.pets,
              ),
              _buildStatItem(
                'Favorites',
                '${_stats['favorites'] ?? 0}',
                Icons.favorite,
              ),
            ],
          ),
        ],
      ),
    ).animate().slideY().fadeIn();
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.headline2.copyWith(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: Colors.white.withOpacity(0.9),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildToolsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Developer Tools',
          style: AppTextStyles.headline3,
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _buildToolCard(
              icon: Icons.bug_report,
              title: 'Debug Console',
              description: 'View app diagnostics',
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DebugScreen(),
                  ),
                );
              },
            ),
            _buildToolCard(
              icon: Icons.smart_toy,
              title: 'ML Demo',
              description: 'Test AI model',
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ModelDemoScreen(),
                  ),
                );
              },
            ),
            _buildToolCard(
              icon: Icons.data_usage,
              title: 'Database Stats',
              description: 'View data usage',
              color: Colors.purple,
              onTap: _showDatabaseStats,
            ),
            _buildToolCard(
              icon: Icons.refresh,
              title: 'Refresh Data',
              description: 'Reload breed database',
              color: Colors.teal,
              onTap: _refreshBreedData,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToolCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Data Management',
          style: AppTextStyles.headline3,
        ),
        const SizedBox(height: 16),
        _buildActionCard(
          icon: Icons.cloud_download,
          title: 'Export Data',
          description: 'Export your recognition history and favorites',
          color: Colors.green,
          onTap: _exportData,
        ),
        _buildActionCard(
          icon: Icons.cloud_upload,
          title: 'Import Data',
          description: 'Import data from backup file',
          color: Colors.blue,
          onTap: _importData,
        ),
        _buildActionCard(
          icon: Icons.delete_sweep,
          title: 'Clear All Data',
          description: 'Remove all recognition history and favorites',
          color: Colors.red,
          onTap: _clearAllData,
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          description,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: AppTheme.textSecondary,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'App Settings',
          style: AppTextStyles.headline3,
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                  _showFeatureDialog('Notifications', 'Notification preferences have been updated.');
                },
                title: const Text('Push Notifications'),
                subtitle: const Text('Get notified about new breeds and features'),
                secondary: const Icon(Icons.notifications),
                activeColor: AppTheme.primaryColor,
              ),
              const Divider(height: 1),
              SwitchListTile(
                value: _analyticsEnabled,
                onChanged: (value) {
                  setState(() {
                    _analyticsEnabled = value;
                  });
                  _showFeatureDialog('Analytics', 'Analytics preferences have been updated.');
                },
                title: const Text('Usage Analytics'),
                subtitle: const Text('Help improve the app by sharing usage data'),
                secondary: const Icon(Icons.analytics),
                activeColor: AppTheme.primaryColor,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Language'),
                subtitle: Text(_selectedLanguage),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _showLanguageSelector,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About MeowAI',
          style: AppTextStyles.headline3,
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline, color: AppTheme.primaryColor),
                title: const Text('App Version'),
                subtitle: const Text('1.0.0 (Build 1)'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showFeatureDialog('Version', 'MeowAI v1.0.0 - Cat Breed Recognition App'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.help_outline, color: Colors.orange),
                title: const Text('Help & Support'),
                subtitle: const Text('Get help using the app'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showFeatureDialog('Help', 'Help and support features coming soon!'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.star_rate, color: Colors.amber),
                title: const Text('Rate the App'),
                subtitle: const Text('Leave a review on the app store'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showFeatureDialog('Rate App', 'Thank you for using MeowAI! Rating feature coming soon.'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.privacy_tip, color: Colors.green),
                title: const Text('Privacy Policy'),
                subtitle: const Text('Learn about data privacy'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showFeatureDialog('Privacy', 'Privacy policy and data handling information coming soon.'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDatabaseStats() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.data_usage, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            const Text('Database Statistics'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('Total Recognitions', '${_stats['total_recognitions'] ?? 0}'),
            _buildStatRow('Unique Breeds Found', '${_stats['unique_breeds'] ?? 0}'),
            _buildStatRow('Favorite Items', '${_stats['favorites'] ?? 0}'),
            _buildStatRow('Recognition This Week', '${_stats['last_week'] ?? 0}'),
            const SizedBox(height: 16),
            Text(
              'Database contains ${_breedDataService.getAllBreeds().length} total cat breeds.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  void _refreshBreedData() async {
    _showLoadingDialog('Refreshing breed database...');
    
    try {
      await _breedDataService.initialize();
      Navigator.of(context).pop(); // Close loading dialog
      
      _showFeatureDialog(
        'Success',
        'Breed database refreshed successfully! ${_breedDataService.getAllBreeds().length} breeds are now available.',
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      _showFeatureDialog('Error', 'Failed to refresh breed database: $e');
    }
  }

  void _exportData() {
    _showFeatureDialog(
      'Export Data',
      'Data export functionality is coming soon! This will allow you to backup your recognition history and favorites.',
    );
  }

  void _importData() {
    _showFeatureDialog(
      'Import Data',
      'Data import functionality is coming soon! This will allow you to restore from backup files.',
    );
  }

  void _clearAllData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Clear All Data'),
          ],
        ),
        content: const Text(
          'Are you sure you want to clear all recognition history and favorites? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              _showLoadingDialog('Clearing data...');
              
              try {
                await _databaseService.clearAllData();
                await _loadData(); // Refresh stats
                Navigator.of(context).pop(); // Close loading dialog
                
                _showFeatureDialog('Success', 'All data has been cleared successfully.');
              } catch (e) {
                Navigator.of(context).pop(); // Close loading dialog
                _showFeatureDialog('Error', 'Failed to clear data: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showLanguageSelector() {
    final languages = [
      'English', 'Spanish', 'French', 'German', 'Italian', 
      'Portuguese', 'Russian', 'Chinese', 'Japanese', 'Korean'
    ];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: languages.length,
            itemBuilder: (context, index) {
              final language = languages[index];
              return RadioListTile<String>(
                value: language,
                groupValue: _selectedLanguage,
                onChanged: (value) {
                  setState(() {
                    _selectedLanguage = value!;
                  });
                  Navigator.of(context).pop();
                  _showFeatureDialog('Language', 'Language changed to $value. Full localization coming soon!');
                },
                title: Text(language),
                activeColor: AppTheme.primaryColor,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LoadingPawAnimation(size: 40),
            const SizedBox(height: 16),
            Text(message, style: AppTextStyles.bodyMedium),
          ],
        ),
      ),
    );
  }

  void _showFeatureDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}