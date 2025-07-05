import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class AddListingScreen extends StatefulWidget {
  const AddListingScreen({super.key});

  @override
  State<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends State<AddListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final picker = ImagePicker();
  final uuid = const Uuid();

  List<File> _selectedImages = [];
  bool _isLoading = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();

  Future<void> _pickImages() async {
    final picked = await picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() {
        _selectedImages = picked.map((x) => File(x.path)).toList();
      });
    }
  }

  Future<List<String>> _saveImagesLocally() async {
    final dir = await getApplicationDocumentsDirectory();
    final List<String> localPaths = [];

    for (var image in _selectedImages) {
      final fileName = '${uuid.v4()}${path.extension(image.path)}';
      final localPath = path.join(dir.path, 'listings', fileName);

      await Directory(path.join(dir.path, 'listings')).create(recursive: true);
      final newImage = await image.copy(localPath);
      localPaths.add(newImage.path);
    }

    return localPaths;
  }

  Future<void> _submitListing() async {
    if (!_formKey.currentState!.validate() || _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill all fields and select images')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;

    try {
      final savedImagePaths = await _saveImagesLocally();

      await FirebaseFirestore.instance.collection('listings').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': _priceController.text.trim(),
        'category': _categoryController.text.trim(),
        'brand': _brandController.text.trim(),
        'ownerId': user?.uid,
        'sellerName': user?.email ?? 'Unknown',
        'createdAt': Timestamp.now(),
        'imagePaths': savedImagePaths,
        'wishlist': [],
        'colors': ['Red', 'Black', 'White'],
        'sizes': ['EU 30', 'EU 32', 'EU 34'],
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing added successfully')),
      );

      Navigator.pop(context);
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error adding listing')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Listing'),
        backgroundColor: Colors.orange[900],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              GestureDetector(
                onTap: _pickImages,
                child: _selectedImages.isEmpty
                    ? Container(
                        height: 150,
                        color: Colors.grey[200],
                        child:
                            const Center(child: Text('Tap to select images')),
                      )
                    : SizedBox(
                        height: 150,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _selectedImages[index],
                                  width: 120,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              _buildTextField(_titleController, 'Title'),
              _buildTextField(_descriptionController, 'Description'),
              _buildTextField(
                  _priceController, 'Price (GHS)', TextInputType.number),
              _buildTextField(_categoryController, 'Category'),
              _buildTextField(_brandController, 'Brand'),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitListing,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[900],
                  minimumSize: const Size.fromHeight(50),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Add Listing',
                        style: TextStyle(color: Colors.white)),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      [TextInputType? type]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        keyboardType: type,
        validator: (value) => value!.isEmpty ? 'Required' : null,
      ),
    );
  }
}
