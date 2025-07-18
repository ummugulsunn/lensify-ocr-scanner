import 'dart:developer' as developer;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/ocr_engine_manager.dart';

/// Comprehensive OCR History Database Manager
class OCRHistoryDatabase {
  static const String _databaseName = 'ocr_history.db';
  static const int _databaseVersion = 2;
  static const String _logTag = 'OCRHistoryDB';
  
  // Table names
  static const String _tableOCRHistory = 'ocr_history';
  static const String _tableCategories = 'categories';
  static const String _tableTags = 'tags';
  static const String _tableHistoryTags = 'history_tags';
  
  static OCRHistoryDatabase? _instance;
  static OCRHistoryDatabase get instance => _instance ??= OCRHistoryDatabase._();
  
  OCRHistoryDatabase._();
  
  Database? _database;
  
  /// Get database instance
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }
  
  /// Initialize the database
  Future<Database> _initDatabase() async {
    try {
      developer.log('Initializing OCR History Database...', name: _logTag);
      
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, _databaseName);
      
      return await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: _onConfigure,
      );
    } catch (e) {
      developer.log('Error initializing database: $e', name: _logTag);
      rethrow;
    }
  }
  
  /// Configure database (enable foreign keys, etc.)
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
    // WAL mode disabled for Android compatibility
    // await db.execute('PRAGMA journal_mode = WAL');
  }
  
  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    developer.log('Creating database tables...', name: _logTag);
    
    // OCR History main table
    await db.execute('''
      CREATE TABLE $_tableOCRHistory (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        text TEXT NOT NULL,
        confidence REAL NOT NULL,
        engine TEXT NOT NULL,
        processing_time INTEGER NOT NULL,
        language TEXT NOT NULL,
        quality TEXT NOT NULL,
        is_handwriting INTEGER NOT NULL DEFAULT 0,
        is_batch INTEGER NOT NULL DEFAULT 0,
        image_count INTEGER NOT NULL DEFAULT 1,
        image_size INTEGER,
        image_path TEXT,
        image_hash TEXT,
        category_id INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        is_archived INTEGER NOT NULL DEFAULT 0,
        title TEXT,
        notes TEXT,
        FOREIGN KEY (category_id) REFERENCES $_tableCategories (id) ON DELETE SET NULL
      )
    ''');
    
    // Categories table
    await db.execute('''
      CREATE TABLE $_tableCategories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        description TEXT,
        color TEXT,
        icon TEXT,
        created_at INTEGER NOT NULL,
        item_count INTEGER NOT NULL DEFAULT 0
      )
    ''');
    
    // Tags table
    await db.execute('''
      CREATE TABLE $_tableTags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        color TEXT,
        created_at INTEGER NOT NULL,
        usage_count INTEGER NOT NULL DEFAULT 0
      )
    ''');
    
    // History-Tags relationship table (many-to-many)
    await db.execute('''
      CREATE TABLE $_tableHistoryTags (
        history_id INTEGER NOT NULL,
        tag_id INTEGER NOT NULL,
        PRIMARY KEY (history_id, tag_id),
        FOREIGN KEY (history_id) REFERENCES $_tableOCRHistory (id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES $_tableTags (id) ON DELETE CASCADE
      )
    ''');
    
    // Create indexes for better performance
    await _createIndexes(db);
    
    // Create full-text search virtual table with fallback
    try {
      await db.execute('''
        CREATE VIRTUAL TABLE ocr_search USING fts5(
          text,
          title,
          notes,
          content='$_tableOCRHistory',
          content_rowid='id'
        )
      ''');
      developer.log('FTS5 search table created successfully', name: _logTag);
    } catch (e) {
      developer.log('FTS5 not available, skipping search table: $e', name: _logTag);
      // FTS5 not available on this device, search will use LIKE queries
    }
    
    // Insert default categories
    await _insertDefaultCategories(db);
    
    developer.log('Database tables created successfully', name: _logTag);
  }
  
  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    developer.log('Upgrading database from version $oldVersion to $newVersion', name: _logTag);
    
    if (oldVersion < 2) {
      // Add new columns for version 2
      await db.execute('ALTER TABLE $_tableOCRHistory ADD COLUMN title TEXT');
      await db.execute('ALTER TABLE $_tableOCRHistory ADD COLUMN notes TEXT');
      await db.execute('ALTER TABLE $_tableOCRHistory ADD COLUMN is_favorite INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE $_tableOCRHistory ADD COLUMN is_archived INTEGER NOT NULL DEFAULT 0');
      
      // Recreate FTS table with fallback
      await db.execute('DROP TABLE IF EXISTS ocr_search');
      try {
        await db.execute('''
          CREATE VIRTUAL TABLE ocr_search USING fts5(
            text,
            title,
            notes,
            content='$_tableOCRHistory',
            content_rowid='id'
          )
        ''');
        developer.log('FTS5 search table recreated successfully', name: _logTag);
      } catch (e) {
        developer.log('FTS5 not available during upgrade, skipping search table: $e', name: _logTag);
        // FTS5 not available on this device, search will use LIKE queries
      }
    }
  }
  
  /// Create database indexes
  Future<void> _createIndexes(Database db) async {
    await db.execute('CREATE INDEX idx_created_at ON $_tableOCRHistory (created_at)');
    await db.execute('CREATE INDEX idx_engine ON $_tableOCRHistory (engine)');
    await db.execute('CREATE INDEX idx_language ON $_tableOCRHistory (language)');
    await db.execute('CREATE INDEX idx_category ON $_tableOCRHistory (category_id)');
    await db.execute('CREATE INDEX idx_favorites ON $_tableOCRHistory (is_favorite)');
    await db.execute('CREATE INDEX idx_archived ON $_tableOCRHistory (is_archived)');
    await db.execute('CREATE INDEX idx_image_hash ON $_tableOCRHistory (image_hash)');
  }
  
  /// Insert default categories
  Future<void> _insertDefaultCategories(Database db) async {
    final defaultCategories = [
      {'name': 'Belgeler', 'description': 'Resmi belgeler ve dökümanlar', 'color': '#2196F3', 'icon': 'description'},
      {'name': 'Notlar', 'description': 'El yazısı notlar ve mektuplar', 'color': '#FF9800', 'icon': 'note'},
      {'name': 'Faturalar', 'description': 'Fatura ve makbuzlar', 'color': '#4CAF50', 'icon': 'receipt'},
      {'name': 'Kartlar', 'description': 'Kartvizit ve kimlik kartları', 'color': '#9C27B0', 'icon': 'badge'},
      {'name': 'Kitaplar', 'description': 'Kitap sayfaları ve metinler', 'color': '#795548', 'icon': 'book'},
      {'name': 'Diğer', 'description': 'Kategorize edilmemiş içerik', 'color': '#607D8B', 'icon': 'category'},
    ];
    
    for (final category in defaultCategories) {
      await db.insert(_tableCategories, {
        ...category,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }
  
  /// Save OCR result to database
  Future<int> saveOCRResult(OCRHistoryEntry entry) async {
    try {
      final db = await database;
      
      final id = await db.insert(_tableOCRHistory, entry.toMap());
      
      // Update FTS table
      await db.execute('''
        INSERT INTO ocr_search(rowid, text, title, notes) 
        VALUES (?, ?, ?, ?)
      ''', [id, entry.text, entry.title ?? '', entry.notes ?? '']);
      
      // Update category item count
      if (entry.categoryId != null) {
        await _updateCategoryCount(entry.categoryId!);
      }
      
      developer.log('OCR result saved with ID: $id', name: _logTag);
      return id;
    } catch (e) {
      developer.log('Error saving OCR result: $e', name: _logTag);
      rethrow;
    }
  }
  
  /// Update existing OCR entry
  Future<void> updateOCREntry(int id, Map<String, dynamic> updates) async {
    try {
      final db = await database;
      
      updates['updated_at'] = DateTime.now().millisecondsSinceEpoch;
      
      await db.update(
        _tableOCRHistory,
        updates,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      // Update FTS if text, title, or notes changed
      if (updates.containsKey('text') || updates.containsKey('title') || updates.containsKey('notes')) {
        final entry = await getOCREntry(id);
        if (entry != null) {
          await db.execute('''
            UPDATE ocr_search SET text = ?, title = ?, notes = ? WHERE rowid = ?
          ''', [entry.text, entry.title ?? '', entry.notes ?? '', id]);
        }
      }
      
      developer.log('OCR entry updated: $id', name: _logTag);
    } catch (e) {
      developer.log('Error updating OCR entry: $e', name: _logTag);
      rethrow;
    }
  }
  
  /// Get OCR entry by ID
  Future<OCRHistoryEntry?> getOCREntry(int id) async {
    try {
      final db = await database;
      
      final results = await db.query(
        _tableOCRHistory,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (results.isNotEmpty) {
        return OCRHistoryEntry.fromMap(results.first);
      }
      return null;
    } catch (e) {
      developer.log('Error getting OCR entry: $e', name: _logTag);
      return null;
    }
  }
  
  /// Get OCR history with pagination and filtering
  Future<List<OCRHistoryEntry>> getOCRHistory({
    int limit = 50,
    int offset = 0,
    String? categoryFilter,
    String? engineFilter,
    String? languageFilter,
    bool? favoritesOnly,
    bool? archivedOnly,
    String? sortBy = 'created_at',
    bool ascending = false,
  }) async {
    try {
      final db = await database;
      
      String query = 'SELECT * FROM $_tableOCRHistory WHERE 1=1';
      List<dynamic> args = [];
      
      // Apply filters
      if (categoryFilter != null) {
        query += ' AND category_id = ?';
        args.add(categoryFilter);
      }
      
      if (engineFilter != null) {
        query += ' AND engine = ?';
        args.add(engineFilter);
      }
      
      if (languageFilter != null) {
        query += ' AND language = ?';
        args.add(languageFilter);
      }
      
      if (favoritesOnly == true) {
        query += ' AND is_favorite = 1';
      }
      
      if (archivedOnly != null) {
        query += ' AND is_archived = ?';
        args.add(archivedOnly ? 1 : 0);
      }
      
      // Add sorting
      query += ' ORDER BY $sortBy ${ascending ? 'ASC' : 'DESC'}';
      
      // Add pagination
      query += ' LIMIT ? OFFSET ?';
      args.addAll([limit, offset]);
      
      final results = await db.rawQuery(query, args);
      
      return results.map((map) => OCRHistoryEntry.fromMap(map)).toList();
    } catch (e) {
      developer.log('Error getting OCR history: $e', name: _logTag);
      return [];
    }
  }
  
  /// Search OCR history using full-text search
  Future<List<OCRHistoryEntry>> searchOCRHistory(
    String searchTerm, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final db = await database;
      
      final results = await db.rawQuery('''
        SELECT h.* FROM $_tableOCRHistory h
        JOIN ocr_search s ON h.id = s.rowid
        WHERE ocr_search MATCH ?
        ORDER BY rank
        LIMIT ? OFFSET ?
      ''', [searchTerm, limit, offset]);
      
      return results.map((map) => OCRHistoryEntry.fromMap(map)).toList();
    } catch (e) {
      developer.log('Error searching OCR history: $e', name: _logTag);
      return [];
    }
  }
  
  /// Delete OCR entry
  Future<void> deleteOCREntry(int id) async {
    try {
      final db = await database;
      
      // Get entry for category count update
      final entry = await getOCREntry(id);
      
      await db.delete(
        _tableOCRHistory,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      // Remove from FTS
      await db.execute('DELETE FROM ocr_search WHERE rowid = ?', [id]);
      
      // Update category count
      if (entry?.categoryId != null) {
        await _updateCategoryCount(entry!.categoryId!);
      }
      
      developer.log('OCR entry deleted: $id', name: _logTag);
    } catch (e) {
      developer.log('Error deleting OCR entry: $e', name: _logTag);
      rethrow;
    }
  }
  
  /// Get statistics
  Future<OCRHistoryStats> getStatistics() async {
    try {
      final db = await database;
      
      final totalCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $_tableOCRHistory'),
      ) ?? 0;
      
      final favoritesCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $_tableOCRHistory WHERE is_favorite = 1'),
      ) ?? 0;
      
      final archivedCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $_tableOCRHistory WHERE is_archived = 1'),
      ) ?? 0;
      
      final avgConfidenceResult = await db.rawQuery('SELECT AVG(confidence) as avg_confidence FROM $_tableOCRHistory');
      final avgConfidence = (avgConfidenceResult.first['avg_confidence'] as double?) ?? 0.0;
      
      final avgProcessingTime = Sqflite.firstIntValue(
        await db.rawQuery('SELECT AVG(processing_time) FROM $_tableOCRHistory'),
      ) ?? 0;
      
      // Engine usage stats
      final engineStats = await db.rawQuery('''
        SELECT engine, COUNT(*) as count 
        FROM $_tableOCRHistory 
        GROUP BY engine 
        ORDER BY count DESC
      ''');
      
      // Language stats
      final languageStats = await db.rawQuery('''
        SELECT language, COUNT(*) as count 
        FROM $_tableOCRHistory 
        GROUP BY language 
        ORDER BY count DESC
      ''');
      
      return OCRHistoryStats(
        totalEntries: totalCount,
        favoritesCount: favoritesCount,
        archivedCount: archivedCount,
        averageConfidence: avgConfidence,
        averageProcessingTime: avgProcessingTime,
        engineStats: Map.fromEntries(
          engineStats.map((row) => MapEntry(row['engine'] as String, row['count'] as int)),
        ),
        languageStats: Map.fromEntries(
          languageStats.map((row) => MapEntry(row['language'] as String, row['count'] as int)),
        ),
      );
    } catch (e) {
      developer.log('Error getting statistics: $e', name: _logTag);
      return OCRHistoryStats.empty();
    }
  }
  
  /// Update category item count
  Future<void> _updateCategoryCount(int categoryId) async {
    final db = await database;
    
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM $_tableOCRHistory WHERE category_id = ?',
        [categoryId],
      ),
    ) ?? 0;
    
    await db.update(
      _tableCategories,
      {'item_count': count},
      where: 'id = ?',
      whereArgs: [categoryId],
    );
  }
  
  /// Get all categories
  Future<List<OCRCategory>> getCategories() async {
    try {
      final db = await database;
      
      final results = await db.query(
        _tableCategories,
        orderBy: 'name ASC',
      );
      
      return results.map((map) => OCRCategory.fromMap(map)).toList();
    } catch (e) {
      developer.log('Error getting categories: $e', name: _logTag);
      return [];
    }
  }
  
  /// Add new category
  Future<int> addCategory(OCRCategory category) async {
    try {
      final db = await database;
      
      return await db.insert(_tableCategories, category.toMap());
    } catch (e) {
      developer.log('Error adding category: $e', name: _logTag);
      rethrow;
    }
  }
  
  /// Clear all data (for testing or reset)
  Future<void> clearAllData() async {
    try {
      final db = await database;
      
      await db.delete(_tableOCRHistory);
      await db.delete(_tableHistoryTags);
      await db.execute('DELETE FROM ocr_search');
      
      // Reset category counts
      await db.update(_tableCategories, {'item_count': 0});
      
      developer.log('All OCR history data cleared', name: _logTag);
    } catch (e) {
      developer.log('Error clearing data: $e', name: _logTag);
      rethrow;
    }
  }
  
  /// Close database
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}

/// OCR History Entry Model
class OCRHistoryEntry {
  final int? id;
  final String text;
  final double confidence;
  final String engine;
  final int processingTime;
  final String language;
  final String quality;
  final bool isHandwriting;
  final bool isBatch;
  final int imageCount;
  final int? imageSize;
  final String? imagePath;
  final String? imageHash;
  final int? categoryId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isFavorite;
  final bool isArchived;
  final String? title;
  final String? notes;
  
  OCRHistoryEntry({
    this.id,
    required this.text,
    required this.confidence,
    required this.engine,
    required this.processingTime,
    required this.language,
    required this.quality,
    this.isHandwriting = false,
    this.isBatch = false,
    this.imageCount = 1,
    this.imageSize,
    this.imagePath,
    this.imageHash,
    this.categoryId,
    required this.createdAt,
    this.updatedAt,
    this.isFavorite = false,
    this.isArchived = false,
    this.title,
    this.notes,
  });
  
  /// Create from OCRResult
  factory OCRHistoryEntry.fromOCRResult(
    OCRResult result, {
    String language = 'tur',
    String quality = 'balanced',
    bool isHandwriting = false,
    bool isBatch = false,
    int imageCount = 1,
    int? imageSize,
    String? imagePath,
    String? imageHash,
    int? categoryId,
    String? title,
    String? notes,
  }) {
    return OCRHistoryEntry(
      text: result.text,
      confidence: result.confidence,
      engine: result.engine.displayName,
      processingTime: result.processingTime.inMilliseconds,
      language: language,
      quality: quality,
      isHandwriting: isHandwriting,
      isBatch: isBatch,
      imageCount: imageCount,
      imageSize: imageSize,
      imagePath: imagePath,
      imageHash: imageHash,
      categoryId: categoryId,
      createdAt: DateTime.now(),
      title: title,
      notes: notes,
    );
  }
  
  /// Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'text': text,
      'confidence': confidence,
      'engine': engine,
      'processing_time': processingTime,
      'language': language,
      'quality': quality,
      'is_handwriting': isHandwriting ? 1 : 0,
      'is_batch': isBatch ? 1 : 0,
      'image_count': imageCount,
      'image_size': imageSize,
      'image_path': imagePath,
      'image_hash': imageHash,
      'category_id': categoryId,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt?.millisecondsSinceEpoch,
      'is_favorite': isFavorite ? 1 : 0,
      'is_archived': isArchived ? 1 : 0,
      'title': title,
      'notes': notes,
    };
  }
  
  /// Create from Map (database)
  factory OCRHistoryEntry.fromMap(Map<String, dynamic> map) {
    return OCRHistoryEntry(
      id: map['id'],
      text: map['text'],
      confidence: map['confidence'],
      engine: map['engine'],
      processingTime: map['processing_time'],
      language: map['language'],
      quality: map['quality'],
      isHandwriting: map['is_handwriting'] == 1,
      isBatch: map['is_batch'] == 1,
      imageCount: map['image_count'],
      imageSize: map['image_size'],
      imagePath: map['image_path'],
      imageHash: map['image_hash'],
      categoryId: map['category_id'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: map['updated_at'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'])
          : null,
      isFavorite: map['is_favorite'] == 1,
      isArchived: map['is_archived'] == 1,
      title: map['title'],
      notes: map['notes'],
    );
  }
}

/// OCR Category Model
class OCRCategory {
  final int? id;
  final String name;
  final String? description;
  final String? color;
  final String? icon;
  final DateTime createdAt;
  final int itemCount;
  
  OCRCategory({
    this.id,
    required this.name,
    this.description,
    this.color,
    this.icon,
    required this.createdAt,
    this.itemCount = 0,
  });
  
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'color': color,
      'icon': icon,
      'created_at': createdAt.millisecondsSinceEpoch,
      'item_count': itemCount,
    };
  }
  
  factory OCRCategory.fromMap(Map<String, dynamic> map) {
    return OCRCategory(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      color: map['color'],
      icon: map['icon'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      itemCount: map['item_count'] ?? 0,
    );
  }
}

/// OCR History Statistics
class OCRHistoryStats {
  final int totalEntries;
  final int favoritesCount;
  final int archivedCount;
  final double averageConfidence;
  final int averageProcessingTime;
  final Map<String, int> engineStats;
  final Map<String, int> languageStats;
  
  OCRHistoryStats({
    required this.totalEntries,
    required this.favoritesCount,
    required this.archivedCount,
    required this.averageConfidence,
    required this.averageProcessingTime,
    required this.engineStats,
    required this.languageStats,
  });
  
  factory OCRHistoryStats.empty() {
    return OCRHistoryStats(
      totalEntries: 0,
      favoritesCount: 0,
      archivedCount: 0,
      averageConfidence: 0.0,
      averageProcessingTime: 0,
      engineStats: {},
      languageStats: {},
    );
  }
} 