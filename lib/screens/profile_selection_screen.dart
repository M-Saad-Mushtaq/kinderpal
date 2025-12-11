import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './create_profile_screen.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../providers/profile_provider.dart';
import '../widgets/glass_container.dart';

class ProfileSelectionScreen extends StatefulWidget {
  const ProfileSelectionScreen({super.key});

  @override
  State<ProfileSelectionScreen> createState() => _ProfileSelectionScreenState();
}

class _ProfileSelectionScreenState extends State<ProfileSelectionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadProfiles();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Consumer<ProfileProvider>(
            builder: (context, profileProvider, child) {
              if (profileProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!profileProvider.hasProfiles) {
                return _buildNoProfiles(context);
              }

              return _buildProfileGrid(context, profileProvider);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNoProfiles(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GlassContainer(
              width: 120,
              height: 120,
              borderRadius: 60,
              blur: 15,
              opacity: 0.25,
              child: Icon(Icons.person_add, size: 60, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            Text(
              'No Profiles Yet',
              style: AppTextStyles.heading2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Create your first child profile to get started',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/create-profile');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text('Create Profile', style: AppTextStyles.button),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileGrid(
    BuildContext context,
    ProfileProvider profileProvider,
  ) {
    return Column(
      children: [
        const SizedBox(height: 40),
        Text(
          'Who\'s Watching?',
          style: AppTextStyles.heading1.copyWith(fontSize: 32),
        ),
        const SizedBox(height: 40),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 0.8,
            ),
            itemCount: profileProvider.profiles.length + 1,
            itemBuilder: (context, index) {
              if (index == profileProvider.profiles.length) {
                return _buildAddProfileCard(context);
              }
              final profile = profileProvider.profiles[index];
              return _buildProfileCard(context, profile, profileProvider);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(
    BuildContext context,
    profile,
    ProfileProvider profileProvider,
  ) {
    return GestureDetector(
      onTap: () {
        profileProvider.selectProfile(profile);
        Navigator.pushReplacementNamed(context, '/home');
      },
      child: GlassContainer(
        borderRadius: 20,
        blur: 15,
        opacity: 0.2,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(Icons.child_care, size: 50, color: AppColors.white),
            ),
            const SizedBox(height: 16),
            Text(
              profile.name,
              style: AppTextStyles.heading3.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Age ${profile.age}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddProfileCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const CreateProfileScreen(isFromProfileTab: true),
          ),
        );
      },
      child: GlassContainer(
        borderRadius: 20,
        blur: 15,
        opacity: 0.15,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.veryLightBlue,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add, size: 50, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'Add Profile',
              style: AppTextStyles.heading3.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
