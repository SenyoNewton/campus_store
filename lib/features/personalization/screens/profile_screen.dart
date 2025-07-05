import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_profile_screen.dart';
import 'package:campus_store/features/personalization/controllers/profile_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProfileController());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.orange[900],
        title: Obx(() => Text(
              '${controller.role.value.capitalizeFirst} Profile',
              style: const TextStyle(fontWeight: FontWeight.w600),
            )),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: controller.logout,
          ),
        ],
      ),
      body: Obx(() {
        final user = controller.userData;

        if (user.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Profile Avatar and Basic Info
            Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: user['profileImage'] != null
                      ? NetworkImage(user['profileImage'])
                      : const AssetImage('assets/images/default_avatar.png')
                          as ImageProvider,
                ),
                const SizedBox(height: 16),
                Text(
                  user['name'] ?? 'No Name',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  user['email'] ?? '',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Info Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _infoRow(Icons.badge, 'Index Number',
                      user['indexNumber'] ?? 'N/A'),
                  const Divider(),
                  _infoRow(Icons.school, 'Course', user['course'] ?? 'N/A'),
                  const Divider(),
                  _infoRow(Icons.person, 'Role',
                      user['role']?.toString().toUpperCase() ?? 'N/A'),
                  const Divider(),
                  _infoRow(Icons.phone, 'Phone', user['phone'] ?? 'N/A'),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Actions Section
            Column(
              children: [
                _actionButton(
                  icon: Icons.edit,
                  label: 'Edit Profile',
                  onTap: () => Get.to(() => const EditProfileScreen()),
                  color: Colors.orange[800],
                ),
                const SizedBox(height: 10),
                _actionButton(
                  icon: Icons.lock_reset,
                  label: 'Reset Password',
                  onTap: controller.resetPassword,
                  color: Colors.orange[700],
                ),
                const SizedBox(height: 10),
                _actionButton(
                  icon: Icons.email_outlined,
                  label: 'Verify Email',
                  onTap: controller.sendEmailVerification,
                  color: Colors.orange[600],
                ),
                const SizedBox(height: 10),
                _actionButton(
                  icon: Icons.logout,
                  label: 'Logout',
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    Get.offAllNamed('/login');
                  },
                  color: Colors.red[700],
                ),
              ],
            ),
          ],
        );
      }),
    );
  }

  Widget _infoRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.orange[900]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(fontSize: 14, color: Colors.black54)),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        )
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color? color,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        onPressed: onTap,
      ),
    );
  }
}
