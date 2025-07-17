import 'dart:async';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:campus_store/features/personalization/controllers/wishlist_controller.dart';

class BuyerController extends GetxController {
  static BuyerController get instance => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get wishlist controller instance
  WishlistController get wishlistController => Get.find<WishlistController>();

  // Observable variables
  final RxInt selectedIndex = 0.obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedCategory = 'All'.obs;
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxList<Map<String, dynamic>> allProducts = <Map<String, dynamic>>[].obs;
  final RxSet<String> wishlist = <String>{}.obs; // For UI state only

  // Categories with icons
  final List<String> categories = [
    'All',
    'Electronics',
    'Books',
    'Fashion',
    'Sports',
    'Home',
    'Beauty',
    'Food',
    'Other'
  ];

  final Map<String, IconData> categoryIcons = {
    'All': Icons.grid_view_rounded,
    'Electronics': Icons.devices_rounded,
    'Books': Icons.book_rounded,
    'Fashion': Icons.checkroom_rounded,
    'Sports': Icons.sports_basketball_rounded,
    'Home': Icons.home_rounded,
    'Beauty': Icons.face_rounded,
    'Food': Icons.restaurant_rounded,
    'Other': Icons.category_rounded,
  };

  @override
  void onInit() {
    super.onInit();
    // Initialize wishlist controller
    Get.put(WishlistController());
    loadProducts();
    _syncWishlistState();
  }

  @override
  void onReady() {
    super.onReady();
    // Set up listener for wishlist changes
    ever(wishlistController.wishlistItems as RxInterface<Object?>,
        (_) => _syncWishlistState());
  }

  /// Sync wishlist state with wishlist controller
  void _syncWishlistState() {
    // Update UI wishlist state from wishlist controller
    wishlist.assignAll(
      wishlistController.wishlistItems
          .map((item) => item['id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet(),
    );
  }

  /// Change bottom navigation tab
  void changeTab(int index) {
    selectedIndex.value = index;
  }

  /// Real-time listener for listings so buyers see updates instantly
  StreamSubscription? _listingsSubscription;

  void loadProducts() {
    isLoading.value = true;
    _listingsSubscription?.cancel();
    _listingsSubscription = _firestore
        .collection('listings')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .listen((snapshot) {
      List<Map<String, dynamic>> products = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        if (data['imageUrls'] == null && data['imagePaths'] != null) {
          data['imageUrls'] = List<String>.from(data['imagePaths'] ?? []);
        }
        return data;
      }).toList();

      // Sort: listings with null createdAt (just created) at the top, then by createdAt desc
      products.sort((a, b) {
        final timestampA = a['createdAt'] as Timestamp?;
        final timestampB = b['createdAt'] as Timestamp?;
        if (timestampA == null && timestampB == null) return 0;
        if (timestampA == null) return -1; // nulls first
        if (timestampB == null) return 1;
        return timestampB.compareTo(timestampA);
      });

      allProducts.value = products;
      _syncWishlistState();
      isLoading.value = false;
      debugPrint('Loaded ${products.length} listings (real-time)');
    }, onError: (e) {
      debugPrint('Error loading listings: $e');
      Get.snackbar(
        'Loading Error',
        'Having trouble loading listings. Please check your connection and try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      allProducts.value = [];
      isLoading.value = false;
    });
  }

  @override
  void onClose() {
    _searchTimer?.cancel();
    _listingsSubscription?.cancel();
    super.onClose();
  }

  /// Refresh products (for pull-to-refresh)
  Future<void> refreshProducts() async {
    try {
      isRefreshing.value = true;
      loadProducts();
    } finally {
      isRefreshing.value = false;
    }
  }

  /// Update search query
  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  /// Clear search query
  void clearSearch() {
    searchQuery.value = '';
  }

  /// Update selected category
  void updateSelectedCategory(String category) {
    selectedCategory.value = category;
  }

  /// Get filtered products based on search and category
  List<Map<String, dynamic>> get filteredProducts {
    List<Map<String, dynamic>> filtered = allProducts;

    // Filter by category
    if (selectedCategory.value != 'All') {
      filtered = filtered
          .where((product) => product['category'] == selectedCategory.value)
          .toList();
    }

    // Filter by search query
    if (searchQuery.value.isNotEmpty) {
      filtered = filtered.where((product) {
        final title = product['title']?.toString().toLowerCase() ?? '';
        final description =
            product['description']?.toString().toLowerCase() ?? '';
        final category = product['category']?.toString().toLowerCase() ?? '';
        final query = searchQuery.value.toLowerCase();

        return title.contains(query) ||
            description.contains(query) ||
            category.contains(query);
      }).toList();
    }

    return filtered;
  }

  /// Toggle wishlist status for a product
  Future<void> toggleWishlist(String productId) async {
    try {
      // Find the product
      final product = allProducts.firstWhere(
        (p) => p['id'] == productId,
        orElse: () => <String, dynamic>{},
      );

      if (product.isEmpty) {
        Get.snackbar(
          'Error',
          'Product not found',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Use wishlist controller to toggle
      await wishlistController.toggleWishlist(product);

      // UI state will be updated automatically through the listener
    } catch (e) {
      debugPrint('Error toggling wishlist: $e');
      Get.snackbar(
        'Error',
        'Failed to update wishlist',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Check if product is in wishlist
  bool isInWishlist(String productId) {
    return wishlist.contains(productId);
  }

  /// Get product by ID
  Map<String, dynamic>? getProductById(String productId) {
    try {
      return allProducts.firstWhere((p) => p['id'] == productId);
    } catch (e) {
      debugPrint('Product not found: $productId');
      return null;
    }
  }

  /// Get category count
  int getCategoryCount(String category) {
    if (category == 'All') return allProducts.length;
    return allProducts
        .where((product) => product['category'] == category)
        .length;
  }

  /// Search products with simple debounce
  void searchProducts(String query) {
    // Cancel any existing search timer
    if (_searchTimer != null) {
      _searchTimer!.cancel();
    }

    // Start new search timer
    _searchTimer = Timer(const Duration(milliseconds: 500), () {
      updateSearchQuery(query);
    });
  }

  Timer? _searchTimer;

  /// Get price range for filtered products
  Map<String, double> get priceRange {
    final products = filteredProducts;
    if (products.isEmpty) return {'min': 0.0, 'max': 0.0};

    double min = double.infinity;
    double max = 0.0;

    for (final product in products) {
      final price = double.tryParse(product['price']?.toString() ?? '0') ?? 0.0;
      if (price < min) min = price;
      if (price > max) max = price;
    }

    return {'min': min == double.infinity ? 0.0 : min, 'max': max};
  }

  get favoritesCount => null;

  /// Sort products
  List<Map<String, dynamic>> sortProducts(
    List<Map<String, dynamic>> products,
    String sortBy,
  ) {
    final sortedProducts = List<Map<String, dynamic>>.from(products);

    switch (sortBy) {
      case 'name_asc':
        sortedProducts
            .sort((a, b) => (a['title'] ?? '').compareTo(b['title'] ?? ''));
        break;
      case 'name_desc':
        sortedProducts
            .sort((a, b) => (b['title'] ?? '').compareTo(a['title'] ?? ''));
        break;
      case 'price_asc':
        sortedProducts.sort((a, b) {
          final priceA = double.tryParse(a['price']?.toString() ?? '0') ?? 0.0;
          final priceB = double.tryParse(b['price']?.toString() ?? '0') ?? 0.0;
          return priceA.compareTo(priceB);
        });
        break;
      case 'price_desc':
        sortedProducts.sort((a, b) {
          final priceA = double.tryParse(a['price']?.toString() ?? '0') ?? 0.0;
          final priceB = double.tryParse(b['price']?.toString() ?? '0') ?? 0.0;
          return priceB.compareTo(priceA);
        });
        break;
      case 'newest':
        sortedProducts.sort((a, b) {
          final dateA =
              (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
          final dateB =
              (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
          return dateB.compareTo(dateA);
        });
        break;
      case 'oldest':
        sortedProducts.sort((a, b) {
          final dateA =
              (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
          final dateB =
              (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
          return dateA.compareTo(dateB);
        });
        break;
    }

    return sortedProducts;
  }
}
