import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const ProductDetailScreen({super.key, required this.data});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  int _selectedImageIndex = 0;
  String? _selectedColor;
  String? _selectedSize;
  bool _isWished = false;
  String? userId;

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid;
    _isWished = widget.data['wishlist']?.contains(userId) ?? false;
  }

  void _toggleWishlist() async {
    final docId = widget.data['id'];
    if (docId == null || userId == null) return;

    final ref = FirebaseFirestore.instance.collection('listings').doc(docId);

    if (_isWished) {
      await ref.update({
        'wishlist': FieldValue.arrayRemove([userId])
      });
    } else {
      await ref.update({
        'wishlist': FieldValue.arrayUnion([userId])
      });
    }

    setState(() => _isWished = !_isWished);
  }

  void _addToBag() {
    if (_selectedColor == null || _selectedSize == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select color and size")),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Added to cart")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final imageUrls = List<String>.from(data['imageUrls'] ?? []);
    final colors = List<String>.from(data['colors'] ?? []);
    final sizes = List<String>.from(data['sizes'] ?? []);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        actions: [
          IconButton(
            onPressed: _toggleWishlist,
            icon: Icon(
              _isWished ? Icons.favorite : Icons.favorite_border,
              color: Colors.red,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (imageUrls.isNotEmpty)
            Column(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: Image.network(
                    imageUrls[_selectedImageIndex],
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 60,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: imageUrls.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedImageIndex = index),
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
                          child: Image.network(imageUrls[index],
                              width: 50, height: 50),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          Text(
            data['title'] ?? '',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Row(
            children: [
              Icon(Icons.star, color: Colors.amber, size: 20),
              SizedBox(width: 4),
              Text('4.9', style: TextStyle(fontWeight: FontWeight.w500)),
              SizedBox(width: 8),
              Text('(199 Reviews)', style: TextStyle(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('78%',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Text(
                'GHS ${data['price'] ?? '0'}',
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(data['description'] ?? '', style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 10),
          if (data['brand'] != null)
            Text('Brand: ${data['brand']}',
                style: const TextStyle(color: Colors.black87)),
          const SizedBox(height: 20),
          if (colors.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Color',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 10,
                  children: colors.map((color) {
                    return ChoiceChip(
                      label: Text(color),
                      selected: _selectedColor == color,
                      onSelected: (_) => setState(() => _selectedColor = color),
                      selectedColor: Colors.orange.shade200,
                    );
                  }).toList(),
                ),
              ],
            ),
          const SizedBox(height: 20),
          if (sizes.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Size',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 10,
                  children: sizes.map((size) {
                    return ChoiceChip(
                      label: Text(size),
                      selected: _selectedSize == size,
                      onSelected: (_) => setState(() => _selectedSize = size),
                      selectedColor: Colors.orange.shade200,
                    );
                  }).toList(),
                ),
              ],
            ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Quantity",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: _quantity > 1
                        ? () => setState(() => _quantity--)
                        : null,
                  ),
                  Text('$_quantity', style: const TextStyle(fontSize: 18)),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => setState(() => _quantity++),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _addToBag,
            icon: const Icon(Icons.shopping_bag),
            label: const Text('Add to Bag'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[900],
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }
}
