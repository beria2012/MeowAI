import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../utils/theme.dart';
import '../models/cat_breed.dart';
import '../services/breed_data_service.dart';
import '../services/ml_service.dart';
import 'breed_detail_screen.dart';

/// Demo screen showcasing the integrated trained model
class ModelDemoScreen extends StatefulWidget {
  const ModelDemoScreen({super.key});

  @override
  State<ModelDemoScreen> createState() => _ModelDemoScreenState();
}

class _ModelDemoScreenState extends State<ModelDemoScreen> {
  final BreedDataService _breedService = BreedDataService();
  final MLService _mlService = MLService();
  
  bool _isInitialized = false;
  String _status = 'Initializing...';
  List<CatBreed> _supportedBreeds = [];
  
  // Demo recognition results
  final List<Map<String, dynamic>> _demoResults = [
    {
      'breed_id': 'abyssinian',
      'confidence': 0.87,
      'image': 'assets/images/breeds/abyssinian.jpg'
    },
    {
      'breed_id': 'bengal', 
      'confidence': 0.82,
      'image': 'assets/images/breeds/bengal.jpg'
    },
    {
      'breed_id': 'british_shorthair',
      'confidence': 0.93,
      'image': 'assets/images/breeds/british_shorthair.jpg'
    },
    {
      'breed_id': 'persian',
      'confidence': 0.75,
      'image': 'assets/images/breeds/persian.jpg'
    },
    {
      'breed_id': 'ragdoll',
      'confidence': 0.89,
      'image': 'assets/images/breeds/ragdoll.jpg'
    }
  ];

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      setState(() {
        _status = 'Loading breed database...';
      });
      
      await _breedService.initialize();
      
      setState(() {
        _status = 'Loading ML model...';
      });
      
      await _mlService.initialize();
      
      setState(() {
        _status = 'Ready!';
        _isInitialized = true;
        _supportedBreeds = _breedService.getAllBreeds();
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Trained Model Demo',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: _isInitialized ? _buildDemoContent() : _buildLoadingState(),
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
          ),
        ],
      ),
    );
  }

  Widget _buildDemoContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildModelInfo(),
          const SizedBox(height: 24),
          _buildDemoResults(),
          const SizedBox(height: 24),
          _buildSupportedBreeds(),
        ],
      ),
    );
  }

  Widget _buildModelInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.psychology,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'EfficientNetV2-B3 Model',
                        style: AppTextStyles.headline3,
                      ),
                      Text(
                        'Your trained model is ready!',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildModelStat('Model Size', '15.5 MB'),
            _buildModelStat('Architecture', 'EfficientNetV2-B3'),
            _buildModelStat('Input Size', '384x384'),
            _buildModelStat('Supported Breeds', '${_supportedBreeds.length}'),
            _buildModelStat('Status', 'Model files ready, TFLite disabled'),
          ],
        ),
      ),
    );
  }

  Widget _buildModelStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Example Results',
              style: AppTextStyles.headline3,
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Text(
                'DEMO ONLY',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.orange.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.orange.shade700,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'These are example UI screenshots showing what results would look like. Real ML recognition is not implemented yet.',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.orange.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ..._demoResults.map((result) => _buildDemoResult(result)),
      ],
    );
  }

  Widget _buildDemoResult(Map<String, dynamic> result) {
    final breedId = result['breed_id'] as String;
    final confidence = result['confidence'] as double;
    final breed = _breedService.getBreedById(breedId);
    
    if (breed == null) return const SizedBox.shrink();
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToBreedDetail(breed),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Breed image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  breed.imageUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.pets,
                        color: Colors.white,
                        size: 30,
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Breed info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      breed.name,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      breed.origin,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getConfidenceColor(confidence),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${(confidence * 100).toInt()}% confident',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (breed.isRare)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.errorColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Rare',
                              style: AppTextStyles.caption.copyWith(
                                color: AppTheme.errorColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const Icon(
                Icons.chevron_right,
                color: AppTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideX(begin: 0.2, end: 0);
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return AppTheme.successColor;
    if (confidence >= 0.6) return Colors.orange;
    return AppTheme.errorColor;
  }

  Widget _buildSupportedBreeds() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'All Supported Breeds',
              style: AppTextStyles.headline3,
            ),
            Text(
              '${_supportedBreeds.length} breeds',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _supportedBreeds.map((breed) {
            return InkWell(
              onTap: () => _navigateToBreedDetail(breed),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  breed.name,
                  style: AppTextStyles.caption.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _navigateToBreedDetail(CatBreed breed) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BreedDetailScreen(breed: breed),
      ),
    );
  }
}