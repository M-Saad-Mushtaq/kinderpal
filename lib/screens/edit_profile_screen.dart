import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../providers/profile_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  DateTime? _selectedBirthdate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Load existing profile data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileProvider = Provider.of<ProfileProvider>(
        context,
        listen: false,
      );
      final selectedProfile = profileProvider.selectedProfile;
      if (selectedProfile != null) {
        _nameController.text = selectedProfile.name;
        _ageController.text = selectedProfile.age.toString();
        _selectedBirthdate = selectedProfile.birthdate;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  int _calculateAge(DateTime birthdate) {
    final today = DateTime.now();
    int age = today.year - birthdate.year;
    if (today.month < birthdate.month ||
        (today.month == birthdate.month && today.day < birthdate.day)) {
      age--;
    }
    return age;
  }

  Future<void> _selectBirthdate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedBirthdate ??
          DateTime.now().subtract(const Duration(days: 365 * 5)),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.white,
              surface: AppColors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedBirthdate = picked;
        // Auto-calculate and populate age
        final calculatedAge = _calculateAge(picked);
        _ageController.text = calculatedAge.toString();
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate birthdate is selected
    if (_selectedBirthdate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a birthdate'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final age = int.tryParse(_ageController.text);
    if (age == null || age < 1 || age > 18) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid age between 1 and 18'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate age matches birthdate
    final calculatedAge = _calculateAge(_selectedBirthdate!);
    if (age != calculatedAge) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Age ($age) does not match birthdate (calculated age: $calculatedAge)',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final selectedProfile = profileProvider.selectedProfile;

    if (selectedProfile != null) {
      final success = await profileProvider.updateProfile(
        profileId: selectedProfile.id,
        name: _nameController.text.trim(),
        age: age,
        birthdate: _selectedBirthdate,
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              profileProvider.errorMessage ?? 'Failed to update profile',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        final selectedProfile = profileProvider.selectedProfile;
        final profileName = selectedProfile?.name ?? 'Guest';

        return Scaffold(
          backgroundColor: AppColors.lightBlue,
          appBar: AppBar(
            backgroundColor: AppColors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: AppColors.textDark),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title
                    Text('Edit Profile Info', style: AppTextStyles.heading2),
                    const SizedBox(height: 10),
                    Text(
                      "Update $profileName's details below.",
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textGray,
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Avatar
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppColors.veryLightBlue,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.child_care,
                            size: 30,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          "$profileName's Avatar (Add Photo)",
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textGray,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    // Name Field
                    CustomTextField(
                      hintText: "Enter child's name",
                      controller: _nameController,
                    ),
                    const SizedBox(height: 16),
                    // Birthdate Field (Date Picker)
                    GestureDetector(
                      onTap: _selectBirthdate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedBirthdate == null
                                    ? 'Select Birthdate *'
                                    : _formatDate(_selectedBirthdate!),
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: _selectedBirthdate == null
                                      ? AppColors.textGray
                                      : AppColors.textDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Age Field (Auto-populated, but editable for verification)
                    CustomTextField(
                      hintText: 'Age (will auto-fill from birthdate)',
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 40),
                    // Save Button
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : CustomButton(
                            text: 'Save Changes',
                            onPressed: _saveChanges,
                          ),
                    const SizedBox(height: 16),
                    // Cancel Button
                    CustomButton(
                      text: 'Cancel',
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      backgroundColor: AppColors.white,
                      textColor: AppColors.textDark,
                      isOutlined: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
