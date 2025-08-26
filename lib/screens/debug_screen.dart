import 'package:flutter/material.dart';
import '../services/breed_data_service.dart';
import '../services/ml_service.dart';
import '../models/cat_breed.dart';
import '../utils/theme.dart';

/// Debug screen to test model integration
class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final BreedDataService _breedService = BreedDataService();
  final MLService _mlService = MLService();
  
  bool _isLoading = true;
  String _status = 'Initializing...';
  List<CatBreed> _breeds = [];
  Map<String, dynamic> _debugInfo = {};

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    final diagnostics = <String, dynamic>{};
    
    try {
      setState(() {
        _status = 'Testing Breed Data Service...';
      });
      
      // Test breed data service
      final breedResult = await _breedService.initialize();
      diagnostics['breed_service_initialized'] = breedResult;
      
      if (breedResult) {
        _breeds = _breedService.getAllBreeds();
        diagnostics['breeds_loaded'] = _breeds.length;
        diagnostics['sample_breed'] = _breeds.isNotEmpty ? _breeds.first.name : 'none';
      }
      
      setState(() {
        _status = 'Testing ML Service...';
      });
      
      // Test ML service
      final mlResult = await _mlService.initialize();
      diagnostics['ml_service_initialized'] = mlResult;
      diagnostics['ml_service_ready'] = _mlService.isInitialized;
      
      setState(() {
        _status = 'Diagnostics complete!';
        _isLoading = false;
        _debugInfo = diagnostics;
      });
      
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _isLoading = false;
        _debugInfo = {
          'error': e.toString(),
          ...diagnostics,
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Model Integration Debug',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: _isLoading ? _buildLoadingState() : _buildDebugInfo(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            _status,
            style: AppTextStyles.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDebugInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Diagnostic Results',
                    style: AppTextStyles.headline3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Status: $_status',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _status.contains('Error') 
                          ? AppTheme.errorColor 
                          : AppTheme.successColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._debugInfo.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 140,
                            child: Text(
                              '${entry.key}:',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              entry.value.toString(),
                              style: AppTextStyles.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          
          if (_breeds.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sample Breeds (${_breeds.length} total)',
                      style: AppTextStyles.headline3,
                    ),
                    const SizedBox(height: 16),
                    ..._breeds.take(5).map((breed) {
                      return Card(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        child: ListTile(
                          title: Text(breed.name),
                          subtitle: Text(breed.origin),
                          trailing: breed.mlIndex != null 
                              ? Chip(
                                  label: Text('ML: ${breed.mlIndex}'),
                                  backgroundColor: AppTheme.successColor.withOpacity(0.2),
                                )
                              : null,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Integration Status',
                    style: AppTextStyles.headline3,
                  ),
                  const SizedBox(height: 16),
                  _buildStatusItem(
                    'Model File',
                    _debugInfo['ml_service_initialized'] == true ? 'Ready' : 'Not Ready',
                    _debugInfo['ml_service_initialized'] == true,
                  ),
                  _buildStatusItem(
                    'Breed Database',
                    _debugInfo['breed_service_initialized'] == true ? 'Loaded' : 'Failed',
                    _debugInfo['breed_service_initialized'] == true,
                  ),
                  _buildStatusItem(
                    'Breeds Count',
                    '${_debugInfo['breeds_loaded'] ?? 0}',
                    (_debugInfo['breeds_loaded'] ?? 0) > 0,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, bool isGood) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium,
          ),
          Row(
            children: [
              Icon(
                isGood ? Icons.check_circle : Icons.error,
                color: isGood ? AppTheme.successColor : AppTheme.errorColor,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isGood ? AppTheme.successColor : AppTheme.errorColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}