import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/sharing_service.dart';
import '../services/database_service.dart';
import '../utils/theme.dart';
import '../models/recognition_result.dart';
import '../widgets/cat_paw_button.dart';

class ShareScreen extends StatefulWidget {
  final RecognitionResult? recognitionResult;
  final String? customContent;

  const ShareScreen({
    super.key,
    this.recognitionResult,
    this.customContent,
  });

  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  final SharingService _sharingService = SharingService();
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _messageController = TextEditingController();
  
  bool _includeImage = true;
  bool _includeAppPromo = true;
  bool _isSharing = false;
  List<Map<String, dynamic>> _recentRecognitions = [];
  RecognitionResult? _selectedResult;

  @override
  void initState() {
    super.initState();
    _selectedResult = widget.recognitionResult;
    _loadRecentRecognitions();
    
    if (widget.customContent != null) {
      _messageController.text = widget.customContent!;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentRecognitions() async {
    try {
      if (!_databaseService.isInitialized) {
        await _databaseService.initialize();
      }
      
      final recognitions = await _databaseService.getRecognitionResults(limit: 10);
      
      setState(() {
        _recentRecognitions = recognitions;
      });
    } catch (e) {
      print('❌ ShareScreen: Error loading recognitions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(
              Icons.share,
              color: AppTheme.primaryColor,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              'Share Discovery',
              style: AppTextStyles.headline2.copyWith(
                color: AppTheme.primaryColor,
                fontSize: 24,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isSharing ? _buildSharingView() : _buildContent(),
    );
  }

  Widget _buildSharingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LoadingPawAnimation(
            message: 'Preparing to share...',
            size: 60,
          ),
          SizedBox(height: 16),
          Text(
            'Getting everything ready for sharing...',
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
          if (widget.recognitionResult == null) ...[
            _buildRecognitionSelector(),
            const SizedBox(height: 24),
          ],
          if (_selectedResult != null) ...[
            _buildSelectedRecognition(),
            const SizedBox(height: 24),
          ],
          _buildCustomMessageSection(),
          const SizedBox(height: 24),
          _buildOptionsSection(),
          const SizedBox(height: 32),
          _buildSharingPlatforms(),
          const SizedBox(height: 24),
          _buildQuickShareSection(),
        ],
      ),
    );
  }

  Widget _buildRecognitionSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Recognition to Share',
          style: AppTextStyles.headline3,
        ),
        const SizedBox(height: 16),
        if (_recentRecognitions.isEmpty)
          _buildEmptyRecognitions()
        else
          _buildRecognitionList(),
      ],
    );
  }

  Widget _buildEmptyRecognitions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.photo_camera,
            size: 48,
            color: AppTheme.textSecondary,
          ),
          SizedBox(height: 16),
          Text(
            'No Recognition Results',
            style: AppTextStyles.headline3,
          ),
          SizedBox(height: 8),
          Text(
            'Take a photo of a cat to create shareable recognition results!',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecognitionList() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _recentRecognitions.length,
        itemBuilder: (context, index) {
          final recognition = _recentRecognitions[index];
          final isSelected = _selectedResult?.id == recognition['id'];
          
          return GestureDetector(
            onTap: () {
              // TODO: Convert database recognition to RecognitionResult
              setState(() {
                // For now, just clear selected result if we don't have conversion logic
                _selectedResult = null;
              });
            },
            child: Container(
              width: 100,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected 
                      ? AppTheme.primaryColor 
                      : AppTheme.textSecondary.withOpacity(0.3),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient.scale(0.1),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppTheme.borderRadiusSmall - 2),
                        ),
                      ),
                      child: File(recognition['image_path'] as String).existsSync()
                          ? ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(AppTheme.borderRadiusSmall - 2),
                              ),
                              child: Image.file(
                                File(recognition['image_path'] as String),
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            )
                          : const Icon(
                              Icons.photo,
                              color: Colors.grey,
                            ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      recognition['breed_name'] as String,
                      style: AppTextStyles.caption,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectedRecognition() {
    if (_selectedResult == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient.scale(0.1),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
            child: SizedBox(
              width: 80,
              height: 80,
              child: File(_selectedResult!.imagePath).existsSync()
                  ? Image.file(
                      File(_selectedResult!.imagePath),
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.photo, color: Colors.grey),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedResult!.predictedBreed.name,
                  style: AppTextStyles.headline3.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  'Confidence: ${_selectedResult!.confidencePercentage}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedResult!.predictedBreed.origin,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Remove button
          IconButton(
            onPressed: () {
              setState(() {
                _selectedResult = null;
              });
            },
            icon: const Icon(
              Icons.close,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomMessageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Custom Message (Optional)',
          style: AppTextStyles.headline3,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _messageController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Add your personal message here...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
              borderSide: const BorderSide(color: AppTheme.primaryColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sharing Options',
          style: AppTextStyles.headline3,
        ),
        const SizedBox(height: 16),
        _buildOptionTile(
          title: 'Include Image',
          subtitle: 'Share the cat photo along with the text',
          value: _includeImage,
          onChanged: (value) {
            setState(() {
              _includeImage = value;
            });
          },
          icon: Icons.photo,
        ),
        _buildOptionTile(
          title: 'Include App Promotion',
          subtitle: 'Mention MeowAI app in the shared message',
          value: _includeAppPromo,
          onChanged: (value) {
            setState(() {
              _includeAppPromo = value;
            });
          },
          icon: Icons.smartphone,
        ),
      ],
    );
  }

  Widget _buildOptionTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Text(
          title,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        secondary: Icon(
          icon,
          color: AppTheme.primaryColor,
        ),
        activeColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildSharingPlatforms() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Platform',
          style: AppTextStyles.headline3,
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.5,
          children: SharePlatform.values.map((platform) {
            return _buildPlatformCard(platform);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPlatformCard(SharePlatform platform) {
    return Card(
      child: InkWell(
        onTap: () => _shareToSpecificPlatform(platform),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: platform.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                ),
                child: Icon(
                  platform.icon,
                  color: platform.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  platform.displayName,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().scale(delay: Duration(milliseconds: SharePlatform.values.indexOf(platform) * 100));
  }

  Widget _buildQuickShareSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: AppTextStyles.headline3,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _copyToClipboard,
                icon: const Icon(Icons.copy),
                label: const Text('Copy Text'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _shareGeneral,
                icon: const Icon(Icons.share),
                label: const Text('Share Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _shareToSpecificPlatform(SharePlatform platform) async {
    setState(() => _isSharing = true);

    try {
      if (_selectedResult != null) {
        final result = await _sharingService.shareRecognitionResult(
          result: _selectedResult!,
          customMessage: _messageController.text.isEmpty ? null : _messageController.text,
          includeImage: _includeImage,
          includeAppPromo: _includeAppPromo,
        );
        _showShareResult(result);
      } else {
        // Share custom content
        final customText = _messageController.text.isEmpty 
            ? 'Check out MeowAI - the amazing cat breed recognition app!'
            : _messageController.text;
            
        final result = await _sharingService.shareToSpecificPlatform(
          text: customText,
          platform: platform,
        );
        _showShareResult(result);
      }
    } finally {
      setState(() => _isSharing = false);
    }
  }

  Future<void> _shareGeneral() async {
    setState(() => _isSharing = true);

    try {
      if (_selectedResult != null) {
        final result = await _sharingService.shareRecognitionResult(
          result: _selectedResult!,
          customMessage: _messageController.text.isEmpty ? null : _messageController.text,
          includeImage: _includeImage,
          includeAppPromo: _includeAppPromo,
        );
        _showShareResult(result);
      } else {
        // Share custom content
        final customText = _messageController.text.isEmpty 
            ? 'Check out MeowAI - the amazing cat breed recognition app!'
            : _messageController.text;
            
        final result = await _sharingService.shareToSpecificPlatform(
          text: customText,
          platform: SharePlatform.system,
        );
        _showShareResult(result);
      }
    } finally {
      setState(() => _isSharing = false);
    }
  }

  Future<void> _copyToClipboard() async {
    String textToShare;
    
    if (_selectedResult != null) {
      textToShare = _sharingService.buildShareText(
        result: _selectedResult!,
        customMessage: _messageController.text.isEmpty ? null : _messageController.text,
        includeAppPromo: _includeAppPromo,
      );
    } else {
      textToShare = _messageController.text.isEmpty 
          ? 'Check out MeowAI - the amazing cat breed recognition app!'
          : _messageController.text;
    }

    final result = await _sharingService.copyToClipboard(textToShare);
    _showShareResult(result);
  }

  void _showShareResult(ShareResult result) {
    final snackBar = SnackBar(
      content: Text(result.message ?? (result.isSuccess ? 'Operation completed' : 'Operation failed')),
      backgroundColor: result.isSuccess ? AppTheme.primaryColor : AppTheme.errorColor,
      behavior: SnackBarBehavior.floating,
    );
    
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    
    if (result.isSuccess) {
      // Optional: Navigate back after successful share
      // Navigator.of(context).pop();
    }
  }
}