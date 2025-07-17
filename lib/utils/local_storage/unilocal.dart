import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// Universal Local Storage for managing favorites and other local data
/// Compatible with existing FavouritesController structure
class UniLocalStorage extends GetxController {
  static UniLocalStorage get instance => Get.find();

  final GetStorage _storage = GetStorage();

  // Storage keys
  static const String _favoritesKey = 'favourites'; // Match your existing key
  static const String _recentSearchKey = 'recent_searches';
  static const String _recentlyViewedKey = 'recently_viewed';
  static const String _userPreferencesKey = 'user_preferences';
  static const String _cartKey = 'cart';
  static const String _wishlistKey = 'wishlist';

  // Reactive maps and lists for different data types
  final RxMap<String, bool> _favorites = <String, bool>{}.obs;
  final RxList<String> _recentSearches = <String>[].obs;
  final RxList<String> _recentlyViewed = <String>[].obs;
  final RxList<String> _wishlist = <String>[].obs;

  // Getters for reactive data
  Map<String, bool> get favorites => Map.from(_favorites);
  List<String> get recentSearches => _recentSearches.toList();
  List<String> get recentlyViewed => _recentlyViewed.toList();
  List<String> get wishlist => _wishlist.toList();

  @override
  void onInit() {
    super.onInit();
    _loadFavorites();
    _loadRecentSearches();
    _loadRecentlyViewed();
    _loadWishlist();
  }

  // ==================== FAVORITES MANAGEMENT (Compatible with your controller) ====================

  /// Load favorites from storage (compatible with your existing structure)
  void _loadFavorites() {
    try {
      final json = readData(_favoritesKey);
      if (json != null) {
        final storedFavorites = jsonDecode(json) as Map<String, dynamic>;
        _favorites.assignAll(
            storedFavorites.map((key, value) => MapEntry(key, value as bool)));
      }
    } catch (e) {
      print('Error loading favorites: $e');
      _favorites.clear();
    }
  }

  /// Save favorites to storage (compatible with your existing structure)
  void _saveFavorites() {
    try {
      final encodedFavorites = json.encode(_favorites);
      saveData(_favoritesKey, encodedFavorites);
    } catch (e) {
      print('Error saving favorites: $e');
    }
  }

  /// Add item to favorites (returns bool for success)
  Future<bool> addToFavorites(String itemId) async {
    try {
      _favorites[itemId] = true;
      _saveFavorites();
      return true;
    } catch (e) {
      print('Error adding to favorites: $e');
      return false;
    }
  }

  /// Remove item from favorites (returns bool for success)
  Future<bool> removeFromFavorites(String itemId) async {
    try {
      _favorites.remove(itemId);
      await removeData(itemId); // Remove individual key as in your code
      _saveFavorites();
      _favorites.refresh(); // Refresh as in your code
      return true;
    } catch (e) {
      print('Error removing from favorites: $e');
      return false;
    }
  }

  /// Toggle favorite status (compatible with your existing method)
  Future<bool> toggleFavorite(String itemId,
      {Function(String)? onAdd, Function(String)? onRemove}) async {
    try {
      if (!_favorites.containsKey(itemId)) {
        // Add to favorites
        _favorites[itemId] = true;
        _saveFavorites();
        if (onAdd != null) onAdd("The item has been added to your Wishlist.");
        return true;
      } else {
        // Remove from favorites
        await removeData(itemId);
        _favorites.remove(itemId);
        _saveFavorites();
        _favorites.refresh();
        if (onRemove != null) {
          onRemove("The item was removed from your Wishlist.");
        }
        return false;
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      return false;
    }
  }

  /// Check if item is favorite (compatible with your existing method)
  bool isFavorite(String itemId) {
    return _favorites[itemId] ?? false;
  }

  /// Get favorites count
  int get favoritesCount => _favorites.length;

  /// Get favorite IDs as list
  List<String> get favoriteIds => _favorites.keys.toList();

  /// Clear all favorites
  Future<void> clearFavorites() async {
    try {
      _favorites.clear();
      _saveFavorites();
    } catch (e) {
      print('Error clearing favorites: $e');
    }
  }

  /// Get favorites as reactive map for UI binding
  RxMap<String, bool> get favoritesList => _favorites;

  // ==================== BATCH OPERATIONS ====================

  /// Add multiple items to favorites
  Future<bool> addMultipleToFavorites(List<String> itemIds) async {
    try {
      for (String itemId in itemIds) {
        _favorites[itemId] = true;
      }
      _saveFavorites();
      return true;
    } catch (e) {
      print('Error adding multiple to favorites: $e');
      return false;
    }
  }

  /// Remove multiple items from favorites
  Future<bool> removeMultipleFromFavorites(List<String> itemIds) async {
    try {
      for (String itemId in itemIds) {
        _favorites.remove(itemId);
        await removeData(itemId);
      }
      _saveFavorites();
      _favorites.refresh();
      return true;
    } catch (e) {
      print('Error removing multiple from favorites: $e');
      return false;
    }
  }

  // ==================== RECENT SEARCHES ====================

  /// Load recent searches from storage
  void _loadRecentSearches() {
    try {
      final searchList = _storage.read<List>(_recentSearchKey) ?? [];
      _recentSearches.assignAll(searchList.cast<String>());
    } catch (e) {
      print('Error loading recent searches: $e');
      _recentSearches.clear();
    }
  }

  /// Save recent searches to storage
  void _saveRecentSearches() {
    try {
      _storage.write(_recentSearchKey, _recentSearches.toList());
    } catch (e) {
      print('Error saving recent searches: $e');
    }
  }

  /// Add search query to recent searches
  Future<void> addRecentSearch(String query) async {
    try {
      if (query.trim().isEmpty) return;

      // Remove if already exists
      _recentSearches.remove(query);

      // Add to beginning
      _recentSearches.insert(0, query);

      // Keep only last 20 searches
      if (_recentSearches.length > 20) {
        _recentSearches.removeRange(20, _recentSearches.length);
      }

      _saveRecentSearches();
    } catch (e) {
      print('Error adding recent search: $e');
    }
  }

  /// Remove specific search from recent searches
  Future<void> removeRecentSearch(String query) async {
    try {
      _recentSearches.remove(query);
      _saveRecentSearches();
    } catch (e) {
      print('Error removing recent search: $e');
    }
  }

  /// Clear all recent searches
  Future<void> clearRecentSearches() async {
    try {
      _recentSearches.clear();
      _saveRecentSearches();
    } catch (e) {
      print('Error clearing recent searches: $e');
    }
  }

  // ==================== RECENTLY VIEWED ====================

  /// Load recently viewed items from storage
  void _loadRecentlyViewed() {
    try {
      final viewedList = _storage.read<List>(_recentlyViewedKey) ?? [];
      _recentlyViewed.assignAll(viewedList.cast<String>());
    } catch (e) {
      print('Error loading recently viewed: $e');
      _recentlyViewed.clear();
    }
  }

  /// Save recently viewed items to storage
  void _saveRecentlyViewed() {
    try {
      _storage.write(_recentlyViewedKey, _recentlyViewed.toList());
    } catch (e) {
      print('Error saving recently viewed: $e');
    }
  }

  /// Add item to recently viewed
  Future<void> addRecentlyViewed(String itemId) async {
    try {
      // Remove if already exists
      _recentlyViewed.remove(itemId);

      // Add to beginning
      _recentlyViewed.insert(0, itemId);

      // Keep only last 50 items
      if (_recentlyViewed.length > 50) {
        _recentlyViewed.removeRange(50, _recentlyViewed.length);
      }

      _saveRecentlyViewed();
    } catch (e) {
      print('Error adding recently viewed: $e');
    }
  }

  /// Clear recently viewed items
  Future<void> clearRecentlyViewed() async {
    try {
      _recentlyViewed.clear();
      _saveRecentlyViewed();
    } catch (e) {
      print('Error clearing recently viewed: $e');
    }
  }

  // ==================== WISHLIST ====================

  /// Load wishlist from storage
  void _loadWishlist() {
    try {
      final wishlistData = _storage.read<List>(_wishlistKey) ?? [];
      _wishlist.assignAll(wishlistData.cast<String>());
    } catch (e) {
      print('Error loading wishlist: $e');
      _wishlist.clear();
    }
  }

  /// Save wishlist to storage
  void _saveWishlist() {
    try {
      _storage.write(_wishlistKey, _wishlist.toList());
    } catch (e) {
      print('Error saving wishlist: $e');
    }
  }

  /// Add item to wishlist
  Future<bool> addToWishlist(String itemId) async {
    try {
      if (!_wishlist.contains(itemId)) {
        _wishlist.add(itemId);
        _saveWishlist();
        return true;
      }
      return false;
    } catch (e) {
      print('Error adding to wishlist: $e');
      return false;
    }
  }

  /// Remove item from wishlist
  Future<bool> removeFromWishlist(String itemId) async {
    try {
      if (_wishlist.contains(itemId)) {
        _wishlist.remove(itemId);
        _saveWishlist();
        return true;
      }
      return false;
    } catch (e) {
      print('Error removing from wishlist: $e');
      return false;
    }
  }

  /// Toggle wishlist status
  Future<bool> toggleWishlist(String itemId) async {
    if (isInWishlist(itemId)) {
      return await removeFromWishlist(itemId);
    } else {
      return await addToWishlist(itemId);
    }
  }

  /// Check if item is in wishlist
  bool isInWishlist(String itemId) {
    return _wishlist.contains(itemId);
  }

  /// Clear all wishlist items
  Future<void> clearWishlist() async {
    try {
      _wishlist.clear();
      _saveWishlist();
    } catch (e) {
      print('Error clearing wishlist: $e');
    }
  }

  // ==================== USER PREFERENCES ====================

  /// Save user preferences
  Future<void> saveUserPreferences(Map<String, dynamic> preferences) async {
    try {
      _storage.write(_userPreferencesKey, preferences);
    } catch (e) {
      print('Error saving user preferences: $e');
    }
  }

  /// Get user preferences
  Map<String, dynamic> getUserPreferences() {
    try {
      return _storage.read<Map<String, dynamic>>(_userPreferencesKey) ?? {};
    } catch (e) {
      print('Error getting user preferences: $e');
      return {};
    }
  }

  /// Save specific preference
  Future<void> savePreference(String key, dynamic value) async {
    try {
      final preferences = getUserPreferences();
      preferences[key] = value;
      await saveUserPreferences(preferences);
    } catch (e) {
      print('Error saving preference: $e');
    }
  }

  /// Get specific preference
  T? getPreference<T>(String key, {T? defaultValue}) {
    try {
      final preferences = getUserPreferences();
      return preferences[key] ?? defaultValue;
    } catch (e) {
      print('Error getting preference: $e');
      return defaultValue;
    }
  }

  // ==================== CART DATA ====================

  /// Save cart data
  Future<void> saveCartData(Map<String, dynamic> cartData) async {
    try {
      _storage.write(_cartKey, cartData);
    } catch (e) {
      print('Error saving cart data: $e');
    }
  }

  /// Get cart data
  Map<String, dynamic> getCartData() {
    try {
      return _storage.read<Map<String, dynamic>>(_cartKey) ?? {};
    } catch (e) {
      print('Error getting cart data: $e');
      return {};
    }
  }

  /// Clear cart data
  Future<void> clearCartData() async {
    try {
      _storage.remove(_cartKey);
    } catch (e) {
      print('Error clearing cart data: $e');
    }
  }

  // ==================== GENERAL UTILITY METHODS (Compatible with your existing code) ====================

  /// Save any data with custom key (compatible with your existing method)
  Future<void> saveData(String key, dynamic value) async {
    try {
      _storage.write(key, value);
    } catch (e) {
      print('Error saving data for key $key: $e');
    }
  }

  /// Read any data with custom key (compatible with your existing method)
  dynamic readData(String key) {
    try {
      return _storage.read(key);
    } catch (e) {
      print('Error reading data for key $key: $e');
      return null;
    }
  }

  /// Get any data with custom key (with type safety)
  T? getData<T>(String key, {T? defaultValue}) {
    try {
      return _storage.read<T>(key) ?? defaultValue;
    } catch (e) {
      print('Error getting data for key $key: $e');
      return defaultValue;
    }
  }

  /// Remove data with custom key (compatible with your existing method)
  Future<void> removeData(String key) async {
    try {
      _storage.remove(key);
    } catch (e) {
      print('Error removing data for key $key: $e');
    }
  }

  /// Check if key exists
  bool hasKey(String key) {
    try {
      return _storage.hasData(key);
    } catch (e) {
      print('Error checking key existence: $e');
      return false;
    }
  }

  /// Clear all storage data
  Future<void> clearAllData() async {
    try {
      await _storage.erase();
      _favorites.clear();
      _recentSearches.clear();
      _recentlyViewed.clear();
      _wishlist.clear();
    } catch (e) {
      print('Error clearing all data: $e');
    }
  }

  // ==================== DATA MIGRATION & VERSIONING ====================

  /// Get storage version
  int? getStorageVersion() {
    return getData<int>('storage_version', defaultValue: 1);
  }

  /// Set storage version
  Future<void> setStorageVersion(int version) async {
    await saveData('storage_version', version);
  }

  /// Migrate data from old format to new format
  Future<void> migrateData() async {
    try {
      final currentVersion = getStorageVersion();

      if (currentVersion != null && currentVersion < 2) {
        // Example migration logic
        // await _migrateFromV1ToV2();
        await setStorageVersion(2);
      }
    } catch (e) {
      print('Error during data migration: $e');
    }
  }

  // ==================== SYNC METHODS ====================

  /// Sync favorites with server
  Future<bool> syncFavorites(
      Future<List<String>> Function() fetchFromServer) async {
    try {
      final serverFavorites = await fetchFromServer();
      final localFavorites = _favorites.keys.toList();

      // Find differences
      final toAdd =
          serverFavorites.where((id) => !localFavorites.contains(id)).toList();
      final toRemove =
          localFavorites.where((id) => !serverFavorites.contains(id)).toList();

      // Apply changes
      await addMultipleToFavorites(toAdd);
      await removeMultipleFromFavorites(toRemove);

      return true;
    } catch (e) {
      print('Error syncing favorites: $e');
      return false;
    }
  }

  /// Export favorites for backup
  Map<String, dynamic> exportFavorites() {
    return {
      'favorites': _favorites.map,
      'timestamp': DateTime.now().toIso8601String(),
      'version': getStorageVersion(),
    };
  }

  /// Import favorites from backup
  Future<bool> importFavorites(Map<String, dynamic> backup) async {
    try {
      final favoritesData = backup['favorites'] as Map<String, dynamic>?;
      if (favoritesData != null) {
        _favorites.clear();
        _favorites.addAll(favoritesData.cast<String, bool>());
        _saveFavorites();
        return true;
      }
      return false;
    } catch (e) {
      print('Error importing favorites: $e');
      return false;
    }
  }

  // ==================== ANALYTICS & MONITORING ====================

  /// Get storage info with detailed analytics
  Map<String, dynamic> getStorageInfo() {
    return {
      'favorites_count': _favorites.length,
      'recent_searches_count': _recentSearches.length,
      'recently_viewed_count': _recentlyViewed.length,
      'wishlist_count': _wishlist.length,
      'has_user_preferences': hasKey(_userPreferencesKey),
      'has_cart_data': hasKey(_cartKey),
      'storage_version': getStorageVersion(),
      'last_accessed': DateTime.now().toIso8601String(),
    };
  }

  /// Get detailed usage statistics
  Map<String, dynamic> getUsageStats() {
    return {
      'total_keys': _storage.getKeys().length,
      'storage_info': getStorageInfo(),
      'memory_usage': _calculateMemoryUsage(),
    };
  }

  /// Calculate approximate memory usage
  int _calculateMemoryUsage() {
    try {
      int totalSize = 0;
      for (String key in _storage.getKeys()) {
        final value = _storage.read(key);
        if (value is String) {
          totalSize += value.length;
        } else if (value is Map || value is List) {
          totalSize += json.encode(value).length;
        }
      }
      return totalSize;
    } catch (e) {
      print('Error calculating memory usage: $e');
      return 0;
    }
  }
}
