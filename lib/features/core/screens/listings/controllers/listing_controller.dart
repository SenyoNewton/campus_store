import 'dart:io';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class ListingController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();

  // Observable variables
  var isLoading = false.obs;
  var isSubmitting = false.obs;
  var listings = <QueryDocumentSnapshot>[].obs;
  var selectedImages = <File>[].obs;
  var currentStep = 0.obs;
  var selectedCategory = ''.obs;
  var selectedServiceType = ''.obs;
  var isService = false.obs;

  // Form controllers
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final locationController = TextEditingController();
  final contactController = TextEditingController();
  final availabilityController = TextEditingController();

  // Categories data
  final List<Map<String, dynamic>> categories = [
    {
      'name': 'Academic Services',
      'icon': Icons.school,
      'items': [
        'Tutoring',
        'Assignment Help',
        'Research Assistance',
        'Note Taking',
        'Exam Preparation'
      ]
    },
    {
      'name': 'Tech Services',
      'icon': Icons.computer,
      'items': [
        'Web Development',
        'App Development',
        'Graphic Design',
        'Data Entry',
        'IT Support'
      ]
    },
    {
      'name': 'Creative Services',
      'icon': Icons.palette,
      'items': [
        'Photography',
        'Video Editing',
        'Writing',
        'Music Production',
        'Art & Design'
      ]
    },
    {
      'name': 'Physical Products',
      'icon': Icons.shopping_bag,
      'items': [
        'Textbooks',
        'Electronics',
        'Furniture',
        'Clothing',
        'Accessories'
      ]
    },
    {
      'name': 'Life Services',
      'icon': Icons.handyman,
      'items': [
        'Cleaning',
        'Delivery',
        'Pet Care',
        'Event Planning',
        'Transportation'
      ]
    }
  ];

  @override
  void onInit() {
    super.onInit();
    fetchUserListings();
  }

  @override
  void onClose() {
    // Dispose controllers
    titleController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    locationController.dispose();
    contactController.dispose();
    availabilityController.dispose();
    super.onClose();
  }

  // Fetch user's listings
  Future<void> fetchUserListings() async {
    isLoading(true);
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      final snapshot = await _firestore
          .collection('listings')
          .where('ownerId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .get();

      listings.assignAll(snapshot.docs);
    } catch (e) {
      _showErrorSnackbar('Failed to fetch listings', e.toString());
    } finally {
      isLoading(false);
    }
  }

  // Category selection
  void selectCategory(String categoryName) {
    selectedCategory.value = categoryName;
    isService.value = categoryName != 'Physical Products';
    selectedServiceType.value = ''; // Reset service type when category changes
  }

  // Service type selection
  void selectServiceType(String serviceType) {
    selectedServiceType.value = serviceType;
  }

  // Image picking
  Future<void> pickImages() async {
    try {
      final picked = await _picker.pickMultiImage();
      if (picked.isNotEmpty) {
        selectedImages.value = picked.map((x) => File(x.path)).toList();
      }
    } catch (e) {
      _showErrorSnackbar('Failed to pick images', e.toString());
    }
  }

  // Remove image
  void removeImage(int index) {
    if (index >= 0 && index < selectedImages.length) {
      selectedImages.removeAt(index);
    }
  }

  // Save images locally
  Future<List<String>> _saveImagesLocally() async {
    final dir = await getApplicationDocumentsDirectory();
    final List<String> localPaths = [];

    for (var image in selectedImages) {
      final fileName = '${_uuid.v4()}${path.extension(image.path)}';
      final localPath = path.join(dir.path, 'listings', fileName);

      await Directory(path.join(dir.path, 'listings')).create(recursive: true);
      final newImage = await image.copy(localPath);
      localPaths.add(newImage.path);
    }

    return localPaths;
  }

  // Form validation
  bool validateCurrentStep() {
    switch (currentStep.value) {
      case 0: // Category step
        return selectedCategory.value.isNotEmpty;
      case 1: // Details step
        return _validateDetailsForm();
      case 2: // Images step
        return true; // Images are optional
      default:
        return false;
    }
  }

  bool _validateDetailsForm() {
    if (titleController.text.trim().isEmpty) return false;
    if (descriptionController.text.trim().isEmpty) return false;
    if (priceController.text.trim().isEmpty) return false;
    if (locationController.text.trim().isEmpty) return false;
    if (contactController.text.trim().isEmpty) return false;
    if (isService.value && availabilityController.text.trim().isEmpty)
      return false;
    if (selectedServiceType.value.isEmpty) return false;

    return true;
  }

  // Navigate to next step
  void nextStep() {
    if (validateCurrentStep()) {
      if (currentStep.value < 2) {
        currentStep.value++;
      } else {
        submitListing();
      }
    } else {
      _showValidationError();
    }
  }

  // Navigate to previous step
  void previousStep() {
    if (currentStep.value > 0) {
      currentStep.value--;
    }
  }

  // Submit listing
  Future<void> submitListing() async {
    if (!_validateDetailsForm()) {
      _showValidationError();
      return;
    }

    isSubmitting(true);
    final user = _auth.currentUser;

    try {
      final savedImagePaths = await _saveImagesLocally();

      final listingData = {
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'price': priceController.text.trim(),
        'category': selectedCategory.value,
        'serviceType': selectedServiceType.value,
        'isService': isService.value,
        'location': locationController.text.trim(),
        'contact': contactController.text.trim(),
        'availability': availabilityController.text.trim(),
        'ownerId': user?.uid,
        'sellerName': user?.displayName ?? user?.email ?? 'Unknown',
        'sellerEmail': user?.email,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'imagePaths': savedImagePaths,
        'wishlist': [],
        'status': 'active',
        'views': 0,
        'rating': 0.0,
        'reviewCount': 0,
        'tags': _generateTags(),
        'featured': false,
        'verified': false,
      };

      await _firestore.collection('listings').add(listingData);

      Get.snackbar(
        'Success!',
        'Your listing has been published successfully',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
        duration: const Duration(seconds: 3),
      );

      // Reset form
      _resetForm();

      // Refresh listings
      fetchUserListings();

      // Navigate back
      Get.back();
    } catch (e) {
      _showErrorSnackbar('Failed to publish listing', e.toString());
    } finally {
      isSubmitting(false);
    }
  }

  // Generate tags for better searchability
  List<String> _generateTags() {
    List<String> tags = [];

    // Add category and service type
    tags.add(selectedCategory.value.toLowerCase());
    tags.add(selectedServiceType.value.toLowerCase());

    // Add words from title and description
    final titleWords = titleController.text.toLowerCase().split(' ');
    final descWords = descriptionController.text.toLowerCase().split(' ');

    tags.addAll(titleWords.where((word) => word.length > 2));
    tags.addAll(descWords.where((word) => word.length > 2));

    // Remove duplicates
    return tags.toSet().toList();
  }

  // Delete listing
  Future<void> deleteListing(String listingId) async {
    try {
      await _firestore.collection('listings').doc(listingId).delete();

      Get.snackbar(
        'Deleted',
        'Listing has been removed successfully',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        icon: const Icon(Icons.delete, color: Colors.white),
      );

      fetchUserListings();
    } catch (e) {
      _showErrorSnackbar('Failed to delete listing', e.toString());
    }
  }

  // Update listing status
  Future<void> updateListingStatus(String listingId, String status) async {
    try {
      await _firestore.collection('listings').doc(listingId).update({
        'status': status,
        'updatedAt': Timestamp.now(),
      });

      Get.snackbar(
        'Updated',
        'Listing status updated to $status',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );

      fetchUserListings();
    } catch (e) {
      _showErrorSnackbar('Failed to update listing', e.toString());
    }
  }

  // Get listings by category
  Future<List<QueryDocumentSnapshot>> getListingsByCategory(
      String category) async {
    try {
      final snapshot = await _firestore
          .collection('listings')
          .where('category', isEqualTo: category)
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs;
    } catch (e) {
      _showErrorSnackbar('Failed to fetch listings', e.toString());
      return [];
    }
  }

  // Search listings
  Future<List<QueryDocumentSnapshot>> searchListings(String query) async {
    try {
      final snapshot = await _firestore
          .collection('listings')
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .get();

      // Filter results based on query
      final filteredDocs = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final title = data['title']?.toString().toLowerCase() ?? '';
        final description = data['description']?.toString().toLowerCase() ?? '';
        final category = data['category']?.toString().toLowerCase() ?? '';
        final serviceType = data['serviceType']?.toString().toLowerCase() ?? '';
        final tags = List<String>.from(data['tags'] ?? []);

        final searchQuery = query.toLowerCase();

        return title.contains(searchQuery) ||
            description.contains(searchQuery) ||
            category.contains(searchQuery) ||
            serviceType.contains(searchQuery) ||
            tags.any((tag) => tag.contains(searchQuery));
      }).toList();

      return filteredDocs;
    } catch (e) {
      _showErrorSnackbar('Failed to search listings', e.toString());
      return [];
    }
  }

  // Reset form
  void _resetForm() {
    titleController.clear();
    descriptionController.clear();
    priceController.clear();
    locationController.clear();
    contactController.clear();
    availabilityController.clear();
    selectedImages.clear();
    currentStep.value = 0;
    selectedCategory.value = '';
    selectedServiceType.value = '';
    isService.value = false;
  }

  // Show validation error
  void _showValidationError() {
    String message = '';

    switch (currentStep.value) {
      case 0:
        message = 'Please select a category';
        break;
      case 1:
        message = 'Please fill in all required fields';
        break;
      default:
        message = 'Please complete the form';
    }

    Get.snackbar(
      'Validation Error',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      icon: const Icon(Icons.error, color: Colors.white),
    );
  }

  // Show error snackbar
  void _showErrorSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      icon: const Icon(Icons.error, color: Colors.white),
      duration: const Duration(seconds: 4),
    );
  }

  // Get user's active listings count
  int get activeListingsCount {
    return listings.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['status'] == 'active';
    }).length;
  }

  // Get user's total views
  int get totalViews {
    return listings.fold(0, (sum, doc) {
      final data = doc.data() as Map<String, dynamic>;
      return sum + (data['views'] as int? ?? 0);
    });
  }
}
