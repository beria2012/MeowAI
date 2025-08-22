import 'dart:io';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';

import 'authentication_service.dart';

class GooglePhotosService {
  static const String _baseUrl = 'https://photoslibrary.googleapis.com/v1';
  static const String _albumName = 'MeowAI Cat Recognitions';
  
  final AuthenticationService _authService = AuthenticationService();
  String? _albumId;
  
  // Singleton pattern
  static final GooglePhotosService _instance = GooglePhotosService._internal();
  factory GooglePhotosService() => _instance;
  GooglePhotosService._internal();

  /// Check if user has Google Photos access
  Future<bool> hasAccess() async {
    return await _authService.hasGooglePhotosAccess();
  }

  /// Get access token for API calls
  Future<String?> _getAccessToken() async {
    return await _authService.getGoogleAccessToken();
  }

  /// Create or get the MeowAI album
  Future<String?> _getOrCreateAlbum() async {
    if (_albumId != null) return _albumId;

    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) return null;

      // First, try to find existing album
      final existingAlbum = await _findAlbum();
      if (existingAlbum != null) {
        _albumId = existingAlbum;
        return _albumId;
      }

      // Create new album
      final response = await http.post(
        Uri.parse('$_baseUrl/albums'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'album': {
            'title': _albumName,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _albumId = data['id'];
        return _albumId;
      } else {
        print('Error creating album: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting or creating album: $e');
      return null;
    }
  }

  /// Find existing MeowAI album
  Future<String?> _findAlbum() async {
    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) return null;

      final response = await http.get(
        Uri.parse('$_baseUrl/albums'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final albums = data['albums'] as List<dynamic>?;
        
        if (albums != null) {
          for (final album in albums) {
            if (album['title'] == _albumName) {
              return album['id'];
            }
          }
        }
      }
      return null;
    } catch (e) {
      print('Error finding album: $e');
      return null;
    }
  }

  /// Upload a photo to Google Photos
  Future<GooglePhotosResult> uploadPhoto({
    required String imagePath,
    required String description,
    String? breedName,
    double? confidence,
  }) async {
    try {
      if (!await hasAccess()) {
        return GooglePhotosResult.failure('No Google Photos access');
      }

      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        return GooglePhotosResult.failure('Unable to get access token');
      }

      // Step 1: Upload raw bytes
      final uploadToken = await _uploadRawBytes(imagePath, accessToken);
      if (uploadToken == null) {
        return GooglePhotosResult.failure('Failed to upload image bytes');
      }

      // Step 2: Create media item
      final mediaItem = await _createMediaItem(
        uploadToken, 
        imagePath, 
        description,
        breedName,
        confidence,
        accessToken,
      );

      if (mediaItem != null) {
        return GooglePhotosResult.success(
          mediaItem['id'],
          mediaItem['productUrl'],
          'Photo uploaded successfully to Google Photos',
        );
      } else {
        return GooglePhotosResult.failure('Failed to create media item');
      }
    } catch (e) {
      print('Error uploading photo: $e');
      return GooglePhotosResult.failure('Upload failed: ${e.toString()}');
    }
  }

  /// Upload raw bytes to Google Photos
  Future<String?> _uploadRawBytes(String imagePath, String accessToken) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        print('Image file does not exist: $imagePath');
        return null;
      }

      final bytes = await file.readAsBytes();
      final fileName = path.basename(imagePath);

      final response = await http.post(
        Uri.parse('$_baseUrl/uploads'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/octet-stream',
          'X-Goog-Upload-File-Name': fileName,
          'X-Goog-Upload-Protocol': 'raw',
        },
        body: bytes,
      );

      if (response.statusCode == 200) {
        return response.body; // This is the upload token
      } else {
        print('Error uploading raw bytes: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error uploading raw bytes: $e');
      return null;
    }
  }

  /// Create media item from upload token
  Future<Map<String, dynamic>?> _createMediaItem(
    String uploadToken,
    String imagePath,
    String description,
    String? breedName,
    double? confidence,
    String accessToken,
  ) async {
    try {
      final fileName = path.basename(imagePath);
      final mimeType = lookupMimeType(imagePath) ?? 'image/jpeg';
      
      // Build description with breed info
      String fullDescription = description;
      if (breedName != null) {
        fullDescription += '\n\nBreed: $breedName';
        if (confidence != null) {
          fullDescription += ' (${(confidence * 100).toInt()}% confidence)';
        }
      }
      fullDescription += '\n\nUploaded by MeowAI - Cat Breed Recognition App';

      final requestBody = {
        'newMediaItems': [
          {
            'description': fullDescription,
            'simpleMediaItem': {
              'fileName': fileName,
              'uploadToken': uploadToken,
            },
          },
        ],
      };

      // Add to album if available
      final albumId = await _getOrCreateAlbum();
      if (albumId != null) {
        requestBody['albumId'] = albumId;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/mediaItems:batchCreate'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['newMediaItemResults'] as List<dynamic>?;
        
        if (results != null && results.isNotEmpty) {
          final result = results.first;
          if (result['status']['message'] == 'SUCCESS') {
            return result['mediaItem'];
          } else {
            print('Media item creation failed: ${result['status']}');
            return null;
          }
        }
      } else {
        print('Error creating media item: ${response.statusCode} - ${response.body}');
        return null;
      }
      return null;
    } catch (e) {
      print('Error creating media item: $e');
      return null;
    }
  }

  /// Get photos from MeowAI album
  Future<List<GooglePhotoItem>> getAlbumPhotos({int? pageSize}) async {
    try {
      if (!await hasAccess()) {
        return [];
      }

      final accessToken = await _getAccessToken();
      if (accessToken == null) return [];

      final albumId = await _getOrCreateAlbum();
      if (albumId == null) return [];

      final uri = Uri.parse('$_baseUrl/mediaItems:search').replace(
        queryParameters: {
          if (pageSize != null) 'pageSize': pageSize.toString(),
        },
      );

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'albumId': albumId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final mediaItems = data['mediaItems'] as List<dynamic>?;
        
        if (mediaItems != null) {
          return mediaItems.map((item) => GooglePhotoItem.fromJson(item)).toList();
        }
      } else {
        print('Error getting album photos: ${response.statusCode} - ${response.body}');
      }
      return [];
    } catch (e) {
      print('Error getting album photos: $e');
      return [];
    }
  }

  /// Delete a photo from Google Photos
  Future<GooglePhotosResult> deletePhoto(String mediaItemId) async {
    try {
      if (!await hasAccess()) {
        return GooglePhotosResult.failure('No Google Photos access');
      }

      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        return GooglePhotosResult.failure('Unable to get access token');
      }

      // Note: Google Photos API doesn't support deleting media items
      // This is a limitation of the API. We can only remove from albums.
      final albumId = await _getOrCreateAlbum();
      if (albumId != null) {
        final result = await _removeFromAlbum(mediaItemId, albumId, accessToken);
        if (result) {
          return GooglePhotosResult.success(
            mediaItemId,
            null,
            'Photo removed from MeowAI album',
          );
        }
      }

      return GooglePhotosResult.failure('Cannot delete photos via API. Please delete manually in Google Photos.');
    } catch (e) {
      print('Error deleting photo: $e');
      return GooglePhotosResult.failure('Delete failed: ${e.toString()}');
    }
  }

  /// Remove photo from album
  Future<bool> _removeFromAlbum(String mediaItemId, String albumId, String accessToken) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/albums/$albumId:batchRemoveMediaItems'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'mediaItemIds': [mediaItemId],
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error removing from album: $e');
      return false;
    }
  }

  /// Get album info
  Future<Map<String, dynamic>?> getAlbumInfo() async {
    try {
      if (!await hasAccess()) return null;

      final accessToken = await _getAccessToken();
      if (accessToken == null) return null;

      final albumId = await _getOrCreateAlbum();
      if (albumId == null) return null;

      final response = await http.get(
        Uri.parse('$_baseUrl/albums/$albumId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error getting album info: $e');
      return null;
    }
  }

  /// Check storage quota
  Future<Map<String, dynamic>?> getStorageInfo() async {
    try {
      // Note: Google Photos API doesn't provide storage quota information
      // This would need to be implemented using Google Drive API
      return {
        'note': 'Storage info not available via Google Photos API',
        'suggestion': 'Check storage in Google Photos app',
      };
    } catch (e) {
      print('Error getting storage info: $e');
      return null;
    }
  }

  /// Clear cached album ID
  void clearCache() {
    _albumId = null;
  }
}

/// Google Photos operation result
class GooglePhotosResult {
  final bool isSuccess;
  final String? mediaItemId;
  final String? photoUrl;
  final String? message;
  final String? error;

  const GooglePhotosResult._({
    required this.isSuccess,
    this.mediaItemId,
    this.photoUrl,
    this.message,
    this.error,
  });

  factory GooglePhotosResult.success(
    String? mediaItemId,
    String? photoUrl,
    String? message,
  ) {
    return GooglePhotosResult._(
      isSuccess: true,
      mediaItemId: mediaItemId,
      photoUrl: photoUrl,
      message: message,
    );
  }

  factory GooglePhotosResult.failure(String error) {
    return GooglePhotosResult._(
      isSuccess: false,
      error: error,
    );
  }

  @override
  String toString() {
    if (isSuccess) {
      return 'GooglePhotosResult.success(mediaItemId: $mediaItemId, message: $message)';
    } else {
      return 'GooglePhotosResult.failure(error: $error)';
    }
  }
}

/// Google Photos item model
class GooglePhotoItem {
  final String id;
  final String? filename;
  final String? mimeType;
  final String baseUrl;
  final String productUrl;
  final String? description;
  final DateTime? creationTime;

  const GooglePhotoItem({
    required this.id,
    this.filename,
    this.mimeType,
    required this.baseUrl,
    required this.productUrl,
    this.description,
    this.creationTime,
  });

  factory GooglePhotoItem.fromJson(Map<String, dynamic> json) {
    return GooglePhotoItem(
      id: json['id'],
      filename: json['filename'],
      mimeType: json['mimeType'],
      baseUrl: json['baseUrl'],
      productUrl: json['productUrl'],
      description: json['description'],
      creationTime: json['mediaMetadata']?['creationTime'] != null
          ? DateTime.parse(json['mediaMetadata']['creationTime'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filename': filename,
      'mimeType': mimeType,
      'baseUrl': baseUrl,
      'productUrl': productUrl,
      'description': description,
      'creationTime': creationTime?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'GooglePhotoItem(id: $id, filename: $filename)';
  }
}