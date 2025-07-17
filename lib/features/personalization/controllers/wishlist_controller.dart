import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WishlistController extends GetxController {
  static WishlistController get instance => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Observable variables
  final RxList<Map<String, dynamic>> _wishlistItems =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadWishlistFromFirestore();
  }

  // Getters
  List<Map<String, dynamic>> get wishlistItems => _wishlistItems;
  bool get isEmpty => _wishlistItems.isEmpty;
  bool get isNotEmpty => _wishlistItems.isNotEmpty;
  int get itemCount => _wishlistItems.length;

  /// Load wishlist from Firestore
  Future<void> loadWishlistFromFirestore() async {
    try {
      isLoading.value = true;

      final user = _auth.currentUser;
      if (user == null) return;

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('wishlist')
          .get();

      _wishlistItems.clear();
      _wishlistItems.addAll(
        doc.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id; // Ensure ID is set
          // Normalize addedAt to int (millisecondsSinceEpoch)
          if (data['addedAt'] is Timestamp) {
            data['addedAt'] =
                (data['addedAt'] as Timestamp).millisecondsSinceEpoch;
          } else if (data['addedAt'] == null) {
            data['addedAt'] = 0;
          }
          return data;
        }).toList(),
      );
    } catch (e) {
      debugPrint('Error loading wishlist: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Add item to wishlist
  Future<void> addToWishlist(Map<String, dynamic> product) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        Get.snackbar('Error', 'Please login to add items to wishlist');
        return;
      }

      final productId = product['id']?.toString();
      if (productId == null) {
        Get.snackbar('Error', 'Invalid product');
        return;
      }

      // Check if already in wishlist
      if (isInWishlist(productId)) {
        Get.snackbar('Info', 'Item already in wishlist');
        return;
      }

      // Add timestamp
      final itemToAdd = Map<String, dynamic>.from(product);
      itemToAdd['addedAt'] = DateTime.now().millisecondsSinceEpoch;

      // Add to Firestore
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('wishlist')
          .doc(productId)
          .set(itemToAdd);

      // Add to local list
      _wishlistItems.add(itemToAdd);

      Get.snackbar(
        'Success',
        'Item added to wishlist',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      debugPrint('Error adding to wishlist: $e');
      Get.snackbar('Error', 'Failed to add item to wishlist');
    }
  }

  /// Remove item from wishlist
  Future<void> removeFromWishlist(String productId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Remove from Firestore
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('wishlist')
          .doc(productId)
          .delete();

      // Remove from local list
      _wishlistItems.removeWhere((item) => item['id'] == productId);

      Get.snackbar(
        'Success',
        'Item removed from wishlist',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } catch (e) {
      debugPrint('Error removing from wishlist: $e');
      Get.snackbar('Error', 'Failed to remove item from wishlist');
    }
  }

  /// Toggle wishlist status for a product
  Future<void> toggleWishlist(Map<String, dynamic> product) async {
    final productId = product['id']?.toString();
    if (productId == null) return;

    if (isInWishlist(productId)) {
      await removeFromWishlist(productId);
    } else {
      await addToWishlist(product);
    }
  }

  /// Check if product is in wishlist
  bool isInWishlist(String productId) {
    return _wishlistItems.any((item) => item['id'] == productId);
  }

  /// Clear entire wishlist
  Future<void> clearWishlist() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Show confirmation dialog
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Clear Wishlist'),
          content: const Text(
              'Are you sure you want to clear your entire wishlist?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Clear', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Clear from Firestore
      final batch = _firestore.batch();
      final docs = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('wishlist')
          .get();

      for (final doc in docs.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      // Clear local list
      _wishlistItems.clear();

      Get.snackbar(
        'Success',
        'Wishlist cleared',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } catch (e) {
      debugPrint('Error clearing wishlist: $e');
      Get.snackbar('Error', 'Failed to clear wishlist');
    }
  }

  /// Get total wishlist value
  double getTotalWishlistValue() {
    return _wishlistItems.fold(0.0, (sum, item) {
      final price = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
      return sum + price;
    });
  }

  /// Get sorted wishlist (by date added, newest first)
  List<Map<String, dynamic>> getSortedWishlist() {
    final sorted = List<Map<String, dynamic>>.from(_wishlistItems);
    sorted.sort((a, b) {
      final dateA = a['addedAt'] ?? 0;
      final dateB = b['addedAt'] ?? 0;
      return dateB.compareTo(dateA); // Newest first
    });
    return sorted;
  }

  /// Refresh wishlist
  Future<void> refreshWishlist() async {
    await loadWishlistFromFirestore();
  }

  /// Get wishlist items by category
  List<Map<String, dynamic>> getWishlistByCategory(String category) {
    return _wishlistItems
        .where((item) => item['category'] == category)
        .toList();
  }

  /// Search wishlist items
  List<Map<String, dynamic>> searchWishlist(String query) {
    if (query.isEmpty) return _wishlistItems;

    return _wishlistItems.where((item) {
      final title = item['title']?.toString().toLowerCase() ?? '';
      final category = item['category']?.toString().toLowerCase() ?? '';
      final searchQuery = query.toLowerCase();

      return title.contains(searchQuery) || category.contains(searchQuery);
    }).toList();
  }
}
