import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  // App configuration constants
  static const String _appName = 'SortCycle';
  static const String _appTagline =
      'Waste Classification & Environmental Awareness';
  static const String _appVersion = '1.0.0';
  static const String _copyrightYear = '2025';
  static const String _teamName = 'SortCycle Team';

  // Content data
  static const String _appDescription =
      'SortCycle is an intelligent waste classification app that helps users sort waste into six categories: plastic, metal, glass, cardboard, paper, and trash. The app uses machine learning to identify waste items and provide helpful information about how to recycle them properly.';

  static const String _missionStatement =
      'SortCycle aims to raise environmental awareness and promote responsible waste disposal through technology. Every correct classification and recycling action helps build a cleaner and more sustainable future.';

  static const List<String> _features = [
    'Classify waste instantly using your camera or gallery.',
    'Receive tailored recycling tips.',
    'Understand the environmental impact of each item.',
    'Request and track pickups from local collectors.',
    'View stats about your recycling activity.',
  ];

  // Theme constants
  static const double _iconSize = 80.0;
  static const double _standardSpacing = 16.0;
  static const double _largeSpacing = 24.0;
  static const double _smallSpacing = 8.0;
  static const double _tinySpacing = 4.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = Colors.green.shade700;

    return Scaffold(
      appBar: _buildAppBar(primaryColor),
      body: _buildBody(theme, primaryColor),
    );
  }

  PreferredSizeWidget _buildAppBar(Color primaryColor) {
    return AppBar(
      title: const Text('About $_appName'),
      backgroundColor: primaryColor,
      elevation: 2,
      foregroundColor: Colors.white,
    );
  }

  Widget _buildBody(ThemeData theme, Color primaryColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(_standardSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAppHeader(theme, primaryColor),
          const SizedBox(height: _largeSpacing),
          _buildSection(
            title: 'What is $_appName?',
            content: const _AppDescriptionWidget(description: _appDescription),
            theme: theme,
          ),
          const SizedBox(height: _standardSpacing),
          _buildSection(
            title: 'Features:',
            content: const _FeaturesList(features: _features),
            theme: theme,
          ),
          const SizedBox(height: _standardSpacing),
          _buildSection(
            title: 'Our Mission',
            content: const _AppDescriptionWidget(
              description: _missionStatement,
            ),
            theme: theme,
          ),
          const SizedBox(height: _largeSpacing),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildAppHeader(ThemeData theme, Color primaryColor) {
    return _AppHeaderWidget(
      appName: _appName,
      tagline: _appTagline,
      primaryColor: primaryColor,
      theme: theme,
    );
  }

  Widget _buildSection({
    required String title,
    required Widget content,
    required ThemeData theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: title, theme: theme),
        const SizedBox(height: _smallSpacing),
        content,
      ],
    );
  }

  Widget _buildFooter() {
    return const _AppFooterWidget(
      version: _appVersion,
      copyrightYear: _copyrightYear,
      teamName: _teamName,
    );
  }
}

// Extracted widget for app header
class _AppHeaderWidget extends StatelessWidget {
  final String appName;
  final String tagline;
  final Color primaryColor;
  final ThemeData theme;

  const _AppHeaderWidget({
    required this.appName,
    required this.tagline,
    required this.primaryColor,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Icon(Icons.recycling, size: AboutPage._iconSize, color: primaryColor),
          const SizedBox(height: 12),
          Text(
            appName,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: AboutPage._tinySpacing),
          Text(
            tagline,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

// Extracted widget for section titles
class _SectionTitle extends StatelessWidget {
  final String title;
  final ThemeData theme;

  const _SectionTitle({required this.title, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: Colors.grey[800],
      ),
    );
  }
}

// Extracted widget for app description
class _AppDescriptionWidget extends StatelessWidget {
  final String description;

  const _AppDescriptionWidget({required this.description});

  @override
  Widget build(BuildContext context) {
    return Text(
      description,
      style: Theme.of(
        context,
      ).textTheme.bodyLarge?.copyWith(height: 1.5, color: Colors.grey[700]),
    );
  }
}

// Extracted widget for features list
class _FeaturesList extends StatelessWidget {
  final List<String> features;

  const _FeaturesList({required this.features});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: features.map((feature) => BulletPoint(text: feature)).toList(),
    );
  }
}

// Extracted widget for app footer
class _AppFooterWidget extends StatelessWidget {
  final String version;
  final String copyrightYear;
  final String teamName;

  const _AppFooterWidget({
    required this.version,
    required this.copyrightYear,
    required this.teamName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final footerStyle = theme.textTheme.bodyMedium?.copyWith(
      color: Colors.grey[600],
    );

    return Column(
      children: [
        Text(
          'Version $version',
          textAlign: TextAlign.center,
          style: footerStyle,
        ),
        const SizedBox(height: AboutPage._smallSpacing),
        Text(
          '© $copyrightYear $teamName',
          textAlign: TextAlign.center,
          style: footerStyle,
        ),
      ],
    );
  }
}

// Improved BulletPoint widget
class BulletPoint extends StatelessWidget {
  final String text;
  final Color? bulletColor;
  final double bulletSize;
  final double spacing;

  const BulletPoint({
    super.key,
    required this.text,
    this.bulletColor,
    this.bulletSize = 16.0,
    this.spacing = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBulletColor = bulletColor ?? Colors.green.shade700;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: spacing),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6, right: 8),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: effectiveBulletColor,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.4,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
