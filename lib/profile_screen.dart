import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _user = FirebaseAuth.instance.currentUser;
  final _nameController = TextEditingController();
  bool _isEditingName = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateUserName() async {
    if (_user == null || _nameController.text.trim().isEmpty) return;

    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .update({'fullName': _nameController.text.trim()});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name updated successfully!')),
        );
        setState(() {
          _isEditingName = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update name: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      // This should not happen if the app flow is correct, but it's a good safeguard.
      return Scaffold(
        appBar: AppBar(title: const Text('My Profile')),
        body: const Center(child: Text('No user found.')),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream:
          FirebaseFirestore.instance.collection('users').doc(_user!.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('My Profile')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(title: const Text('My Profile')),
            body: const Center(child: Text('Could not load profile.')),
          );
        }

        final userData = snapshot.data!.data()!;
        if (!_isEditingName) {
          _nameController.text = userData['fullName'] ?? '';
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Profile'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildProfileHeader(context, userData),
              const SizedBox(height: 24),
              _buildNameSection(context, userData),
              const SizedBox(height: 16),
              _buildInfoTile(context, 'Email', userData['email'] ?? 'Not provided',
                  Icons.email_outlined),
              if (userData['phoneNumber'] != null &&
                  (userData['phoneNumber'] as String).isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildInfoTile(context, 'Phone Number',
                    userData['phoneNumber'], Icons.phone_outlined),
              ],
              const SizedBox(height: 16),
              _buildInfoTile(
                  context,
                  'Member Since',
                  _formatTimestamp(userData['createdAt']),
                  Icons.calendar_today_outlined),
              const Divider(height: 48),
              _buildThemeSwitcher(context),
              const Divider(height: 48),
              _buildDangerZone(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(
      BuildContext context, Map<String, dynamic> userData) {
    final String name = userData['fullName'] ?? 'U';
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U',
            style: TextStyle(
                fontSize: 40,
                color: Theme.of(context).colorScheme.onPrimaryContainer),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          userData['fullName'] ?? 'User',
          style:
              Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildNameSection(
      BuildContext context, Map<String, dynamic> userData) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Full Name', style: Theme.of(context).textTheme.titleMedium),
                IconButton(
                  icon: Icon(_isEditingName ? Icons.close : Icons.edit_outlined),
                  onPressed: () => setState(() => _isEditingName = !_isEditingName),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_isEditingName)
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Enter new name'),
                      autofocus: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _isSaving
                      ? const CircularProgressIndicator()
                      : IconButton(
                          icon: const Icon(Icons.check),
                          onPressed: _updateUserName,
                          color: Theme.of(context).primaryColor,
                        ),
                ],
              )
            else
              Text(
                userData['fullName'] ?? 'Not set',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 18),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(
      BuildContext context, String title, String subtitle, IconData icon) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.secondary),
        title: Text(title),
        subtitle: Text(
          subtitle,
          style:
              Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildThemeSwitcher(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('App Theme', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(
                value: ThemeMode.light,
                label: Text('Light'),
                icon: Icon(Icons.light_mode_outlined)),
            ButtonSegment(
                value: ThemeMode.dark,
                label: Text('Dark'),
                icon: Icon(Icons.dark_mode_outlined)),
            ButtonSegment(
                value: ThemeMode.system,
                label: Text('System'),
                icon: Icon(Icons.settings_system_daydream_outlined)),
          ],
          selected: {themeProvider.themeMode},
          onSelectionChanged: (newSelection) {
            themeProvider.setTheme(newSelection.first);
          },
        ),
      ],
    );
  }

  Widget _buildDangerZone(BuildContext context) {
    // Placeholder for delete functionality
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Danger Zone',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(color: Theme.of(context).colorScheme.error),
        ),
        const SizedBox(height: 8),
        Card(
          color: Theme.of(context).colorScheme.errorContainer,
          child: ListTile(
            leading: Icon(Icons.delete_forever,
                color: Theme.of(context).colorScheme.onErrorContainer),
            title: Text(
              'Delete Account',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  fontWeight: FontWeight.bold),
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Delete account functionality coming soon.')));
            },
          ),
        ),
      ],
    );
  }
}