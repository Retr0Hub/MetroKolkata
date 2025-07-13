import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateFullName() async {
    if (user == null) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .update({'fullName': _nameController.text.trim()});
        navigator.pop(); // Close the dialog
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Name updated successfully!')),
        );
      } catch (e) {
        navigator.pop();
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error updating name: $e')),
        );
      }
    }
  }

  Future<void> _showEditNameDialog(String currentName) async {
    _nameController.text = currentName;
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Full Name'),
          content: Form(
            key: _formKey,
            child: TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your full name';
                }
                return null;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: _updateFullName,
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccount() async {
    if (user == null) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      // Delete user document from Firestore
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).delete();

      // Sign out from providers
      await GoogleSignIn().signOut();
      
      // Delete the user from Firebase Auth
      await user!.delete();

      // Pop all routes until we are back at the root (likely the login screen)
      navigator.popUntil((route) => route.isFirst);

    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'requires-recent-login') {
        message = 'This action requires a recent sign-in. Please log out and log back in to continue.';
      } else {
        message = 'Error deleting account: ${e.message}';
      }
      scaffoldMessenger.showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('An unexpected error occurred: $e')));
    }
  }

  Future<void> _showDeleteConfirmationDialog() async {
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
            'This is a permanent action. All your data will be lost. Are you sure you want to proceed?'),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      _deleteAccount();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      // This should ideally not happen if ProfileScreen is protected
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Not logged in.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        // The hamburger menu is gone. A back button is automatically added.
        title: const Text('Profile & Settings'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Could not load user data.'));
          }

          final userData = snapshot.data!.data()!;
          final String fullName = userData['fullName'] ?? 'N/A';
          final String email = userData['email'] ?? 'N/A';
          final String? photoUrl = user!.photoURL;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            children: [
              _buildProfileHeader(context, fullName, email, photoUrl),
              const SizedBox(height: 24),
              _buildSectionTitle(context, 'Account Settings'),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    _buildSettingsTile(
                      icon: Icons.edit_outlined,
                      title: 'Full Name',
                      subtitle: fullName,
                      onTap: () => _showEditNameDialog(fullName),
                    ),
                    const Divider(height: 1),
                    _buildSettingsTile(
                      icon: Icons.email_outlined,
                      title: 'Email',
                      subtitle: email,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle(context, 'Danger Zone'),
              Card(
                clipBehavior: Clip.antiAlias,
                child: _buildSettingsTile(
                  icon: Icons.delete_forever_outlined,
                  title: 'Delete Account',
                  subtitle: 'This action is permanent',
                  iconColor: Colors.red,
                  titleColor: Colors.red,
                  onTap: _showDeleteConfirmationDialog,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, String name, String email, String? photoUrl) {
    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
          child: photoUrl == null
              ? Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
                  style: const TextStyle(fontSize: 30, color: Colors.white),
                )
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                email,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Color? iconColor,
    Color? titleColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Theme.of(context).colorScheme.primary),
      title: Text(title, style: TextStyle(color: titleColor, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
      trailing: onTap != null ? const Icon(Icons.arrow_forward_ios, size: 16) : null,
      onTap: onTap,
    );
  }
}

