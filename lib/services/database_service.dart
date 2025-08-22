import 'dart:async';
import 'dart:io';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/cat_breed.dart';
import '../models/recognition_result.dart';
import '../models/user.dart';
import '../models/challenge.dart';

class DatabaseService {
  static const String _databaseName = 'meow_ai.db';
  static const int _databaseVersion = 1;
  
  // SQLite tables
  static const String _tableRecognitions = 'recognitions';
  static const String _tableFavorites = 'favorites';
  static const String _tableNotes = 'notes';
  static const String _tableHistory = 'history';
  static const String _tableSettings = 'settings';
  
  // Hive boxes
  static const String _boxUser = 'user';
  static const String _boxChallenges = 'challenges';
  static const String _boxAchievements = 'achievements';
  static const String _boxPreferences = 'preferences';
  
  Database? _database;
  bool _isInitialized = false;
  
  // Singleton pattern
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  /// Initialize the database service
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      // Initialize Hive
      await _initializeHive();
      
      // Initialize SQLite
      await _initializeSQLite();
      
      _isInitialized = true;
      print('Database service initialized successfully');
      return true;
    } catch (e) {
      print('Error initializing database service: $e');
      return false;
    }
  }

  /// Initialize Hive database
  Future<void> _initializeHive() async {
    if (!Hive.isAdapterRegistered(0)) {
      // Register Hive adapters for custom types
      // Note: In a real implementation, you'd generate these with build_runner
      // Hive.registerAdapter(CatBreedAdapter());
      // Hive.registerAdapter(UserAdapter());
      // Hive.registerAdapter(ChallengeAdapter());
    }
    
    // Open Hive boxes
    await Future.wait([
      Hive.openBox(_boxUser),
      Hive.openBox(_boxChallenges),
      Hive.openBox(_boxAchievements),
      Hive.openBox(_boxPreferences),
    ]);
  }

  /// Initialize SQLite database
  Future<void> _initializeSQLite() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final dbPath = path.join(documentsDirectory.path, _databaseName);
    
    _database = await openDatabase(
      dbPath,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    // Recognition results table
    await db.execute('''
      CREATE TABLE $_tableRecognitions (
        id TEXT PRIMARY KEY,
        image_path TEXT NOT NULL,
        breed_id TEXT NOT NULL,
        breed_name TEXT NOT NULL,
        confidence REAL NOT NULL,
        alternative_predictions TEXT,
        timestamp INTEGER NOT NULL,
        processing_time INTEGER NOT NULL,
        model_version TEXT NOT NULL,
        metadata TEXT
      )
    ''');

    // Favorites table
    await db.execute('''
      CREATE TABLE $_tableFavorites (
        id TEXT PRIMARY KEY,
        recognition_id TEXT,
        breed_id TEXT,
        image_path TEXT,
        note TEXT,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (recognition_id) REFERENCES $_tableRecognitions (id)
      )
    ''');

    // Notes table
    await db.execute('''
      CREATE TABLE $_tableNotes (
        id TEXT PRIMARY KEY,
        recognition_id TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (recognition_id) REFERENCES $_tableRecognitions (id)
      )
    ''');

    // History table for tracking user interactions
    await db.execute('''
      CREATE TABLE $_tableHistory (
        id TEXT PRIMARY KEY,
        action_type TEXT NOT NULL,
        recognition_id TEXT,
        breed_id TEXT,
        timestamp INTEGER NOT NULL,
        metadata TEXT
      )
    ''');

    // Settings table
    await db.execute('''
      CREATE TABLE $_tableSettings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_recognitions_timestamp ON $_tableRecognitions (timestamp)');
    await db.execute('CREATE INDEX idx_recognitions_breed ON $_tableRecognitions (breed_id)');
    await db.execute('CREATE INDEX idx_favorites_created_at ON $_tableFavorites (created_at)');
    await db.execute('CREATE INDEX idx_history_timestamp ON $_tableHistory (timestamp)');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database schema migrations here
    print('Upgrading database from version $oldVersion to $newVersion');
  }

  // MARK: - Recognition Results Operations

  /// Save a recognition result
  Future<bool> saveRecognitionResult(RecognitionResult result) async {
    if (_database == null) return false;

    try {
      await _database!.insert(
        _tableRecognitions,
        {
          'id': result.id,
          'image_path': result.imagePath,
          'breed_id': result.predictedBreed.id,
          'breed_name': result.predictedBreed.name,
          'confidence': result.confidence,
          'alternative_predictions': _encodeAlternativePredictions(result.alternativePredictions),
          'timestamp': result.timestamp.millisecondsSinceEpoch,
          'processing_time': result.processingTime.inMilliseconds,
          'model_version': result.modelVersion,
          'metadata': _encodeMetadata(result.metadata),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Add to history
      await _addToHistory('recognition', result.id, result.predictedBreed.id);
      
      return true;
    } catch (e) {
      print('Error saving recognition result: $e');
      return false;
    }
  }

  /// Get all recognition results
  Future<List<Map<String, dynamic>>> getRecognitionResults({
    int? limit,
    int? offset,
  }) async {
    if (_database == null) return [];

    try {
      String query = 'SELECT * FROM $_tableRecognitions ORDER BY timestamp DESC';
      if (limit != null) {
        query += ' LIMIT $limit';
        if (offset != null) {
          query += ' OFFSET $offset';
        }
      }

      return await _database!.rawQuery(query);
    } catch (e) {
      print('Error getting recognition results: $e');
      return [];
    }
  }

  /// Get recognition results by breed
  Future<List<Map<String, dynamic>>> getRecognitionsByBreed(String breedId) async {
    if (_database == null) return [];

    try {
      return await _database!.query(
        _tableRecognitions,
        where: 'breed_id = ?',
        whereArgs: [breedId],
        orderBy: 'timestamp DESC',
      );
    } catch (e) {
      print('Error getting recognitions by breed: $e');
      return [];
    }
  }

  /// Delete a recognition result
  Future<bool> deleteRecognitionResult(String id) async {
    if (_database == null) return false;

    try {
      await _database!.delete(
        _tableRecognitions,
        where: 'id = ?',
        whereArgs: [id],
      );

      // Also delete related favorites and notes
      await deleteFavoriteByRecognition(id);
      await deleteNoteByRecognition(id);
      
      return true;
    } catch (e) {
      print('Error deleting recognition result: $e');
      return false;
    }
  }

  // MARK: - Favorites Operations

  /// Add to favorites
  Future<bool> addToFavorites({
    required String id,
    String? recognitionId,
    String? breedId,
    String? imagePath,
    String? note,
  }) async {
    if (_database == null) return false;

    try {
      await _database!.insert(
        _tableFavorites,
        {
          'id': id,
          'recognition_id': recognitionId,
          'breed_id': breedId,
          'image_path': imagePath,
          'note': note,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await _addToHistory('favorite_added', recognitionId, breedId);
      return true;
    } catch (e) {
      print('Error adding to favorites: $e');
      return false;
    }
  }

  /// Get all favorites
  Future<List<Map<String, dynamic>>> getFavorites() async {
    if (_database == null) return [];

    try {
      return await _database!.query(
        _tableFavorites,
        orderBy: 'created_at DESC',
      );
    } catch (e) {
      print('Error getting favorites: $e');
      return [];
    }
  }

  /// Remove from favorites
  Future<bool> removeFavorite(String id) async {
    if (_database == null) return false;

    try {
      await _database!.delete(
        _tableFavorites,
        where: 'id = ?',
        whereArgs: [id],
      );

      await _addToHistory('favorite_removed', null, null);
      return true;
    } catch (e) {
      print('Error removing favorite: $e');
      return false;
    }
  }

  /// Delete favorite by recognition ID
  Future<bool> deleteFavoriteByRecognition(String recognitionId) async {
    if (_database == null) return false;

    try {
      await _database!.delete(
        _tableFavorites,
        where: 'recognition_id = ?',
        whereArgs: [recognitionId],
      );
      return true;
    } catch (e) {
      print('Error deleting favorite by recognition: $e');
      return false;
    }
  }

  /// Check if recognition is favorited
  Future<bool> isFavorite(String recognitionId) async {
    if (_database == null) return false;

    try {
      final result = await _database!.query(
        _tableFavorites,
        where: 'recognition_id = ?',
        whereArgs: [recognitionId],
        limit: 1,
      );
      return result.isNotEmpty;
    } catch (e) {
      print('Error checking if favorite: $e');
      return false;
    }
  }

  // MARK: - Notes Operations

  /// Save a note
  Future<bool> saveNote({
    required String id,
    required String recognitionId,
    required String content,
  }) async {
    if (_database == null) return false;

    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      await _database!.insert(
        _tableNotes,
        {
          'id': id,
          'recognition_id': recognitionId,
          'content': content,
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await _addToHistory('note_added', recognitionId, null);
      return true;
    } catch (e) {
      print('Error saving note: $e');
      return false;
    }
  }

  /// Get note by recognition ID
  Future<Map<String, dynamic>?> getNoteByRecognition(String recognitionId) async {
    if (_database == null) return null;

    try {
      final result = await _database!.query(
        _tableNotes,
        where: 'recognition_id = ?',
        whereArgs: [recognitionId],
        limit: 1,
      );
      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      print('Error getting note: $e');
      return null;
    }
  }

  /// Update a note
  Future<bool> updateNote(String id, String content) async {
    if (_database == null) return false;

    try {
      await _database!.update(
        _tableNotes,
        {
          'content': content,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      return true;
    } catch (e) {
      print('Error updating note: $e');
      return false;
    }
  }

  /// Delete note by recognition ID
  Future<bool> deleteNoteByRecognition(String recognitionId) async {
    if (_database == null) return false;

    try {
      await _database!.delete(
        _tableNotes,
        where: 'recognition_id = ?',
        whereArgs: [recognitionId],
      );
      return true;
    } catch (e) {
      print('Error deleting note: $e');
      return false;
    }
  }

  // MARK: - History Operations

  /// Add to history
  Future<void> _addToHistory(String actionType, String? recognitionId, String? breedId) async {
    if (_database == null) return;

    try {
      await _database!.insert(_tableHistory, {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'action_type': actionType,
        'recognition_id': recognitionId,
        'breed_id': breedId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'metadata': '{}',
      });
    } catch (e) {
      print('Error adding to history: $e');
    }
  }

  /// Get user history
  Future<List<Map<String, dynamic>>> getHistory({int? limit}) async {
    if (_database == null) return [];

    try {
      String query = 'SELECT * FROM $_tableHistory ORDER BY timestamp DESC';
      if (limit != null) {
        query += ' LIMIT $limit';
      }
      return await _database!.rawQuery(query);
    } catch (e) {
      print('Error getting history: $e');
      return [];
    }
  }

  // MARK: - Statistics

  /// Get user statistics
  Future<Map<String, int>> getStatistics() async {
    if (_database == null) return {};

    try {
      final recognitionCount = await _database!.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableRecognitions',
      );
      
      final breedCount = await _database!.rawQuery(
        'SELECT COUNT(DISTINCT breed_id) as count FROM $_tableRecognitions',
      );
      
      final favoriteCount = await _database!.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableFavorites',
      );

      final lastWeekCount = await _database!.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableRecognitions WHERE timestamp > ?',
        [DateTime.now().subtract(const Duration(days: 7)).millisecondsSinceEpoch],
      );

      return {
        'total_recognitions': recognitionCount.first['count'] as int,
        'unique_breeds': breedCount.first['count'] as int,
        'favorites': favoriteCount.first['count'] as int,
        'last_week': lastWeekCount.first['count'] as int,
      };
    } catch (e) {
      print('Error getting statistics: $e');
      return {};
    }
  }

  /// Get breed recognition counts
  Future<List<Map<String, dynamic>>> getBreedCounts() async {
    if (_database == null) return [];

    try {
      return await _database!.rawQuery('''
        SELECT breed_id, breed_name, COUNT(*) as count 
        FROM $_tableRecognitions 
        GROUP BY breed_id, breed_name 
        ORDER BY count DESC
      ''');
    } catch (e) {
      print('Error getting breed counts: $e');
      return [];
    }
  }

  // MARK: - Hive Operations (User Data)

  /// Save user data
  Future<bool> saveUser(User user) async {
    try {
      final box = Hive.box(_boxUser);
      await box.put('current_user', user.toJson());
      return true;
    } catch (e) {
      print('Error saving user: $e');
      return false;
    }
  }

  /// Get current user
  Future<User?> getCurrentUser() async {
    try {
      final box = Hive.box(_boxUser);
      final userData = box.get('current_user');
      if (userData != null) {
        return User.fromJson(Map<String, dynamic>.from(userData));
      }
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  /// Save user preferences
  Future<bool> saveUserPreferences(UserPreferences preferences) async {
    try {
      final box = Hive.box(_boxPreferences);
      await box.put('user_preferences', preferences.toJson());
      return true;
    } catch (e) {
      print('Error saving user preferences: $e');
      return false;
    }
  }

  /// Get user preferences
  Future<UserPreferences?> getUserPreferences() async {
    try {
      final box = Hive.box(_boxPreferences);
      final prefsData = box.get('user_preferences');
      if (prefsData != null) {
        return UserPreferences.fromJson(Map<String, dynamic>.from(prefsData));
      }
      return UserPreferences.defaultPreferences();
    } catch (e) {
      print('Error getting user preferences: $e');
      return UserPreferences.defaultPreferences();
    }
  }

  // MARK: - Utility Methods

  /// Encode alternative predictions to JSON string
  String _encodeAlternativePredictions(List<PredictionScore> predictions) {
    try {
      return predictions.map((p) => p.toJson()).toList().toString();
    } catch (e) {
      return '[]';
    }
  }

  /// Encode metadata to JSON string
  String _encodeMetadata(Map<String, dynamic> metadata) {
    try {
      return metadata.toString();
    } catch (e) {
      return '{}';
    }
  }

  /// Clear all data (for testing or reset)
  Future<bool> clearAllData() async {
    try {
      // Clear SQLite tables
      if (_database != null) {
        await _database!.delete(_tableRecognitions);
        await _database!.delete(_tableFavorites);
        await _database!.delete(_tableNotes);
        await _database!.delete(_tableHistory);
        await _database!.delete(_tableSettings);
      }

      // Clear Hive boxes
      await Hive.box(_boxUser).clear();
      await Hive.box(_boxChallenges).clear();
      await Hive.box(_boxAchievements).clear();
      await Hive.box(_boxPreferences).clear();

      return true;
    } catch (e) {
      print('Error clearing all data: $e');
      return false;
    }
  }

  /// Get database info
  Map<String, dynamic> getDatabaseInfo() {
    return {
      'is_initialized': _isInitialized,
      'sqlite_path': _database?.path,
      'hive_boxes': Hive.boxNames.toList(),
    };
  }

  /// Close database connections
  Future<void> close() async {
    await _database?.close();
    await Hive.close();
    _isInitialized = false;
  }
}