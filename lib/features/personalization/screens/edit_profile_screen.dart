import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:campus_store/features/personalization/controllers/profile_controller.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final controller = Get.find<ProfileController>();

  late TextEditingController _nameController;
  late TextEditingController _indexController;
  late TextEditingController _courseController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final user = controller.userData;
    _nameController = TextEditingController(text: user['name'] ?? '');
    _indexController = TextEditingController(text: user['indexNumber'] ?? '');
    _courseController = TextEditingController(text: user['course'] ?? '');
    _phoneController = TextEditingController(text: user['phone'] ?? '');
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    String? profileImageUrl = controller.userData['profileImage'];
    if (controller.profileImage != null) {
      profileImageUrl =
          await controller.uploadProfileImage(controller.profileImage!);
    }

    final updatedData = {
      'name': _nameController.text.trim(),
      'indexNumber': _indexController.text.trim(),
      'course': _courseController.text.trim(),
      'phone': _phoneController.text.trim(),
      'profileImage': profileImageUrl,
    };

    await controller.updateProfile(updatedData);
    Get.back();
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool enabled = true,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      readOnly: readOnly,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = controller.userData;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.orange[900],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: () async {
                  await controller.pickProfileImage();
                  setState(() {});
                },
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 55,
                      backgroundImage: controller.profileImage != null
                          ? FileImage(controller.profileImage!)
                          : (user['profileImage'] != null
                                  ? NetworkImage(user['profileImage'])
                                  : const AssetImage(
                                      'assets/images/default_avatar.png'))
                              as ImageProvider,
                    ),
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.orange[800],
                      child:
                          const Icon(Icons.edit, color: Colors.white, size: 18),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 30),
              _buildTextField(
                controller: _nameController,
                label: 'Full Name',
                validator: (value) => value!.isEmpty ? 'Enter your name' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _indexController,
                label: 'Index Number',
                validator: (value) =>
                    value!.isEmpty ? 'Enter index number' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _courseController,
                label: 'Course',
                validator: (value) => value!.isEmpty ? 'Enter course' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                validator: (value) =>
                    value!.isEmpty ? 'Enter phone number' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: TextEditingController(text: user['email'] ?? ''),
                label: 'Email',
                enabled: false,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: TextEditingController(
                    text: user['role']?.toUpperCase() ?? ''),
                label: 'Role',
                enabled: false,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  onPressed: _saveChanges,
                  label: const Text('Save Changes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[900],
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontSize: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
