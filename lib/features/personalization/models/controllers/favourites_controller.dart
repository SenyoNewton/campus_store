import 'package:get/get.dart';
import 'package:campus_store/utils/local_storage/unilocal.dart';
// import 'package:campus_store/utils/popups/loaders.dart';
// import 'package:campus_store/data/repositories/property_repository.dart';
// import 'package:campus_store/data/repositories/food_repository.dart';
// import 'package:campus_store/models/property_model.dart';
// import 'package:campus_store/models/food_model.dart';

class FavouritesController extends GetxController {
  static FavouritesController get instance => Get.find();

  // Get direct access to storage favorites
  RxMap<String, bool> get favourites => UniLocalStorage.instance.favoritesList;

  @override
  void onInit() {
    super.onInit();
    // No need to initialize here as UniLocalStorage handles it
  }

  /// Check if item is in favourites
  bool isFavourite(String id) {
    return UniLocalStorage.instance.isFavorite(id);
  }

  /// Toggle favourite status for a product
  Future<void> toggleFavouriteProduct(String id) async {
    final storage = UniLocalStorage.instance;

    final wasAdded = await storage.toggleFavorite(
      id,
      onAdd: (message) {
        // Show toast for add
        _showToast(message);
      },
      onRemove: (message) {
        // Show toast for remove
        _showToast(message);
      },
    );

    // Optional: Add analytics tracking
    _trackFavoriteAction(id, wasAdded);
  }

  /// Add item to favourites
  Future<bool> addToFavourites(String id) async {
    final success = await UniLocalStorage.instance.addToFavorites(id);
    if (success) {
      _showToast("The item has been added to your Wishlist.");
      _trackFavoriteAction(id, true);
    }
    return success;
  }

  /// Remove item from favourites
  Future<bool> removeFromFavourites(String id) async {
    final success = await UniLocalStorage.instance.removeFromFavorites(id);
    if (success) {
      _showToast("The item was removed from your Wishlist.");
      _trackFavoriteAction(id, false);
    }
    return success;
  }

  /// Get all favourite product IDs
  List<String> getFavouriteIds() {
    return UniLocalStorage.instance.favoriteIds;
  }

  /// Get favourites count
  int get favouritesCount => UniLocalStorage.instance.favoritesCount;

  /// Clear all favourites
  Future<void> clearAllFavourites() async {
    await UniLocalStorage.instance.clearFavorites();
    _showToast("All favourites have been cleared.");
  }

  /// Add multiple items to favourites
  Future<bool> addMultipleToFavourites(List<String> ids) async {
    final success = await UniLocalStorage.instance.addMultipleToFavorites(ids);
    if (success) {
      _showToast("${ids.length} items added to your Wishlist.");
    }
    return success;
  }

  /// Remove multiple items from favourites
  Future<bool> removeMultipleFromFavourites(List<String> ids) async {
    final success =
        await UniLocalStorage.instance.removeMultipleFromFavorites(ids);
    if (success) {
      _showToast("${ids.length} items removed from your Wishlist.");
    }
    return success;
  }

  // ==================== REPOSITORY METHODS ====================

  /// Get favourite properties (uncomment and implement based on your models)
  /*
  Future<List<PropertyModel>> favouriteProperties() async {
    try {
      final favouriteIds = getFavouriteIds();
      if (favouriteIds.isEmpty) return [];
      
      return await PropertyRepository.instance.getFavouriteProperties(favouriteIds);
    } catch (e) {
      print('Error fetching favourite properties: $e');
      return [];
    }
  }
  */

  /// Get favourite foods (uncomment and implement based on your models)
  /*
  Future<List<FoodModel>> favouriteFoods() async {
    try {
      final favouriteIds = getFavouriteIds();
      if (favouriteIds.isEmpty) return [];
      
      return await FoodRepository.instance.getFavouriteFoods(favouriteIds);
    } catch (e) {
      print('Error fetching favourite foods: $e');
      return [];
    }
  }
  */

  /// Get favourite items by category
  Future<List<String>> getFavouritesByCategory(String category) async {
    try {
      final favouriteIds = getFavouriteIds();
      // Filter by category logic here
      // This is a placeholder - implement based on your data structure
      return favouriteIds.where((id) => id.contains(category)).toList();
    } catch (e) {
      print('Error fetching favourites by category: $e');
      return [];
    }
  }

  // ==================== SYNC METHODS ====================

  /// Sync favourites with server
  Future<bool> syncFavouritesWithServer() async {
    try {
      // Implement server sync logic here
      // Example:
      /*
      final serverFavorites = await ApiService.getFavorites();
      return await UniLocalStorage.instance.syncFavorites(() async {
        return serverFavorites.map((item) => item.id).toList();
      });
      */
      return true;
    } catch (e) {
      print('Error syncing favourites with server: $e');
      return false;
    }
  }

  /// Export favourites for backup
  Map<String, dynamic> exportFavourites() {
    return UniLocalStorage.instance.exportFavorites();
  }

  /// Import favourites from backup
  Future<bool> importFavourites(Map<String, dynamic> backup) async {
    final success = await UniLocalStorage.instance.importFavorites(backup);
    if (success) {
      _showToast("Favourites imported successfully.");
    }
    return success;
  }

  // ==================== ANALYTICS & SEARCH ====================

  /// Search within favourites
  List<String> searchFavourites(String query) {
    if (query.isEmpty) return getFavouriteIds();

    return getFavouriteIds()
        .where((id) => id.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  /// Get favourites statistics
  Map<String, dynamic> getFavouritesStats() {
    return {
      'total_favourites': favouritesCount,
      'favourite_ids': getFavouriteIds(),
      'last_updated': DateTime.now().toIso8601String(),
    };
  }

  /// Check if favourites list is empty
  bool get isEmpty => favouritesCount == 0;

  /// Check if favourites list is not empty
  bool get isNotEmpty => favouritesCount > 0;

  // ==================== PRIVATE HELPER METHODS ====================

  /// Show toast message (implement based on your toast library)
  void _showToast(String message) {
    // Implement your toast logic here
    // Example with Get.snackbar:
    Get.snackbar(
      'Favourites',
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );

    // Or if you have UniLoaders:
    // UniLoaders.customToast(message: message);
  }

  /// Track favorite action for analytics
  void _trackFavoriteAction(String itemId, bool isAdded) {
    // Implement your analytics tracking here
    // Example:
    /*
    AnalyticsService.track(
      isAdded ? 'favorite_added' : 'favorite_removed',
      properties: {
        'item_id': itemId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    */
    print('Favourite ${isAdded ? 'added' : 'removed'}: $itemId');
  }

  // ==================== REACTIVE GETTERS FOR UI ====================

  /// Get reactive favorites map for UI binding
  RxMap<String, bool> get reactiveFavourites => favourites;

  /// Get reactive favorite count for UI binding
  RxInt get reactiveFavouritesCount => favouritesCount.obs;

  /// Get reactive favorite IDs list for UI binding
  RxList<String> get reactiveFavouriteIds => getFavouriteIds().obs;

  // ==================== VALIDATION METHODS ====================

  /// Validate if item ID is valid before adding to favourites
  bool _isValidItemId(String id) {
    return id.isNotEmpty && id.trim().isNotEmpty;
  }

  /// Validate favourite operation
  bool validateFavouriteOperation(String id) {
    if (!_isValidItemId(id)) {
      _showToast("Invalid item ID");
      return false;
    }
    return true;
  }

  // ==================== BATCH OPERATIONS ====================

  /// Process multiple favourite operations
  Future<Map<String, bool>> batchToggleFavourites(List<String> ids) async {
    final results = <String, bool>{};

    for (String id in ids) {
      if (validateFavouriteOperation(id)) {
        final wasAdded = await UniLocalStorage.instance.toggleFavorite(id);
        results[id] = wasAdded;
      }
    }

    if (results.isNotEmpty) {
      _showToast("Processed ${results.length} favourite operations");
    }

    return results;
  }

  // ==================== CLEANUP ====================

  @override
  void onClose() {
    // Perform any cleanup if needed
    super.onClose();
  }
}
