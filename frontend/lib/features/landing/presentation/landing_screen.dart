import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../ads/presentation/ad_banner_section.dart';
import '../../ads/presentation/ad_popup_section.dart';
import '../../ads/data/ad_dtos.dart';

import '../../../core/theme.dart';
import '../../../core/design_system.dart';
import '../../../shared/widgets/illustrations.dart';

class LandingScreen extends ConsumerWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // =========================================================
                  // HERO SECTION
                  // =========================================================

                  Material(
                    child: _buildHeroSection(context, theme),
                  ),

                  // =========================================================
                  // MAIN CONTENT
                  // =========================================================

                  LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 600;
                  final horizontalPadding = isMobile ? 16.0 : 20.0;
                  final verticalPadding = isMobile ? 40.0 : 60.0;
                  
                  return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1100),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                              vertical: verticalPadding,
                            ),
                        child: Column(
                          children: [
                            _FadeInSection(
                              child: _buildFeaturesSection(theme),
                            ),

                        const SizedBox(height: 100),

                        _FadeInSection(
                          child: _buildAboutSection(theme),
                        ),

                        const SizedBox(height: 100),

                        _FadeInSection(
                          child: _buildWhoBenefitsSection(theme),
                        ),
                            const SizedBox(height: 48),
                            const AdBannerSection(
                              placement: AdPlacementType.banner,
                              limit: 2,
                            ),
                            const SizedBox(height: 100),
                            _FadeInSection(
                              child: _buildMissionSection(theme),
                            ),
                            const SizedBox(height: 80),
                            _FadeInSection(
                              child: _buildStatsSection(theme),
                            ),
                            const SizedBox(height: 80),
                            _FadeInSection(
                              child: _buildHowItWorksSection(theme),
                            ),

                        const SizedBox(height: 100),

                        _FadeInSection(
                          child: _buildEducationalGuideSection(theme),
                        ),
                            const SizedBox(height: 100),
                            _FadeInSection(
                              child: _buildFAQSection(theme),
                            ),
                            const SizedBox(height: 80),
                            _FadeInSection(
                              child: _buildTestimonialsSection(theme),
                            ),
                            const SizedBox(height: 100),
                            _FadeInSection(
                              child: _buildCTASection(context, theme),
                            ),
                            const SizedBox(height: 80),
                            const _AppFooter(),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                  ),
                ],
              ),
            ),
          ),
          const AdPopupSection(),
        ],
      ),
    );
  }

  // =========================================================
  // HERO SECTION
  // =========================================================

  Widget _buildHeroSection(
    BuildContext context,
    ThemeData theme,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final heroHeight = isMobile
            ? MediaQuery.of(context).size.height * 1.15
            : MediaQuery.of(context).size.height * 1.05;
        
        return SizedBox(
          width: double.infinity,
          height: heroHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
          // Background Image
          Image.asset(
            'assets/hero.png',
            fit: BoxFit.cover,
          ),

          // Dark Overlay
          Container(
            color: Colors.black.withOpacity(0.4),
          ),

          // Decorative Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.15),
                  Colors.black.withOpacity(0.55),
                ],
              ),
            ),
          ),

          // Main Content
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(isMobile ? 20 : 32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 16,
                    sigmaY: 16,
                  ),
                  child: Container(
                    width: isMobile ? double.infinity : 760,
                    padding: EdgeInsets.all(isMobile ? 12 : 42),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(isMobile ? 20 : 32),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Location Chip
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 10 : 14,
                            vertical: isMobile ? 6 : 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                color: Colors.white,
                                size: isMobile ? 14 : 16,
                              ),
                              SizedBox(width: isMobile ? 4 : 6),
                              Text(
                                'Addis Ababa, Ethiopia',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: isMobile ? 11 : 13,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: isMobile ? 12 : 28),

                        // Brand Name with Unique Font
                        Text(
                          'FIDEL GUIDE',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 12 : 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: isMobile ? 3 : 4,
                            height: 1.2,
                          ),
                        ),

                        SizedBox(height: isMobile ? 12 : 24),

                        // Main Heading
                        Text(
                          'Education starts\nfrom the right choice.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.displayMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                            fontSize: isMobile ? 24 : null,
                          ),
                        ),

                        SizedBox(height: isMobile ? 8 : 18),

                        // Amharic Subtitle
                        Text(
                          'ትምህርት በትክክለኛው ምርጫ ይጀምራል።',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white.withOpacity(0.92),
                            fontWeight: FontWeight.w500,
                            fontSize: isMobile ? 14 : null,
                          ),
                        ),

                        SizedBox(height: isMobile ? 16 : 24),

                        // Description
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 580),
                          child: Text(
                            "A modern platform helping Ethiopian families discover, compare, and choose schools that truly fit their child's needs, aspirations, and future.",
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.white.withOpacity(0.85),
                              height: 1.7,
                              fontSize: isMobile ? 13 : null,
                            ),
                          ),
                        ),

                        SizedBox(height: isMobile ? 24 : 40),

                        // Buttons
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            FilledButton.icon(
                              onPressed: () => context.go('/register'),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                padding:
                                    EdgeInsets.symmetric(
                                  horizontal: isMobile ? 20 : 30,
                                  vertical: isMobile ? 14 : 20,
                                ),
                                shape: const StadiumBorder(),
                              ),
                              icon: Text(
                                'Start Exploring',
                                style: TextStyle(fontSize: isMobile ? 13 : null),
                              ),
                              label: Icon(
                                Icons.arrow_forward,
                                size: isMobile ? 16 : 18,
                              ),
                            ),
                            OutlinedButton(
                              onPressed: () => context.go('/login'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(
                                  color: Colors.white,
                                ),
                                padding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 30,
                                  vertical: 20,
                                ),
                                shape: const StadiumBorder(),
                              ),
                              child: const Text('Sign In'),
                            ),
                            OutlinedButton(
                              onPressed: () => context.go('/advertise'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(
                                  color: Colors.white,
                                ),
                                padding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 30,
                                  vertical: 20,
                                ),
                                shape: const StadiumBorder(),
                              ),
                              child: const Text('Advertise with us'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
        );
      },
    );
  }

  // =========================================================
  // FEATURES SECTION
  // =========================================================

  Widget _buildFeaturesSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'OUR SERVICES',
          style: theme.textTheme.labelLarge?.copyWith(letterSpacing: 2),
        ),

        SpacingHelper.lg,

        Text(
          'Empowering education through connected communities.',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 40),
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            final features = [
              {'icon': Icons.auto_awesome_outlined, 'title': 'School Recommendations', 'description': "Tailored school suggestions based on your child's academic and personal needs."},
              {'icon': Icons.location_searching_outlined, 'title': 'Smart Discovery', 'description': 'Compare schools by curriculum, facilities, tuition, and location.'},
              {'icon': Icons.groups_outlined, 'title': 'Parent Engagement', 'description': 'Strengthening communication between schools and families.'},
              {'icon': Icons.trending_up_outlined, 'title': 'Educational Insights', 'description': 'Helping schools and parents make more informed decisions.'},
            ];

            if (isMobile) {
              // Vertical list for mobile
              return Column(
                children: features.map((feature) => _FeatureListItem(
                  theme: theme,
                  icon: feature['icon'] as IconData,
                  title: feature['title'] as String,
                  description: feature['description'] as String,
                )).toList(),
              );
            } else {
              // Two-column grid for desktop
              return Column(
                children: [
                  for (int i = 0; i < features.length; i += 2)
                    Row(
                      children: [
                        Expanded(
                          child: _FeatureListItem(
                            theme: theme,
                            icon: features[i]['icon'] as IconData,
                            title: features[i]['title'] as String,
                            description: features[i]['description'] as String,
                          ),
                        ),
                        if (i + 1 < features.length) ...[
                          const SizedBox(width: 24),
                          Expanded(
                            child: _FeatureListItem(
                              theme: theme,
                              icon: features[i + 1]['icon'] as IconData,
                              title: features[i + 1]['title'] as String,
                              description: features[i + 1]['description'] as String,
                            ),
                          ),
                        ],
                      ],
                    ),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _featureCard(
    ThemeData theme,
    IconData icon,
    String title,
    String description,
  ) {
    return _FeatureCard(
      theme: theme,
      icon: icon,
      title: title,
      description: description,
    );
  }

  Widget _FeatureListItem({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 32,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // ABOUT SECTION
  // =========================================================

  Widget _buildAboutSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'OUR STORY',
          style: theme.textTheme.labelLarge?.copyWith(letterSpacing: 2),
        ),

        SpacingHelper.lg,

        Text(
          'Why We Built Fidel Guide',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        SpacingHelper.xxxl,

        Text(
          'Education is the foundation of every child\'s future, yet finding the right school in Ethiopia has never been easy. We spoke with hundreds of parents across Addis Ababa who shared similar frustrations: spending countless hours visiting schools, relying on word-of-mouth recommendations that often proved unreliable, and struggling to find accurate information about curriculum, facilities, and fees. Many families felt overwhelmed by the lack of centralized, trustworthy information, often making one of the most important decisions for their children based on incomplete or outdated data.',
          style: theme.textTheme.bodyLarge?.copyWith(
            height: 1.8,
            color: theme.colorScheme.onSurface.withOpacity(0.85),
          ),
        ),

        SpacingHelper.xl,

        Text(
          'We realized that technology could bridge this gap - creating a platform that not only aggregates information but makes it accessible, understandable, and actionable for every Ethiopian family. Our vision extends beyond simply connecting families with schools. We aim to transform how educational decisions are made in Ethiopia by fostering transparency, empowering parents with data-driven insights, and creating a community where knowledge is shared freely.',
          style: theme.textTheme.bodyLarge?.copyWith(
            height: 1.8,
            color: theme.colorScheme.onSurface.withOpacity(0.85),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // WHO BENEFITS SECTION
  // =========================================================

  Widget _buildWhoBenefitsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WHO WE SERVE',
          style: theme.textTheme.labelLarge?.copyWith(letterSpacing: 2),
        ),

        SpacingHelper.lg,

        Text(
          'Empowering the entire education ecosystem',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        SpacingHelper.xxxl,

        // For Parents
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.15),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.family_restroom,
                      size: 28,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'For Parents',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'We understand that choosing a school is one of the most important decisions you\'ll make as a parent. Our platform saves you countless hours of research by providing comprehensive, verified information all in one place. You can compare schools side-by-side based on curriculum type, facilities, extracurricular activities, location, and tuition fees - factors that matter most to your family\'s unique situation. Beyond basic information, we offer personalized recommendations that consider your child\'s academic strengths, learning style, and your family\'s preferences, while connecting you with other parents who have firsthand experience with the schools you\'re considering.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.8,
                  color: theme.colorScheme.onSurface.withOpacity(0.85),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 40),

        // For Schools
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: theme.colorScheme.tertiaryContainer.withOpacity(0.15),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.school,
                      size: 28,
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'For Schools',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Schools are the heart of our education system, and we\'re committed to helping you connect with families who are the right fit for your institution. By creating a comprehensive profile on our platform, you can showcase what makes your school unique - your curriculum approach, teaching philosophy, facilities, achievements, and the values that define your community. Our platform streamlines the admissions process by providing tools to manage inquiries, schedule tours, and communicate with prospective families efficiently, while offering analytics that help you understand what families are looking for and connect with a network of schools across Ethiopia.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.8,
                  color: theme.colorScheme.onSurface.withOpacity(0.85),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================
  // EDUCATIONAL GUIDE SECTION
  // =========================================================

  Widget _buildEducationalGuideSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'EDUCATIONAL GUIDE',
          style: theme.textTheme.labelLarge?.copyWith(letterSpacing: 2),
        ),

        SpacingHelper.lg,

        Text(
          '5 Things to Consider When Choosing a School',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        SpacingHelper.xxxl,

        _guideItem(
          theme,
          '1. Curriculum and Educational Philosophy',
          'Understanding a school\'s curriculum approach is fundamental to ensuring it aligns with your child\'s learning style and your family\'s educational values. Some schools follow traditional Ethiopian curriculum, while others offer international programs like Cambridge or International Baccalaureate. Consider whether the school emphasizes rote learning or critical thinking, and don\'t hesitate to ask about class sizes, teacher qualifications, and support for students who need extra help.',
        ),

        SpacingHelper.xl,

        _guideItem(
          theme,
          '2. Location and Logistics',
          'The practical aspects of school attendance can significantly impact your daily life and your child\'s overall experience. Consider commute time and transportation options - long journeys can leave children exhausted and reduce time for homework and family activities. Think about traffic patterns during peak hours, whether the school offers transportation services, and evaluate the safety of the route and surrounding neighborhood.',
        ),

        SpacingHelper.xl,

        _guideItem(
          theme,
          '3. Facilities and Learning Environment',
          'The physical environment plays a crucial role in your child\'s daily experience and learning outcomes. Visit the school to observe classrooms, libraries, science labs, computer facilities, and sports infrastructure. Consider whether the spaces are well-maintained, safe, and conducive to learning, and look for age-appropriate facilities that support your child\'s developmental needs.',
        ),

        SpacingHelper.xl,

        _guideItem(
          theme,
          '4. School Culture and Community',
          'The intangible aspects of school life often determine whether a child truly thrives. Observe interactions between students and teachers during your visit - are they respectful and warm? Does the school foster a sense of community and belonging? Consider the school\'s values and whether they align with your family\'s principles, and look into extracurricular activities that contribute to school spirit and student engagement.',
        ),

        SpacingHelper.xl,

        _guideItem(
          theme,
          '5. Cost and Financial Considerations',
          'Education is an investment, and it\'s important to have a clear understanding of all costs involved. Beyond tuition, consider registration fees, textbook costs, uniforms, meal programs, extracurricular fees, and transportation expenses. Ask about payment schedules and whether the school offers financial aid or scholarships. Consider whether the cost aligns with the value provided and fits within your family\'s budget long-term.',
        ),
      ],
    );
  }

  Widget _guideItem(
    ThemeData theme,
    String title,
    String content,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: theme.textTheme.bodyLarge?.copyWith(
            height: 1.8,
            color: theme.colorScheme.onSurface.withOpacity(0.85),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // MISSION SECTION
  // =========================================================

  Widget _buildMissionSection(ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final sectionHeight = isMobile ? 650.0 : 500.0;
        final horizontalPadding = isMobile ? 16.0 : 40.0;
        final verticalPadding = isMobile ? 32.0 : 80.0;
        
        return Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
          ),
          child: SizedBox(
            width: double.infinity,
            height: sectionHeight,
            child: Stack(
              children: [
                // Background Image
                Image.asset(
                  'assets/hero.png',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: sectionHeight,
                ),

                // Dark Overlay
                Container(
                  width: double.infinity,
                  height: sectionHeight,
                  color: Colors.black.withOpacity(0.5),
                ),

                // Decorative Gradient
                Container(
                  width: double.infinity,
                  height: sectionHeight,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.6),
                      ],
                    ),
                  ),
                ),

                // Main Content
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
              child: Column(
                children: [
                  Text(
                    'MISSION',
                    style: theme.textTheme.labelLarge?.copyWith(
                      letterSpacing: 2,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 40),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 600) {
                        // Two-column layout for larger screens
                        return Row(
                          children: [
                            Expanded(
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.school_outlined,
                                    size: 120,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 40),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Empowering Every Child\'s Future',
                                    style: theme.textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      height: 1.3,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'Our mission is to democratize access to quality education information across Ethiopia. Every child deserves a school that nurtures their potential, and every family deserves the tools to find it.',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      height: 1.7,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      } else {
                        // Single column layout for smaller screens
                        return Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.school_outlined,
                                size: 80,
                                color: Colors.white,
                              ),
                            ),
                            SpacingHelper.xxxl,
                            Text(
                              'Empowering Every Child\'s Future',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                height: 1.3,
                                color: Colors.white,
                              ),
                            ),
                            SpacingHelper.lg,
                            Text(
                              'Our mission is to democratize access to quality education information across Ethiopia. Every child deserves a school that nurtures their potential, and every family deserves the tools to find it.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                height: 1.7,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }

  // =========================================================
  // STATISTICS SECTION
  // =========================================================

  Widget _buildStatsSection(ThemeData theme) {
    return Column(
      children: [
        Text(
          'OUR IMPACT',
          style: theme.textTheme.labelLarge?.copyWith(letterSpacing: 2),
        ),

        SpacingHelper.lg,

        SizedBox(height: AppSpacing.massive),

        // Feature illustrations section
        _FeatureIllustrationsSection(theme: theme),

        SizedBox(height: AppSpacing.massive),

        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            final crossAxisCount = isMobile ? 2 : 4;

            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: isMobile ? 0.9 : 0.85,
              children: [
                _StatCard(
                  theme: theme,
                  icon: Icons.school,
                  value: '500+',
                  label: 'Schools',
                  color: theme.colorScheme.primary,
                ),
                _StatCard(
                  theme: theme,
                  icon: Icons.family_restroom,
                  value: '10,000+',
                  label: 'Parents',
                  color: theme.colorScheme.tertiary,
                ),
                _StatCard(
                  theme: theme,
                  icon: Icons.location_city,
                  value: '10+',
                  label: 'Subcities',
                  color: theme.colorScheme.tertiary,
                ),
                _StatCard(
                  theme: theme,
                  icon: Icons.star,
                  value: '98%',
                  label: 'Satisfaction',
                  color: AppColors.primaryLight,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // =========================================================
  // HOW IT WORKS SECTION
  // =========================================================

  Widget _buildHowItWorksSection(ThemeData theme) {
    final steps = [
      {
        'icon': Icons.person_add,
        'title': 'Create Account',
        'description': 'Sign up in seconds with your email'
      },
      {
        'icon': Icons.tune,
        'title': 'Set Preferences',
        'description': 'Tell us what matters to you'
      },
      {
        'icon': Icons.school,
        'title': 'Get Recommendations',
        'description': 'Receive personalized school matches'
      },
      {
        'icon': Icons.favorite,
        'title': 'Compare & Choose',
        'description': 'Find the perfect fit for your child'
      },
    ];

    return Column(
      children: [
        Text(
          'HOW IT WORKS',
          style: theme.textTheme.labelLarge?.copyWith(letterSpacing: 2),
        ),

        SpacingHelper.lg,

        Text(
          'Simple steps to find the right school.',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        SizedBox(height: AppSpacing.massive),

        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 800;

            if (isMobile) {
              // Vertical layout for mobile
              return Column(
                children: steps.asMap().entries.map((entry) {
                  final index = entry.key;
                  final step = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: _StepCard(
                      theme: theme,
                      stepNumber: index + 1,
                      icon: step['icon'] as IconData,
                      title: step['title'] as String,
                      description: step['description'] as String,
                      isLast: index == steps.length - 1,
                    ),
                  );
                }).toList(),
              );
            } else {
              // Horizontal layout for desktop
              return Row(
                children: [
                  // Card 1
                  Expanded(
                    child: _StepCard(
                      theme: theme,
                      stepNumber: 1,
                      icon: steps[0]['icon'] as IconData,
                      title: steps[0]['title'] as String,
                      description: steps[0]['description'] as String,
                      isLast: false,
                    ),
                  ),
                  // Arrow
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Icon(
                      Icons.arrow_forward,
                      color: theme.colorScheme.primary.withOpacity(0.5),
                      size: 32,
                    ),
                  ),
                  // Card 2
                  Expanded(
                    child: _StepCard(
                      theme: theme,
                      stepNumber: 2,
                      icon: steps[1]['icon'] as IconData,
                      title: steps[1]['title'] as String,
                      description: steps[1]['description'] as String,
                      isLast: false,
                    ),
                  ),
                  // Arrow
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Icon(
                      Icons.arrow_forward,
                      color: theme.colorScheme.primary.withOpacity(0.5),
                      size: 32,
                    ),
                  ),
                  // Card 3
                  Expanded(
                    child: _StepCard(
                      theme: theme,
                      stepNumber: 3,
                      icon: steps[2]['icon'] as IconData,
                      title: steps[2]['title'] as String,
                      description: steps[2]['description'] as String,
                      isLast: false,
                    ),
                  ),
                  // Arrow
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Icon(
                      Icons.arrow_forward,
                      color: theme.colorScheme.primary.withOpacity(0.5),
                      size: 32,
                    ),
                  ),
                  // Card 4
                  Expanded(
                    child: _StepCard(
                      theme: theme,
                      stepNumber: 4,
                      icon: steps[3]['icon'] as IconData,
                      title: steps[3]['title'] as String,
                      description: steps[3]['description'] as String,
                      isLast: true,
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  // =========================================================
  // FAQ SECTION
  // =========================================================

  Widget _buildFAQSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'COMMON QUESTIONS',
          style: theme.textTheme.labelLarge?.copyWith(letterSpacing: 2),
        ),

        SpacingHelper.lg,

        Text(
          'Answers to get you started.',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        SpacingHelper.xxxl,

        _faqItem(
          theme,
          'Is the system free for parents?',
          'Yes. Parents can create accounts and explore schools for free.',
        ),
        _faqItem(
          theme,
          'Which cities are covered?',
          'We are currently focused on Addis Ababa and expanding gradually.',
        ),
        _faqItem(
          theme,
          'How are schools verified?',
          'Each school profile is reviewed before publication to ensure accuracy.',
        ),
        _faqItem(
          theme,
          'How do recommendations work?',
          'We match schools using curriculum, facilities, location, and budget preferences.',
        ),
      ],
    );
  }

  Widget _faqItem(
    ThemeData theme,
    String question,
    String answer,
  ) {
    return _FAQItem(
      theme: theme,
      question: question,
      answer: answer,
    );
  }

  // =========================================================
  // TESTIMONIALS SECTION
  // =========================================================

  Widget _buildTestimonialsSection(ThemeData theme) {
    final testimonials = [
      {
        'quote':
            'This platform made finding the right school for my daughter so easy. The recommendations were spot-on!',
        'name': 'Sarah T.',
        'role': 'Parent',
        'icon': Icons.person,
      },
      {
        'quote':
            'Finally, a platform that understands what Ethiopian families need. The school comparisons are incredibly helpful.',
        'name': 'Dawit A.',
        'role': 'Parent',
        'icon': Icons.person,
      },
      {
        'quote':
            'As a school administrator, this platform has helped us reach more families and showcase our unique programs.',
        'name': 'Hanna M.',
        'role': 'School Administrator',
        'icon': Icons.school,
      },
    ];

    return Column(
      children: [
        Text(
          'TESTIMONIALS',
          style: theme.textTheme.labelLarge?.copyWith(letterSpacing: 2),
        ),

        SpacingHelper.lg,

        Text(
          'What parents are saying.',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        SizedBox(height: AppSpacing.massive),

        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 800;

            if (isMobile) {
              return Column(
                children: testimonials.map((testimonial) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: _TestimonialCard(
                      theme: theme,
                      quote: testimonial['quote'] as String,
                      name: testimonial['name'] as String,
                      role: testimonial['role'] as String,
                      icon: testimonial['icon'] as IconData,
                    ),
                  );
                }).toList(),
              );
            } else {
              return Row(
                children: testimonials.map((testimonial) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: _TestimonialCard(
                        theme: theme,
                        quote: testimonial['quote'] as String,
                        name: testimonial['name'] as String,
                        role: testimonial['role'] as String,
                        icon: testimonial['icon'] as IconData,
                      ),
                    ),
                  );
                }).toList(),
              );
            }
          },
        ),
      ],
    );
  }

  // =========================================================
  // CTA SECTION
  // =========================================================

  Widget _buildCTASection(
    BuildContext context,
    ThemeData theme,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(isMobile ? 32 : 60),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary.withOpacity(0.1),
                theme.colorScheme.tertiary.withOpacity(0.1),
                theme.colorScheme.tertiary.withOpacity(0.1),
              ],
            ),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withOpacity(0.3),
            ),
          ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.tertiary.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            top: 20,
            left: 40,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.tertiary.withOpacity(0.1),
              ),
            ),
          ),

          // Main content
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 24),
            child: Center(
                  child: Column(
                    children: [
                      Text(
                        'Ready to find the right school?',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 16 : null,
                        ),
                      ),

                      SizedBox(height: isMobile ? 12 : 20),

                      Text(
                        'Create your account and begin exploring schools tailored to your child.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                          fontSize: isMobile ? 12 : null,
                        ),
                      ),

                      SpacingHelper.xxxl,

                      FilledButton(
                        onPressed: () => context.go('/register'),
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 16.0 : 40.0,
                            vertical: isMobile ? 12.0 : 24.0,
                          ),
                          shape: const StadiumBorder(),
                          elevation: 2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Create Your Account', style: TextStyle(fontSize: isMobile ? 12 : 16)),
                            SizedBox(width: isMobile ? 4 : 8),
                            Icon(Icons.arrow_forward, size: isMobile ? 16 : 20),
                          ],
                        ),
                      ),

                      SpacingHelper.xxl,

                      Text(
                        'Join 10,000+ parents already using our platform',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
        );
      },
    );
  }
}

// =========================================================
// FEATURE CARD WIDGET
// =========================================================

class _FeatureCard extends StatefulWidget {
  final ThemeData theme;
  final IconData icon;
  final String title;
  final String description;

  const _FeatureCard({
    required this.theme,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _animationController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _animationController.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.all(isMobile ? 12 : 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.theme.colorScheme.surface,
                    widget.theme.colorScheme.surface.withOpacity(0.95),
                  ],
                ),
                border: Border.all(
                  color: widget.theme.colorScheme.outlineVariant.withOpacity(0.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.theme.colorScheme.shadow.withOpacity(_isHovered ? 0.15 : 0.05),
                    blurRadius: _isHovered ? 20 : 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(isMobile ? 5 : 20),
                    decoration: BoxDecoration(
                      color: widget.theme.colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.icon,
                      size: isMobile ? 16 : 48,
                      color: widget.theme.colorScheme.primary,
                    ),
                  ),

                  SizedBox(height: isMobile ? 8 : 28),

                  Text(
                    widget.title,
                    style: widget.theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 13 : 32,
                    ),
                  ),

                  SizedBox(height: isMobile ? 4 : 18),

                  Text(
                    widget.description,
                    style: widget.theme.textTheme.bodySmall?.copyWith(
                      height: 1.5,
                      fontSize: isMobile ? 11 : 20,
                      color: widget.theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// =========================================================
// STAT CARD WIDGET
// =========================================================

class _StatCard extends StatefulWidget {
  final ThemeData theme;
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.theme,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return FadeTransition(
      opacity: _fadeInAnimation,
      child: Container(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              widget.theme.colorScheme.surface,
              widget.theme.colorScheme.surface.withOpacity(0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.theme.colorScheme.outlineVariant.withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: widget.theme.colorScheme.shadow.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(isMobile ? 8 : 12),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                widget.icon,
                size: isMobile ? 24 : 32,
                color: widget.color,
              ),
            ),
            SizedBox(height: isMobile ? 8 : 16),
            Text(
              widget.value,
              style: widget.theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: widget.color,
                fontSize: isMobile ? 20 : null,
              ),
            ),
            SizedBox(height: isMobile ? 4 : 8),
            Text(
              widget.label,
              style: widget.theme.textTheme.bodyMedium?.copyWith(
                color: widget.theme.colorScheme.onSurface.withOpacity(0.7),
                fontSize: isMobile ? 12 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================
// STEP CARD WIDGET
// =========================================================

class _StepCard extends StatefulWidget {
  final ThemeData theme;
  final int stepNumber;
  final IconData icon;
  final String title;
  final String description;
  final bool isLast;

  const _StepCard({
    required this.theme,
    required this.stepNumber,
    required this.icon,
    required this.title,
    required this.description,
    required this.isLast,
  });

  @override
  State<_StepCard> createState() => _StepCardState();
}

class _StepCardState extends State<_StepCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _animationController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _animationController.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          height: 190,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.theme.colorScheme.surface,
                widget.theme.colorScheme.surface.withOpacity(0.95),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.theme.colorScheme.outlineVariant.withOpacity(0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: widget.theme.colorScheme.shadow
                    .withOpacity(_isHovered ? 0.1 : 0.05),
                blurRadius: _isHovered ? 15 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: widget.theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${widget.stepNumber}',
                        style: widget.theme.textTheme.titleMedium?.copyWith(
                          color: widget.theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.theme.colorScheme.primaryContainer
                          .withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 24,
                      color: widget.theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              Text(
                widget.title,
                style: widget.theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                widget.description,
                style: widget.theme.textTheme.bodyMedium?.copyWith(
                  height: 1.4,
                  color: widget.theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================================================
// FAQ ITEM WIDGET
// =========================================================

class _FAQItem extends StatefulWidget {
  final ThemeData theme;
  final String question;
  final String answer;

  const _FAQItem({
    required this.theme,
    required this.question,
    required this.answer,
  });

  @override
  State<_FAQItem> createState() => _FAQItemState();
}

class _FAQItemState extends State<_FAQItem>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: _toggleExpand,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.theme.colorScheme.surface,
                widget.theme.colorScheme.surface.withOpacity(0.98),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.theme.colorScheme.outlineVariant
                  .withOpacity(_isHovered ? 0.8 : 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: widget.theme.colorScheme.shadow
                    .withOpacity(_isHovered ? 0.1 : 0.05),
                blurRadius: _isHovered ? 12 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.question,
                      style: widget.theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  RotationTransition(
                    turns: _rotationAnimation,
                    child: Icon(
                      Icons.expand_more,
                      color: widget.theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              SizeTransition(
                sizeFactor: _expandAnimation,
                axisAlignment: -1.0,
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    widget.answer,
                    style: widget.theme.textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                      color:
                          widget.theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================================================
// TESTIMONIAL CARD WIDGET
// =========================================================

class _TestimonialCard extends StatefulWidget {
  final ThemeData theme;
  final String quote;
  final String name;
  final String role;
  final IconData icon;

  const _TestimonialCard({
    required this.theme,
    required this.quote,
    required this.name,
    required this.role,
    required this.icon,
  });

  @override
  State<_TestimonialCard> createState() => _TestimonialCardState();
}

class _TestimonialCardState extends State<_TestimonialCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _animationController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _animationController.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 800;
            return Container(
              height: isMobile ? 340 : 320,
              padding: EdgeInsets.all(isMobile ? 20 : 28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.theme.colorScheme.surface,
                widget.theme.colorScheme.surface.withOpacity(0.95),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.theme.colorScheme.outlineVariant.withOpacity(0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: widget.theme.colorScheme.shadow
                    .withOpacity(_isHovered ? 0.12 : 0.06),
                blurRadius: _isHovered ? 16 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.theme.colorScheme.primaryContainer
                      .withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.format_quote,
                  size: 28,
                  color: widget.theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.quote,
                style: widget.theme.textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                  fontStyle: FontStyle.italic,
                  color: widget.theme.colorScheme.onSurface.withOpacity(0.85),
                ),
              ),
              SpacingHelper.xxl,
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: widget.theme.colorScheme.tertiaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 24,
                      color: widget.theme.colorScheme.tertiary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.name,
                        style: widget.theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.role,
                        style: widget.theme.textTheme.bodySmall?.copyWith(
                          color: widget.theme.colorScheme.onSurface
                              .withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
            );
          },
        ),
      ),
    );
  }
}

// =========================================================
// FADE IN SECTION WIDGET
// =========================================================

class _FadeInSection extends StatefulWidget {
  final Widget child;

  const _FadeInSection({required this.child});

  @override
  State<_FadeInSection> createState() => _FadeInSectionState();
}

class _FadeInSectionState extends State<_FadeInSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    // Start animation after a brief delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeInAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(_fadeInAnimation),
        child: widget.child,
      ),
    );
  }
}

// =========================================================
// FOOTER
// =========================================================

class _AppFooter extends StatelessWidget {
  const _AppFooter();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              
              if (isMobile) {
                return Column(
                  children: [
                    Text(
                      'Fidel Guide',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your trusted partner in education',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.email_outlined,
                          size: 16,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'info@fidelguide.com',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => context.go('/advertise'),
                      child: const Text('Advertise with us'),
                    ),
                  ],
                );
              } else {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fidel Guide',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your trusted partner in education',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.email_outlined,
                          size: 16,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'info@fidelguide.com',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(width: 24),
                        TextButton(
                          onPressed: () => context.go('/advertise'),
                          child: const Text('Advertise with us'),
                        ),
                      ],
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

/// Feature illustrations section showcasing key benefits with custom graphics
class _FeatureIllustrationsSection extends StatelessWidget {
  final ThemeData theme;

  const _FeatureIllustrationsSection({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Why Choose Our Platform?',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        SpacingHelper.lg,
        Text(
          'We provide comprehensive tools to help you find the perfect educational environment',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
        SpacingHelper.xxxl,
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 800;
            if (isMobile) {
              return Column(
                children: [
                  _IllustrationFeatureCard(
                    illustration: IllustrationType.education,
                    title: 'Quality Education',
                    description: 'Access detailed information about curriculum, facilities, and performance metrics.',
                    theme: theme,
                  ),
                  SpacingHelper.xxl,
                  _IllustrationFeatureCard(
                    illustration: IllustrationType.community,
                    title: 'Connected Community',
                    description: 'Join a network of parents, schools, and educators sharing experiences.',
                    theme: theme,
                  ),
                  SpacingHelper.xxl,
                  _IllustrationFeatureCard(
                    illustration: IllustrationType.growth,
                    title: 'Continuous Growth',
                    description: 'Track achievements and celebrate milestones in your educational journey.',
                    theme: theme,
                  ),
                ],
              );
            } else {
              return Row(
                children: [
                  Expanded(
                    child: _IllustrationFeatureCard(
                      illustration: IllustrationType.education,
                      title: 'Quality Education',
                      description: 'Access detailed information about curriculum, facilities, and performance metrics.',
                      theme: theme,
                    ),
                  ),
                  SizedBox(width: AppSpacing.xxl),
                  Expanded(
                    child: _IllustrationFeatureCard(
                      illustration: IllustrationType.community,
                      title: 'Connected Community',
                      description: 'Join a network of parents, schools, and educators sharing experiences.',
                      theme: theme,
                    ),
                  ),
                  SizedBox(width: AppSpacing.xxl),
                  Expanded(
                    child: _IllustrationFeatureCard(
                      illustration: IllustrationType.growth,
                      title: 'Continuous Growth',
                      description: 'Track achievements and celebrate milestones in your educational journey.',
                      theme: theme,
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ],
    );
  }
}

class _IllustrationFeatureCard extends StatelessWidget {
  final IllustrationType illustration;
  final String title;
  final String description;
  final ThemeData theme;

  const _IllustrationFeatureCard({
    required this.illustration,
    required this.title,
    required this.description,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          AppIllustration(
            type: illustration,
            size: AppSizing.iconXl * 1.5,
            color: theme.colorScheme.primary,
            showBackground: true,
          ),
          SpacingHelper.lg,
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SpacingHelper.sm,
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
