import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartController extends GetxController {
  static CartController get instance => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Observable variables
  final RxList<Map<String, dynamic>> _cartItems = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isUpdating = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadCartFromFirestore();
  }

  // Getters
  List<Map<String, dynamic>> get cartItems => _cartItems;
  bool get isEmpty => _cartItems.isEmpty;
  bool get isNotEmpty => _cartItems.isNotEmpty;
  int get itemCount => _cartItems.length;

  /// Load cart from Firestore
  Future<void> loadCartFromFirestore() async {
    try {
      isLoading.value = true;

      final user = _auth.currentUser;
      if (user == null) return;

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .orderBy('addedAt', descending: true)
          .get();

      _cartItems.clear();
      _cartItems.addAll(
        doc.docs.map((doc) {
          final data = doc.data();
          data['cartId'] = doc.id; // Store cart document ID
          return data;
        }).toList(),
      );
    } catch (e) {
      debugPrint('Error loading cart: $e');
      Get.snackbar(
        'Error',
        'Failed to load cart items',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Add item to cart
  Future<void> addToCart({
    required String listingId,
    required String title,
    required String price,
    String? imageUrl,
    String? selectedColor,
    String? selectedSize,
    int quantity = 1,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        Get.snackbar(
          'Login Required',
          'Please login to add items to cart',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange[100],
          colorText: Colors.orange[800],
        );
        return;
      }

      // Check if item with same specifications already exists
      final existingItemIndex = _cartItems.indexWhere((item) =>
          item['listingId'] == listingId &&
          item['selectedColor'] == selectedColor &&
          item['selectedSize'] == selectedSize);

      if (existingItemIndex != -1) {
        // Update quantity of existing item
        final existingItem = _cartItems[existingItemIndex];
        final newQuantity = (existingItem['quantity'] ?? 0) + quantity;
        await updateCartItemQuantity(existingItem['cartId'], newQuantity);
        return;
      }

      // Add new item to cart
      final cartData = {
        'listingId': listingId,
        'title': title,
        'price': price,
        'imageUrl': imageUrl,
        'quantity': quantity,
        'selectedColor': selectedColor,
        'selectedSize': selectedSize,
        'addedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .add(cartData);

      // Add to local list with cart ID
      final localCartData = Map<String, dynamic>.from(cartData);
      localCartData['cartId'] = docRef.id;
      localCartData['addedAt'] = DateTime.now().millisecondsSinceEpoch;
      _cartItems.insert(0, localCartData);

      Get.snackbar(
        'Success',
        'Item added to cart',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green[100],
        colorText: Colors.green[800],
        icon: Icon(Icons.shopping_cart, color: Colors.green[800]),
      );
    } catch (e) {
      debugPrint('Error adding to cart: $e');
      Get.snackbar(
        'Error',
        'Failed to add item to cart',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
      );
    }
  }

  /// Remove item from cart
  Future<void> removeFromCart(String cartId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Remove from Firestore
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc(cartId)
          .delete();

      // Remove from local list
      _cartItems.removeWhere((item) => item['cartId'] == cartId);

      Get.snackbar(
        'Removed',
        'Item removed from cart',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange[100],
        colorText: Colors.orange[800],
      );
    } catch (e) {
      debugPrint('Error removing from cart: $e');
      Get.snackbar(
        'Error',
        'Failed to remove item from cart',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
      );
    }
  }

  /// Update item quantity in cart
  Future<void> updateCartItemQuantity(String cartId, int newQuantity) async {
    if (newQuantity <= 0) {
      await removeFromCart(cartId);
      return;
    }

    try {
      isUpdating.value = true;
      final user = _auth.currentUser;
      if (user == null) return;

      // Update in Firestore
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc(cartId)
          .update({'quantity': newQuantity});

      // Update in local list
      final itemIndex =
          _cartItems.indexWhere((item) => item['cartId'] == cartId);
      if (itemIndex != -1) {
        _cartItems[itemIndex]['quantity'] = newQuantity;
        _cartItems.refresh();
      }
    } catch (e) {
      debugPrint('Error updating cart item quantity: $e');
      Get.snackbar(
        'Error',
        'Failed to update quantity',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
      );
    } finally {
      isUpdating.value = false;
    }
  }

  /// Clear entire cart
  Future<void> clearCart() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Show confirmation dialog
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Clear Cart'),
          content:
              const Text('Are you sure you want to clear your entire cart?'),
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
          .collection('cart')
          .get();

      for (final doc in docs.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      // Clear local list
      _cartItems.clear();

      Get.snackbar(
        'Cart Cleared',
        'All items removed from cart',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange[100],
        colorText: Colors.orange[800],
      );
    } catch (e) {
      debugPrint('Error clearing cart: $e');
      Get.snackbar(
        'Error',
        'Failed to clear cart',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
      );
    }
  }

  /// Get total cart value
  double getTotalCartValue() {
    return _cartItems.fold(0.0, (sum, item) {
      final price = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
      final quantity = item['quantity'] ?? 1;
      return sum + (price * quantity);
    });
  }

  /// Get total number of items in cart
  int getTotalItemCount() {
    return _cartItems.fold(
        0, (sum, item) => sum + (item['quantity'] ?? 1) as int);
  }

  /// Check if item is in cart
  bool isInCart(String listingId, {String? color, String? size}) {
    return _cartItems.any((item) =>
        item['listingId'] == listingId &&
        item['selectedColor'] == color &&
        item['selectedSize'] == size);
  }

  /// Get cart item by listing ID and specifications
  Map<String, dynamic>? getCartItem(String listingId,
      {String? color, String? size}) {
    try {
      return _cartItems.firstWhere((item) =>
          item['listingId'] == listingId &&
          item['selectedColor'] == color &&
          item['selectedSize'] == size);
    } catch (e) {
      return null;
    }
  }

  /// Refresh cart
  Future<void> refreshCart() async {
    await loadCartFromFirestore();
  }

  /// Get cart items grouped by seller (if available)
  Map<String, List<Map<String, dynamic>>> getCartItemsBySeller() {
    final Map<String, List<Map<String, dynamic>>> groupedItems = {};

    for (final item in _cartItems) {
      final seller = item['sellerName'] ?? 'Unknown Seller';
      if (!groupedItems.containsKey(seller)) {
        groupedItems[seller] = [];
      }
      groupedItems[seller]!.add(item);
    }

    return groupedItems;
  }

  /// Calculate shipping or handling fee (if applicable)
  double calculateHandlingFee() {
    if (isEmpty) return 0.0;

    final total = getTotalCartValue();
    // Example: Free handling for orders above GHS 100
    return total >= 100 ? 0.0 : 5.0;
  }

  /// Get cart summary
  Map<String, dynamic> getCartSummary() {
    final subtotal = getTotalCartValue();
    final handlingFee = calculateHandlingFee();
    final total = subtotal + handlingFee;

    return {
      'subtotal': subtotal,
      'handlingFee': handlingFee,
      'total': total,
      'itemCount': getTotalItemCount(),
      'uniqueItems': itemCount,
    };
  }
}
