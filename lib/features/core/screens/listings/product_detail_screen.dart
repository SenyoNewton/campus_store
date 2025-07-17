import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:campus_store/features/personalization/controllers/wishlist_controller.dart';
import 'package:campus_store/features/core/controllers/cart_controller.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const ProductDetailScreen({super.key, required this.data});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with SingleTickerProviderStateMixin {
  int _quantity = 1;
  int _selectedImageIndex = 0;
  String? _selectedColor;
  String? _selectedSize;
  bool _isWished = false;
  bool _isLoading = false;
  final WishlistController _wishlistController = Get.put(WishlistController());
  String? userId;
  late TabController _tabController;
  final CartController _cartController = Get.put(CartController());

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    userId = _auth.currentUser?.uid;
    _checkWishlistStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkWishlistStatus() async {
    if (userId == null) return;
    try {
      final listingId = widget.data['id'];
      if (listingId == null) return;
      setState(() {
        _isWished = _wishlistController.isInWishlist(listingId);
      });
    } catch (e) {
      print('Error checking wishlist status: $e');
    }
  }

  Future<void> _toggleWishlist() async {
    if (userId == null) {
      Get.snackbar(
        'Login Required',
        'Please login to add items to wishlist',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange[100],
        colorText: Colors.orange[800],
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _wishlistController.toggleWishlist(widget.data);
      setState(() {
        _isWished = _wishlistController.isInWishlist(widget.data['id']);
      });
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update wishlist: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addToCart() async {
    if (userId == null) {
      Get.snackbar(
        'Login Required',
        'Please login to add items to cart',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange[100],
        colorText: Colors.orange[800],
      );
      return;
    }

    // Check if colors and sizes are available and selected
    final colors = List<String>.from(widget.data['colors'] ?? []);
    final sizes = List<String>.from(widget.data['sizes'] ?? []);

    if (colors.isNotEmpty && _selectedColor == null) {
      Get.snackbar(
        'Selection Required',
        'Please select a color',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange[100],
        colorText: Colors.orange[800],
      );
      return;
    }

    if (sizes.isNotEmpty && _selectedSize == null) {
      Get.snackbar(
        'Selection Required',
        'Please select a size',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange[100],
        colorText: Colors.orange[800],
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _cartController.addToCart(
        listingId: widget.data['id'],
        title: widget.data['title'],
        price: widget.data['price'],
        imageUrl: widget.data['imageUrls']?.isNotEmpty == true
            ? widget.data['imageUrls'][0]
            : null,
        quantity: _quantity,
        selectedColor: _selectedColor,
        selectedSize: _selectedSize,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to add item to cart: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _shareProduct() {
    final title = widget.data['title'] ?? 'Check out this product';
    final price = widget.data['price'] ?? '0';
    final text = '$title - GHS $price\n\nFound on Campus Store';
    Share.share(text);
  }

  void _contactSeller() async {
    final sellerPhone = widget.data['sellerPhone'];
    if (sellerPhone != null) {
      final url = Uri.parse('tel:$sellerPhone');
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        Get.snackbar(
          'Error',
          'Cannot make phone call',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } else {
      Get.snackbar(
        'Info',
        'Seller contact not available',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Widget _buildImageSection() {
    final imageUrls = List<String>.from(widget.data['imageUrls'] ?? []);

    if (imageUrls.isEmpty) {
      return Container(
        height: 300,
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: PageView.builder(
            itemCount: imageUrls.length,
            onPageChanged: (index) =>
                setState(() => _selectedImageIndex = index),
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _showImageDialog(imageUrls[index]),
                child: Image.network(
                  imageUrls[index],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child:
                          const Icon(Icons.error, size: 50, color: Colors.grey),
                    );
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        if (imageUrls.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              imageUrls.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _selectedImageIndex == index
                      ? Colors.orange
                      : Colors.grey[300],
                ),
              ),
            ),
          ),
        const SizedBox(height: 10),
        if (imageUrls.length > 1)
          SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: imageUrls.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => setState(() => _selectedImageIndex = index),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _selectedImageIndex == index
                            ? Colors.orange
                            : Colors.grey,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.network(
                      imageUrls[index],
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Image.network(imageUrl, fit: BoxFit.contain),
        ),
      ),
    );
  }

  Widget _buildProductInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.data['title'] ?? 'No Title',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 20),
            const SizedBox(width: 4),
            const Text('4.9', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(width: 8),
            const Text('(199 Reviews)', style: TextStyle(color: Colors.grey)),
            const Spacer(),
            if (widget.data['condition'] != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.data['condition'],
                  style: TextStyle(
                    color: Colors.blue[800],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              'GHS ${widget.data['price'] ?? '0'}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const Spacer(),
            if (widget.data['category'] != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.data['category'],
                  style: TextStyle(
                    color: Colors.orange[800],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildOptionsSection() {
    final colors = List<String>.from(widget.data['colors'] ?? []);
    final sizes = List<String>.from(widget.data['sizes'] ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (colors.isNotEmpty) ...[
          const Text('Color', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: colors.map((color) {
              return ChoiceChip(
                label: Text(color),
                selected: _selectedColor == color,
                onSelected: (_) => setState(() => _selectedColor = color),
                selectedColor: Colors.orange[200],
                backgroundColor: Colors.grey[100],
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
        if (sizes.isNotEmpty) ...[
          const Text('Size', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sizes.map((size) {
              return ChoiceChip(
                label: Text(size),
                selected: _selectedSize == size,
                onSelected: (_) => setState(() => _selectedSize = size),
                selectedColor: Colors.orange[200],
                backgroundColor: Colors.grey[100],
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Quantity',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed:
                      _quantity > 1 ? () => setState(() => _quantity--) : null,
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      Text('$_quantity', style: const TextStyle(fontSize: 16)),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => setState(() => _quantity++),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabSection() {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Colors.orange[900],
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.orange[900],
          tabs: const [
            Tab(text: 'Description'),
            Tab(text: 'Details'),
            Tab(text: 'Reviews'),
          ],
        ),
        SizedBox(
          height: 200,
          child: TabBarView(
            controller: _tabController,
            children: [
              // Description Tab
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Text(
                  widget.data['description'] ?? 'No description available',
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
              ),
              // Details Tab
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.data['brand'] != null)
                      _buildDetailRow('Brand', widget.data['brand']),
                    if (widget.data['category'] != null)
                      _buildDetailRow('Category', widget.data['category']),
                    if (widget.data['condition'] != null)
                      _buildDetailRow('Condition', widget.data['condition']),
                    if (widget.data['location'] != null)
                      _buildDetailRow('Location', widget.data['location']),
                    _buildDetailRow(
                        'Seller', widget.data['sellerName'] ?? 'Unknown'),
                  ],
                ),
              ),
              // Reviews Tab
              const SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('Reviews feature coming soon!'),
                    SizedBox(height: 16),
                    Text('Overall Rating: 4.9/5'),
                    Text('Based on 199 reviews'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        actions: [
          IconButton(
            onPressed: _shareProduct,
            icon: const Icon(Icons.share),
          ),
          IconButton(
            onPressed: _isLoading ? null : _toggleWishlist,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _isWished ? Icons.favorite : Icons.favorite_border,
                    color: Colors.red,
                  ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildImageSection(),
          const SizedBox(height: 16),
          _buildProductInfo(),
          const SizedBox(height: 20),
          _buildOptionsSection(),
          const SizedBox(height: 20),
          _buildTabSection(),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            OutlinedButton(
              onPressed: _contactSeller,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.orange[900]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Icon(Icons.phone, color: Colors.orange[900]),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _addToCart,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.shopping_cart),
                label: Text(_isLoading ? 'Adding...' : 'Add to Cart'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[900],
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
