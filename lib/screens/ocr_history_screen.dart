import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../database/ocr_history_database.dart';
import '../l10n/app_localizations.dart';
import '../animations/animations.dart';
import '../utils/error_handler.dart';
import '../text_editor_screen.dart';

/// Comprehensive OCR History Screen
class OCRHistoryScreen extends StatefulWidget {
  const OCRHistoryScreen({super.key});

  @override
  State<OCRHistoryScreen> createState() => _OCRHistoryScreenState();
}

class _OCRHistoryScreenState extends State<OCRHistoryScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final List<OCRHistoryEntry> _historyEntries = [];
  List<OCRCategory> _categories = [];
  OCRHistoryStats? _stats;
  
  bool _isLoading = true;
  bool _isSearching = false;
  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedEngine;
  String _sortBy = 'created_at';
  bool _sortAscending = false;
  bool _showFavoritesOnly = false;
  bool _showArchivedOnly = false;
  
  static const int _pageSize = 20;
  int _currentPage = 0;
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInitialData();
    _setupScrollListener();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= 
          _scrollController.position.maxScrollExtent - 200) {
        _loadMoreData();
      }
    });
  }

  Future<void> _loadInitialData() async {
    try {
      setState(() => _isLoading = true);
      
      await Future.wait([
        _loadHistoryEntries(reset: true),
        _loadCategories(),
        _loadStatistics(),
      ]);
    } catch (e) {
      if (mounted) {
        ErrorHandler.handleError(context, e, customMessage: 'Geçmiş yüklenirken hata oluştu');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadHistoryEntries({bool reset = false}) async {
    if (reset) {
      _currentPage = 0;
      _hasMoreData = true;
      _historyEntries.clear();
    }
    
    if (!_hasMoreData) return;

    try {
      List<OCRHistoryEntry> newEntries;
      
      if (_searchQuery.isNotEmpty) {
        newEntries = await OCRHistoryDatabase.instance.searchOCRHistory(
          _searchQuery,
          limit: _pageSize,
          offset: _currentPage * _pageSize,
        );
      } else {
        newEntries = await OCRHistoryDatabase.instance.getOCRHistory(
          limit: _pageSize,
          offset: _currentPage * _pageSize,
          categoryFilter: _selectedCategory,
          engineFilter: _selectedEngine,
          favoritesOnly: _showFavoritesOnly,
          archivedOnly: _showArchivedOnly,
          sortBy: _sortBy,
          ascending: _sortAscending,
        );
      }
      
      if (newEntries.length < _pageSize) {
        _hasMoreData = false;
      }
      
      if (mounted) {
        setState(() {
          _historyEntries.addAll(newEntries);
          _currentPage++;
        });
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.handleError(context, e, customMessage: 'Veriler yüklenirken hata oluştu');
      }
    }
  }

  Future<void> _loadMoreData() async {
    if (!_hasMoreData || _isLoading) return;
    await _loadHistoryEntries();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await OCRHistoryDatabase.instance.getCategories();
      if (mounted) {
        setState(() => _categories = categories);
      }
    } catch (e) {
      developer.log('Error loading categories: $e');
    }
  }

  Future<void> _loadStatistics() async {
    try {
      final stats = await OCRHistoryDatabase.instance.getStatistics();
      if (mounted) {
        setState(() => _stats = stats);
      }
    } catch (e) {
      developer.log('Error loading statistics: $e');
    }
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query;
      _isSearching = query.isNotEmpty;
    });
    _loadHistoryEntries(reset: true);
  }

  void _applyFilter({
    String? category,
    String? engine,
    bool? favoritesOnly,
    bool? archivedOnly,
  }) {
    setState(() {
      _selectedCategory = category;
      _selectedEngine = engine;
      _showFavoritesOnly = favoritesOnly ?? _showFavoritesOnly;
      _showArchivedOnly = archivedOnly ?? _showArchivedOnly;
    });
    _loadHistoryEntries(reset: true);
  }

  void _changeSorting(String sortBy, {bool? ascending}) {
    setState(() {
      _sortBy = sortBy;
      _sortAscending = ascending ?? !_sortAscending;
    });
    _loadHistoryEntries(reset: true);
  }

  Future<void> _toggleFavorite(OCRHistoryEntry entry) async {
    try {
      await OCRHistoryDatabase.instance.updateOCREntry(
        entry.id!,
        {'is_favorite': !entry.isFavorite},
      );
      
      // Update local entry
      final index = _historyEntries.indexWhere((e) => e.id == entry.id);
      if (index != -1) {
        setState(() {
          _historyEntries[index] = OCRHistoryEntry(
            id: entry.id,
            text: entry.text,
            confidence: entry.confidence,
            engine: entry.engine,
            processingTime: entry.processingTime,
            language: entry.language,
            quality: entry.quality,
            isHandwriting: entry.isHandwriting,
            isBatch: entry.isBatch,
            imageCount: entry.imageCount,
            imageSize: entry.imageSize,
            imagePath: entry.imagePath,
            imageHash: entry.imageHash,
            categoryId: entry.categoryId,
            createdAt: entry.createdAt,
            updatedAt: DateTime.now(),
            isFavorite: !entry.isFavorite,
            isArchived: entry.isArchived,
            title: entry.title,
            notes: entry.notes,
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.handleError(context, e, customMessage: 'Favori durumu değiştirilemedi');
      }
    }
  }

  Future<void> _deleteEntry(OCRHistoryEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deleteConfirmation),
        content: Text(context.l10n.deleteConfirmationMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await OCRHistoryDatabase.instance.deleteOCREntry(entry.id!);
        setState(() {
          _historyEntries.removeWhere((e) => e.id == entry.id);
        });
        
        if (mounted) {
          ErrorHandler.showSuccess(context, context.l10n.recordDeleted);
        }
      } catch (e) {
        if (mounted) {
          ErrorHandler.handleError(context, e, customMessage: context.l10n.recordDeletionFailed);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.ocrHistory),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.history), text: l10n.history),
            Tab(icon: Icon(Icons.category), text: l10n.categories),
            Tab(icon: Icon(Icons.analytics), text: l10n.statistics),
          ],
        ),
        actions: [
          if (_tabController.index == 0) ...[
            IconButton(
              icon: Icon(Icons.search),
              onPressed: _showSearchDialog,
            ),
            IconButton(
              icon: Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.sort),
              onSelected: (value) {
                switch (value) {
                  case 'date_desc':
                    _changeSorting('created_at', ascending: false);
                    break;
                  case 'date_asc':
                    _changeSorting('created_at', ascending: true);
                    break;
                  case 'confidence_desc':
                    _changeSorting('confidence', ascending: false);
                    break;
                  case 'confidence_asc':
                    _changeSorting('confidence', ascending: true);
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(value: 'date_desc', child: Text(l10n.sortByDateDesc)),
                PopupMenuItem(value: 'date_asc', child: Text(l10n.sortByDateAsc)),
                PopupMenuItem(value: 'confidence_desc', child: Text(l10n.sortByConfidenceDesc)),
                PopupMenuItem(value: 'confidence_asc', child: Text(l10n.sortByConfidenceAsc)),
              ],
            ),
          ],
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHistoryTab(),
          _buildCategoriesTab(),
          _buildStatisticsTab(),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_isLoading && _historyEntries.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }

    if (_historyEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              _isSearching ? context.l10n.searchNoResults : context.l10n.noHistory,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey),
            ),
            if (_isSearching) ...[
              SizedBox(height: 8),
              Text(
                '"$_searchQuery" ${context.l10n.searchNoResultsForQuery}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadHistoryEntries(reset: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.all(16),
        itemCount: _historyEntries.length + (_hasMoreData ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _historyEntries.length) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final entry = _historyEntries[index];
          return AppAnimations.slideInFromRight(
            child: _buildHistoryCard(entry),
            duration: AppAnimations.fast,
          );
        },
      ),
    );
  }

  Widget _buildHistoryCard(OCRHistoryEntry entry) {
    final category = _categories.firstWhere(
      (c) => c.id == entry.categoryId,
      orElse: () => OCRCategory(name: context.l10n.uncategorized, createdAt: DateTime.now()),
    );

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openTextEditor(entry),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (entry.title?.isNotEmpty == true) ...[
                          Text(
                            entry.title!,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                        ],
                        Row(
                          children: [
                            Icon(
                              _getEngineIcon(entry.engine),
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            SizedBox(width: 4),
                            Text(
                              entry.engine,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 12),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getConfidenceColor(entry.confidence).withAlpha(25),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${(entry.confidence * 100).toStringAsFixed(0)}%',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: _getConfidenceColor(entry.confidence),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      entry.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: entry.isFavorite ? Colors.red : Colors.grey,
                    ),
                    onPressed: () => _toggleFavorite(entry),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _editEntry(entry);
                          break;
                        case 'delete':
                          _deleteEntry(entry);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 'edit', child: Text(context.l10n.edit)),
                      PopupMenuItem(value: 'delete', child: Text(context.l10n.delete)),
                    ],
                  ),
                ],
              ),
              
              SizedBox(height: 12),
              
              // Text preview
              Text(
                entry.text,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              
              SizedBox(height: 12),
              
              // Footer row
              Row(
                children: [
                  if (entry.categoryId != null) ...[
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(int.parse(category.color?.replaceFirst('#', '0xFF') ?? '0xFF2196F3')).withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        category.name,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Color(int.parse(category.color?.replaceFirst('#', '0xFF') ?? '0xFF2196F3')),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                  ],
                  if (entry.isBatch) ...[
                    Icon(Icons.collections, size: 14, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      '${entry.imageCount} ${context.l10n.images}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                    SizedBox(width: 8),
                  ],
                  Spacer(),
                  Text(
                    _formatDate(entry.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesTab() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        return Card(
          margin: EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Color(int.parse(category.color?.replaceFirst('#', '0xFF') ?? '0xFF2196F3')),
              child: Icon(
                _getCategoryIcon(category.icon),
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(category.name),
            subtitle: Text(category.description ?? ''),
            trailing: Text('${category.itemCount} ${context.l10n.items}'),
            onTap: () => _applyFilter(category: category.id.toString()),
          ),
        );
      },
    );
  }

  Widget _buildStatisticsTab() {
    if (_stats == null) {
      return Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatsCard(
            context.l10n.generalStatistics,
            [
              _buildStatRow(context.l10n.totalRecords, '${_stats!.totalEntries}'),
              _buildStatRow(context.l10n.favorites, '${_stats!.favoritesCount}'),
              _buildStatRow(context.l10n.archived, '${_stats!.archivedCount}'),
              _buildStatRow(context.l10n.averageConfidence, '${(_stats!.averageConfidence * 100).toStringAsFixed(1)}%'),
              _buildStatRow(context.l10n.averageProcessingTime, '${_stats!.averageProcessingTime}ms'),
            ],
          ),
          
          SizedBox(height: 16),
          
          _buildStatsCard(
            context.l10n.engineUsage,
            _stats!.engineStats.entries.map((e) => 
              _buildStatRow(e.key, '${e.value}')
            ).toList(),
          ),
          
          SizedBox(height: 16),
          
          _buildStatsCard(
            context.l10n.languageDistribution,
            _stats!.languageStats.entries.map((e) => 
              _buildStatRow(e.key, '${e.value}')
            ).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.search),
        content: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: context.l10n.searchHint,
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (value) {
            Navigator.pop(context);
            _performSearch(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _searchController.clear();
              _performSearch('');
            },
            child: Text(context.l10n.clear),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performSearch(_searchController.text);
            },
            child: Text(context.l10n.search),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.filter),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Category filter
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: InputDecoration(labelText: context.l10n.category),
              items: [
                DropdownMenuItem(value: null, child: Text(context.l10n.all)),
                ..._categories.map((c) => DropdownMenuItem(
                  value: c.id.toString(),
                  child: Text(c.name),
                )),
              ],
              onChanged: (value) => _selectedCategory = value,
            ),
            SizedBox(height: 16),
            CheckboxListTile(
              title: Text(context.l10n.favoritesOnly),
              value: _showFavoritesOnly,
              onChanged: (value) => _showFavoritesOnly = value ?? false,
            ),
            CheckboxListTile(
              title: Text(context.l10n.archivedOnly),
              value: _showArchivedOnly,
              onChanged: (value) => _showArchivedOnly = value ?? false,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _applyFilter();
            },
            child: Text(context.l10n.apply),
          ),
        ],
      ),
    );
  }

  void _openTextEditor(OCRHistoryEntry entry) {
    Navigator.push(
      context,
      AppAnimations.createRoute(
        page: TextEditorScreen(
          initialText: entry.text,
          l10n: context.l10n,
        ),
        duration: AppAnimations.medium,
      ),
    );
  }

  void _editEntry(OCRHistoryEntry entry) {
    _openTextEditor(entry);
  }

  IconData _getEngineIcon(String engine) {
    switch (engine.toLowerCase()) {
      case 'google ml kit':
        return Icons.smart_toy;
      case 'tesseract':
        return Icons.text_fields;
      default:
        return Icons.camera_alt;
    }
  }

  IconData _getCategoryIcon(String? icon) {
    switch (icon) {
      case 'description':
        return Icons.description;
      case 'note':
        return Icons.note;
      case 'receipt':
        return Icons.receipt;
      case 'badge':
        return Icons.badge;
      case 'book':
        return Icons.book;
      default:
        return Icons.category;
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      if (diff.inHours < 1) {
        return '${diff.inMinutes} ${context.l10n.minutesAgo}';
      }
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return context.l10n.yesterday;
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ${context.l10n.daysAgo}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
