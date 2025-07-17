import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class SellerController extends GetxController {
  // Reactive variables
  final RxInt selectedIndex = 0.obs;
  final RxBool isLoading = false.obs;
  final RxBool isUploading = false.obs;
  final RxList<Map<String, dynamic>> myListings = <Map<String, dynamic>>[].obs;
  final RxList<String> wishlist = <String>[].obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedCategory = 'All'.obs;

  // User ID and info
  String? get uid => FirebaseAuth.instance.currentUser?.uid;
  String? get userEmail => FirebaseAuth.instance.currentUser?.email;

  // Categories for filtering
  final List<String> categories = [
    'All',
    'Academic Services',
    'Tech Services',
    'Creative Services',
    'Physical Products',
    'Life Services'
  ];

  // Statistics
  final RxInt totalListings = 0.obs;
  final RxInt activeListings = 0.obs;
  final RxInt soldListings = 0.obs;
  final RxDouble totalRevenue = 0.0.obs;
  final RxInt totalViews = 0.obs;
  final RxDouble averageRating = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    loadMyListings();
    loadWishlist();
    calculateStats();
  }

  // Load seller's listings with real-time updates
  void loadMyListings() {
    if (uid == null) return;

    isLoading.value = true;

    FirebaseFirestore.instance
        .collection('listings')
        .where('ownerId', isEqualTo: uid)
        .snapshots()
        .listen((snapshot) {
      List<Map<String, dynamic>> listings = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Sort: listings with null createdAt (just created) at the top, then by createdAt desc
      listings.sort((a, b) {
        final timestampA = a['createdAt'] as Timestamp?;
        final timestampB = b['createdAt'] as Timestamp?;
        if (timestampA == null && timestampB == null) return 0;
        if (timestampA == null) return -1; // nulls first
        if (timestampB == null) return 1;
        return timestampB.compareTo(timestampA);
      });

      myListings.value = listings;
      calculateStats();
      isLoading.value = false;
    }, onError: (error) {
      print('Error loading listings: $error');
      isLoading.value = false;
      Get.snackbar(
        'Error',
        'Failed to load listings',
        snackPosition: SnackPosition.BOTTOM,
      );
    });
  }

  // Enhanced listing creation with image upload
  Future<bool> createListing({
    required String title,
    required String description,
    required String price,
    required String category,
    required String serviceType,
    required bool isService,
    required String location,
    required String contact,
    required String availability,
    required List<File> images,
  }) async {
    if (uid == null) return false;

    try {
      isUploading.value = true;

      // Upload images to Firebase Storage
      List<String> imageUrls = [];
      if (images.isNotEmpty) {
        imageUrls = await _uploadImages(images);
      }

      // Create listing document
      final listingData = {
        'title': title.trim(),
        'description': description.trim(),
        'price': price.trim(),
        'category': category,
        'serviceType': serviceType,
        'isService': isService,
        'location': location.trim(),
        'contact': contact.trim(),
        'availability': availability.trim(),
        'ownerId': uid,
        'sellerName': userEmail ?? 'Unknown',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'imageUrls': imageUrls,
        'imagePaths': [], // Keep for backward compatibility
        'wishlist': [],
        'status': 'active',
        'views': 0,
        'rating': 0.0,
        'reviewCount': 0,
        'featured': false,
        'promoted': false,
        'reportCount': 0,
        'tags': _generateTags(title, description, category, serviceType),
      };

      final docRef = await FirebaseFirestore.instance
          .collection('listings')
          .add(listingData);

      // Update user's listing count
      await _updateUserStats();

      // Add to recent activity
      await _addToRecentActivity('created_listing', docRef.id, title);

      Get.snackbar(
        'Success!',
        'Your listing has been published successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return true;
    } catch (e) {
      print('Error creating listing: $e');
      Get.snackbar(
        'Error',
        'Failed to create listing. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isUploading.value = false;
    }
  }

  // Upload images to Firebase Storage
  Future<List<String>> _uploadImages(List<File> images) async {
    List<String> imageUrls = [];

    for (int i = 0; i < images.length; i++) {
      try {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final ref = FirebaseStorage.instance
            .ref()
            .child('listings')
            .child(uid!)
            .child(fileName);

        final uploadTask = ref.putFile(images[i]);
        final snapshot = await uploadTask;
        final url = await snapshot.ref.getDownloadURL();
        imageUrls.add(url);
      } catch (e) {
        print('Error uploading image $i: $e');
      }
    }

    return imageUrls;
  }

  // Generate search tags for better discoverability
  List<String> _generateTags(
      String title, String description, String category, String serviceType) {
    final tags = <String>{};

    // Add words from title and description
    final words =
        '${title.toLowerCase()} ${description.toLowerCase()}'.split(' ');
    for (final word in words) {
      if (word.length > 2) {
        tags.add(word.trim());
      }
    }

    // Add category and service type
    tags.add(category.toLowerCase());
    tags.add(serviceType.toLowerCase());

    return tags.toList();
  }

  // Update user statistics
  Future<void> _updateUserStats() async {
    if (uid == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid!).update({
        'totalListings': FieldValue.increment(1),
        'lastActiveAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating user stats: $e');
    }
  }

  // Add to recent activity
  Future<void> _addToRecentActivity(
      String action, String listingId, String title) async {
    if (uid == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid!)
          .collection('activity')
          .add({
        'action': action,
        'listingId': listingId,
        'listingTitle': title,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding to recent activity: $e');
    }
  }

  // Enhanced listing update
  Future<bool> updateListing(
      String listingId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();

      await FirebaseFirestore.instance
          .collection('listings')
          .doc(listingId)
          .update(updates);

      await _addToRecentActivity(
          'updated_listing', listingId, updates['title'] ?? 'Unknown');

      Get.snackbar(
        'Success',
        'Listing updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return true;
    } catch (e) {
      print('Error updating listing: $e');
      Get.snackbar(
        'Error',
        'Failed to update listing',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  // Enhanced toggle listing status
  Future<void> toggleListingStatus(
      String listingId, String currentStatus) async {
    try {
      final newStatus = currentStatus == 'active' ? 'sold' : 'active';
      final updates = {
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (newStatus == 'sold') {
        updates['soldAt'] = FieldValue.serverTimestamp();
      }

      await FirebaseFirestore.instance
          .collection('listings')
          .doc(listingId)
          .update(updates);

      await _addToRecentActivity(
          'status_changed', listingId, 'Status changed to $newStatus');

      Get.snackbar(
        'Success',
        'Listing status updated to ${newStatus.capitalize}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Error updating listing status: $e');
      Get.snackbar(
        'Error',
        'Failed to update listing status',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Enhanced delete listing
  Future<void> deleteListing(String listingId) async {
    try {
      // Get listing data first
      final doc = await FirebaseFirestore.instance
          .collection('listings')
          .doc(listingId)
          .get();

      if (!doc.exists) return;

      final data = doc.data()!;

      // Delete images from storage
      if (data['imageUrls'] != null) {
        for (String url in List<String>.from(data['imageUrls'])) {
          try {
            await FirebaseStorage.instance.refFromURL(url).delete();
          } catch (e) {
            print('Error deleting image: $e');
          }
        }
      }

      // Delete the listing document
      await FirebaseFirestore.instance
          .collection('listings')
          .doc(listingId)
          .delete();

      // Update user stats
      await FirebaseFirestore.instance.collection('users').doc(uid!).update({
        'totalListings': FieldValue.increment(-1),
      });

      await _addToRecentActivity(
          'deleted_listing', listingId, data['title'] ?? 'Unknown');

      Get.snackbar(
        'Success',
        'Listing deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Error deleting listing: $e');
      Get.snackbar(
        'Error',
        'Failed to delete listing',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Load wishlist
  void loadWishlist() async {
    if (uid == null) return;

    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid!).get();

      if (doc.exists) {
        final data = doc.data();
        wishlist.value = List<String>.from(data?['wishlist'] ?? []);
      }
    } catch (e) {
      print('Error loading wishlist: $e');
    }
  }

  // Enhanced calculate statistics
  void calculateStats() {
    totalListings.value = myListings.length;
    activeListings.value =
        myListings.where((item) => item['status'] == 'active').length;
    soldListings.value =
        myListings.where((item) => item['status'] == 'sold').length;

    totalRevenue.value = myListings
        .where((item) => item['status'] == 'sold')
        .fold(
            0.0,
            (sum, item) =>
                sum + (double.tryParse(item['price'].toString()) ?? 0.0));

    totalViews.value =
        myListings.fold(0, (sum, item) => sum + (item['views'] as int? ?? 0));

    if (myListings.isNotEmpty) {
      averageRating.value = myListings.fold(
              0.0, (sum, item) => sum + (item['rating'] as double? ?? 0.0)) /
          myListings.length;
    }
  }

  // Toggle wishlist
  void toggleWishlist(String productId) async {
    if (uid == null) return;

    try {
      if (wishlist.contains(productId)) {
        wishlist.remove(productId);
      } else {
        wishlist.add(productId);
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid!)
          .update({'wishlist': wishlist.toList()});
    } catch (e) {
      print('Error updating wishlist: $e');
    }
  }

  // Promote listing (for premium users)
  Future<void> promoteListing(String listingId) async {
    try {
      await FirebaseFirestore.instance
          .collection('listings')
          .doc(listingId)
          .update({
        'promoted': true,
        'promotedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar(
        'Success',
        'Listing promoted successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Error promoting listing: $e');
      Get.snackbar(
        'Error',
        'Failed to promote listing',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Get filtered listings
  List<Map<String, dynamic>> get filteredListings {
    return myListings.where((listing) {
      final title = listing['title']?.toString().toLowerCase() ?? '';
      final description =
          listing['description']?.toString().toLowerCase() ?? '';
      final category = listing['category'] ?? 'Other';

      final matchesSearch = searchQuery.value.isEmpty ||
          title.contains(searchQuery.value.toLowerCase()) ||
          description.contains(searchQuery.value.toLowerCase());
      final matchesCategory =
          selectedCategory.value == 'All' || selectedCategory.value == category;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  // Get recent listings
  List<Map<String, dynamic>> get recentListings {
    final sorted = List<Map<String, dynamic>>.from(myListings);
    sorted.sort((a, b) {
      final aTime = a['createdAt'] as Timestamp?;
      final bTime = b['createdAt'] as Timestamp?;
      if (aTime == null || bTime == null) return 0;
      return bTime.compareTo(aTime);
    });
    return sorted.take(5).toList();
  }

  // Get best performing listings
  List<Map<String, dynamic>> get bestPerformingListings {
    final sorted = List<Map<String, dynamic>>.from(myListings);
    sorted.sort((a, b) {
      final aViews = a['views'] as int? ?? 0;
      final bViews = b['views'] as int? ?? 0;
      return bViews.compareTo(aViews);
    });
    return sorted.take(5).toList();
  }

  // Navigation methods
  void changeTab(int index) {
    selectedIndex.value = index;
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  void updateSelectedCategory(String category) {
    selectedCategory.value = category;
  }

  // Refresh listings
  void refreshListings() {
    loadMyListings();
  }
}
