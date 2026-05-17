import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/dimensions.dart';
import '../utils/user_preferences.dart';
import '../widgets/custom_text_field.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late String _username = '';
  late String _fullName = '';
  late String _email = '';
  late String _city = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final username = await UserPreferences.getUsername();
    final fullName = await UserPreferences.getUserName();
    final email = await UserPreferences.getUserEmail();
    final city = await UserPreferences.getUserCity();

    setState(() {
      _username = username ?? '';
      _fullName = fullName ?? '';
      _email = email ?? '';
      _city = city ?? '';
      _isLoading = false;
    });
  }

  void _editFullName() {
    final nameController = TextEditingController(text: _fullName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundDark,
        title: const Text(
          'Edit Full Name',
          style: TextStyle(color: AppColors.textWhite),
        ),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: AppColors.textWhite),
          decoration: InputDecoration(
            hintText: 'Enter your full name',
            hintStyle: const TextStyle(color: AppColors.textGrey),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              borderSide: const BorderSide(color: AppColors.textGrey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              borderSide: const BorderSide(
                color: AppColors.primaryOrange,
                width: 2,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textGrey),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                final success = await UserPreferences.updateUserName(
                  nameController.text.trim(),
                );

                if (success) {
                  setState(() {
                    _fullName = nameController.text.trim();
                  });

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Full name updated successfully!'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                    Navigator.pop(context);
                  }
                }
              }
            },
            child: const Text(
              'Save',
              style: TextStyle(color: AppColors.primaryOrange),
            ),
          ),
        ],
      ),
    );
  }

  void _editCity() {
    final cityController = TextEditingController(text: _city);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundDark,
        title: const Text(
          'Edit City',
          style: TextStyle(color: AppColors.textWhite),
        ),
        content: TextField(
          controller: cityController,
          style: const TextStyle(color: AppColors.textWhite),
          decoration: InputDecoration(
            hintText: 'Enter your city',
            hintStyle: const TextStyle(color: AppColors.textGrey),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              borderSide: const BorderSide(color: AppColors.textGrey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              borderSide: const BorderSide(
                color: AppColors.primaryOrange,
                width: 2,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textGrey),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (cityController.text.trim().isNotEmpty) {
                final success = await UserPreferences.updateUserCity(
                  cityController.text.trim(),
                );

                if (success) {
                  setState(() {
                    _city = cityController.text.trim();
                  });

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('City updated successfully!'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                    Navigator.pop(context);
                  }
                }
              }
            },
            child: const Text(
              'Save',
              style: TextStyle(color: AppColors.primaryOrange),
            ),
          ),
        ],
      ),
    );
  }

  void _changePassword() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool _obscureCurrentPassword = true;
    bool _obscureNewPassword = true;
    bool _obscureConfirmPassword = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.backgroundDark,
          title: const Text(
            'Change Password',
            style: TextStyle(color: AppColors.textWhite),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Current Password
                TextField(
                  controller: currentPasswordController,
                  obscureText: _obscureCurrentPassword,
                  style: const TextStyle(color: AppColors.textWhite),
                  decoration: InputDecoration(
                    hintText: 'Current Password',
                    hintStyle: const TextStyle(color: AppColors.textGrey),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureCurrentPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColors.textGrey,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          _obscureCurrentPassword = !_obscureCurrentPassword;
                        });
                      },
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMedium),
                      borderSide: const BorderSide(color: AppColors.textGrey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMedium),
                      borderSide: const BorderSide(
                        color: AppColors.primaryOrange,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // New Password
                TextField(
                  controller: newPasswordController,
                  obscureText: _obscureNewPassword,
                  style: const TextStyle(color: AppColors.textWhite),
                  decoration: InputDecoration(
                    hintText: 'New Password',
                    hintStyle: const TextStyle(color: AppColors.textGrey),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNewPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColors.textGrey,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          _obscureNewPassword = !_obscureNewPassword;
                        });
                      },
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMedium),
                      borderSide: const BorderSide(color: AppColors.textGrey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMedium),
                      borderSide: const BorderSide(
                        color: AppColors.primaryOrange,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Confirm Password
                TextField(
                  controller: confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  style: const TextStyle(color: AppColors.textWhite),
                  decoration: InputDecoration(
                    hintText: 'Confirm Password',
                    hintStyle: const TextStyle(color: AppColors.textGrey),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColors.textGrey,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMedium),
                      borderSide: const BorderSide(color: AppColors.textGrey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMedium),
                      borderSide: const BorderSide(
                        color: AppColors.primaryOrange,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textGrey),
              ),
            ),
            TextButton(
              onPressed: () async {
                if (currentPasswordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter your current password'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (newPasswordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter your new password'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (newPasswordController.text !=
                    confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Passwords do not match'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (newPasswordController.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password must be at least 6 characters'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final success = await UserPreferences.changePassword(
                  currentPassword: currentPasswordController.text,
                  newPassword: newPasswordController.text,
                );

                if (mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password changed successfully!'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Current password is incorrect'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text(
                'Change',
                style: TextStyle(color: AppColors.primaryOrange),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundDark,
        title: const Text(
          'Logout',
          style: TextStyle(color: AppColors.textWhite),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: AppColors.textWhite),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textGrey),
            ),
          ),
          TextButton(
            onPressed: () async {
              await UserPreferences.logoutUser();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: AppColors.textWhite,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryOrange,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile Avatar
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 50,
                        color: AppColors.textWhite,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Username (Non-editable)
                  _buildProfileField(
                    label: 'Username',
                    value: _username,
                    isEditable: false,
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 20),

                  // Email (Non-editable)
                  _buildProfileField(
                    label: 'Email',
                    value: _email,
                    isEditable: false,
                    icon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 20),

                  // Full Name (Editable)
                  _buildEditableProfileField(
                    label: 'Full Name',
                    value: _fullName,
                    icon: Icons.person,
                    onEdit: _editFullName,
                  ),
                  const SizedBox(height: 20),

                  // City (Editable)
                  _buildEditableProfileField(
                    label: 'City',
                    value: _city.isEmpty ? 'Not set' : _city,
                    icon: Icons.location_city,
                    onEdit: _editCity,
                  ),
                  const SizedBox(height: 40),

                  // Change Password Button
                  ElevatedButton.icon(
                    onPressed: _changePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMedium),
                      ),
                    ),
                    icon: const Icon(Icons.lock, color: AppColors.textWhite),
                    label: const Text(
                      'Change Password',
                      style: TextStyle(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Logout Button
                  ElevatedButton.icon(
                    onPressed: _logout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMedium),
                      ),
                    ),
                    icon: const Icon(Icons.logout, color: AppColors.textWhite),
                    label: const Text(
                      'Logout',
                      style: TextStyle(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileField({
    required String label,
    required String value,
    required bool isEditable,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.textGrey),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textGrey,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(icon, color: AppColors.primaryOrange, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditableProfileField({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onEdit,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.textGrey),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              GestureDetector(
                onTap: onEdit,
                child: const Icon(
                  Icons.edit,
                  color: AppColors.primaryOrange,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(icon, color: AppColors.primaryOrange, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}