import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../providers/profile_provider.dart';

class CreateProfileScreen extends StatefulWidget {
  final bool isFromProfileTab;

  const CreateProfileScreen({super.key, this.isFromProfileTab = false});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  DateTime? _selectedBirthdate;
  bool _isLoading = false;

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
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
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

  Future<void> _handleCreateProfile() async {
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

    // Validate age
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

    final success = await profileProvider.createProfile(
      name: _nameController.text.trim(),
      age: age,
      birthdate: _selectedBirthdate,
      preferences: [], // Will be set in preferences screen
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      // Navigate to select preferences screen
      Navigator.pushReplacementNamed(context, '/select-preferences');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            profileProvider.errorMessage ?? 'Failed to create profile',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // If not from profile tab, go to login instead of back
        if (!widget.isFromProfileTab) {
          Navigator.pushReplacementNamed(context, '/login');
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: AppColors.lightBlue,
        appBar: AppBar(
          backgroundColor: AppColors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.textDark),
            onPressed: () {
              if (!widget.isFromProfileTab) {
                Navigator.pushReplacementNamed(context, '/login');
              } else {
                Navigator.pop(context);
              }
            },
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
                  const SizedBox(height: 40),
                  // Avatar
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.image,
                            size: 50,
                            color: AppColors.textGray,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              color: AppColors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Title
                  Text(
                    "Create Child's Profile",
                    style: AppTextStyles.heading2,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Create your profile to personalize safe\ncontent.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textGray,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  // Name Field
                  CustomTextField(
                    hintText: 'Name',
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
                          text: 'Save Profile',
                          icon: Icons.save_rounded,
                          onPressed: _handleCreateProfile,
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
