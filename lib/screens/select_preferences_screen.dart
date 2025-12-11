import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../widgets/custom_button.dart';
import '../widgets/category_card.dart';
import '../providers/profile_provider.dart';

class SelectPreferencesScreen extends StatefulWidget {
  const SelectPreferencesScreen({super.key});

  @override
  State<SelectPreferencesScreen> createState() =>
      _SelectPreferencesScreenState();
}

class _SelectPreferencesScreenState extends State<SelectPreferencesScreen> {
  final Set<String> selectedCategories = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Load existing preferences
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final profileProvider = Provider.of<ProfileProvider>(
        context,
        listen: false,
      );

      // If no profile is selected, try to load profiles first
      if (profileProvider.selectedProfile == null &&
          !profileProvider.isLoading) {
        await profileProvider.loadProfiles();
        // If still no profile after loading, select the first one
        if (profileProvider.profiles.isNotEmpty &&
            profileProvider.selectedProfile == null) {
          profileProvider.selectProfile(profileProvider.profiles.first);
        }
      }

      final selectedProfile = profileProvider.selectedProfile;
      if (selectedProfile != null && selectedProfile.preferences.isNotEmpty) {
        setState(() {
          selectedCategories.addAll(selectedProfile.preferences);
        });
      }
    });
  }

  Future<void> _savePreferences() async {
    setState(() => _isLoading = true);

    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final selectedProfile = profileProvider.selectedProfile;

    if (selectedProfile != null) {
      final success = await profileProvider.updateProfile(
        profileId: selectedProfile.id,
        name: selectedProfile.name,
        age: selectedProfile.age,
        preferences: selectedCategories.toList(),
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (success) {
        Navigator.pushReplacementNamed(context, '/custom-rules');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              profileProvider.errorMessage ?? 'Failed to save preferences',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      setState(() => _isLoading = false);
      Navigator.pushReplacementNamed(context, '/custom-rules');
    }
  }

  final List<Map<String, dynamic>> categories = [
    {'title': 'Art &\nCrafts', 'icon': Icons.brush, 'color': AppColors.pink},
    {
      'title': 'Learning',
      'icon': Icons.menu_book,
      'color': AppColors.veryLightBlue,
    },
    {'title': 'Puzzles', 'icon': Icons.extension, 'color': AppColors.yellow},
    {
      'title': 'Urdu\nPoems',
      'icon': Icons.music_note,
      'color': AppColors.lightPurple,
    },
    {'title': 'Science &\nNature', 'icon': Icons.eco, 'color': AppColors.green},
    {
      'title': 'Sports',
      'icon': Icons.sports_basketball,
      'color': AppColors.peach,
    },
    {
      'title': 'Animals',
      'icon': Icons.pets,
      'color': AppColors.pink.withOpacity(0.5),
    },
    {
      'title': 'Activities',
      'icon': Icons.directions_run,
      'color': AppColors.cyan,
    },
    {'title': 'Cooking\nFun', 'icon': Icons.restaurant, 'color': AppColors.red},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.beige,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Title
              Text(
                'Pick Some Preferred\nCategories',
                style: AppTextStyles.heading2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Pick a few interests so we can personalize safe,\nsmart content.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textGray,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              // Categories Grid
              Expanded(
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = selectedCategories.contains(
                      category['title'],
                    );
                    return CategoryCard(
                      title: category['title'],
                      icon: category['icon'],
                      backgroundColor: category['color'],
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            selectedCategories.remove(category['title']);
                          } else {
                            selectedCategories.add(category['title']);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              // Continue Button
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : CustomButton(text: 'Continue', onPressed: _savePreferences),
            ],
          ),
        ),
      ),
    );
  }
}
