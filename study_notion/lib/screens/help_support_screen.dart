import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({Key? key}) : super(key: key);

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final List<FAQItem> _faqItems = [
    FAQItem(
      question: 'How are course recommendations generated?',
      answer: 'Course recommendations are generated using machine learning algorithms based on your selected interests, learning history, and the patterns of similar users. We analyze various factors including course ratings, content, and popularity to suggest the most relevant courses for you.',
    ),
    FAQItem(
      question: 'Can I change my course preferences?',
      answer: 'Yes, you can update your learning preferences at any time by going to Settings > Learning Preferences. Changes to your preferences will affect future recommendations to better match your interests.',
    ),
    FAQItem(
      question: 'How do I save courses for later?',
      answer: 'To save a course for later, tap on the bookmark icon on the course card or course details page. You can view all your saved courses in the Favorites tab of the app.',
    ),
    FAQItem(
      question: 'Is my personal data secure?',
      answer: 'Yes, we take data security very seriously. We implement industry-standard security measures to protect your personal information. You can review and adjust your privacy settings at any time in the Privacy section of the Settings menu.',
    ),
    FAQItem(
      question: 'How do I report a bug or suggest a feature?',
      answer: 'You can report bugs or suggest features by using the "Report an Issue" or "Suggest a Feature" options at the bottom of this screen. Alternatively, you can contact our support team directly at support@studynotion.com.',
    ),
    FAQItem(
      question: 'How do I delete my account?',
      answer: 'You can delete your account by going to Settings > Account Settings > Delete Account. Please note that this action is irreversible and will permanently remove all your data from our systems.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Help & Support',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        elevation: 0,
        backgroundColor: const Color(0xFF17252A),
      ),
      body: ListView(
        children: [
          _buildHeader(),
          _buildContactSection(),
          _buildFAQSection(),
          _buildActionButtons(),
          _buildSupportInfo(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF17252A),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.support_agent_rounded,
            size: 64,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          const Text(
            'How can we help you?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Find answers to common questions or contact our support team',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search for help topics...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              prefixIcon: Icon(
                Icons.search,
                color: Colors.white.withOpacity(0.7),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(50),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
            style: const TextStyle(color: Colors.white),
            onSubmitted: (query) {
              // Filter FAQs or search help articles
              // This would be implemented with a more complete help system
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Searching for: $query'),
                  backgroundColor: const Color(0xFF3AAFA9),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact Us',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF17252A),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildContactCard(
                  icon: Icons.email_outlined,
                  title: 'Email Support',
                  description: 'Get help via email',
                  onTap: () => _launchEmail(),
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildContactCard(
                  icon: Icons.chat_outlined,
                  title: 'Live Chat',
                  description: 'Chat with support',
                  onTap: () => _showLiveChatDialog(),
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: color,
              size: 28,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Frequently Asked Questions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF17252A),
            ),
          ),
          const SizedBox(height: 16),
          ..._faqItems.map((item) => _buildFAQItem(item)).toList(),
        ],
      ),
    );
  }

  Widget _buildFAQItem(FAQItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
        ),
      ),
      child: ExpansionTile(
        title: Text(
          item.question,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Color(0xFF17252A),
          ),
        ),
        iconColor: const Color(0xFF3AAFA9),
        collapsedIconColor: Colors.grey,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.answer,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildActionButton(
            icon: Icons.bug_report_outlined,
            title: 'Report an Issue',
            onTap: () => _showReportIssueDialog(),
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          _buildActionButton(
            icon: Icons.lightbulb_outline,
            title: 'Suggest a Feature',
            onTap: () => _showSuggestFeatureDialog(),
            color: Colors.amber,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color.withOpacity(0.9),
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              color: color.withOpacity(0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Divider(height: 40),
          const Text(
            'StudyNotion Support',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF17252A),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Available Monday to Friday\n9:00 AM - 6:00 PM (EST)',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSocialButton(Icons.language, () => _launchWebsite()),
              const SizedBox(width: 16),
              _buildSocialButton(Icons.facebook, () => _launchSocial('facebook')),
              const SizedBox(width: 16),
              _buildSocialButton(Icons.android, () => _launchSocial('twitter')),
              const SizedBox(width: 16),
              _buildSocialButton(Icons.camera_alt_outlined, () => _launchSocial('instagram')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF3AAFA9).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: const Color(0xFF3AAFA9),
          size: 24,
        ),
      ),
    );
  }

  void _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@studynotion.com',
      queryParameters: {
        'subject': 'StudyNotion Support Request',
        'body': 'Hello StudyNotion Support,\n\n',
      },
    );
    
    try {
      await launchUrl(emailUri);
    } catch (e) {
      _showErrorDialog('Could not launch email client. Please send an email to support@studynotion.com');
    }
  }

  void _launchWebsite() async {
    final Uri websiteUri = Uri.parse('https://www.studynotion.com');
    
    try {
      await launchUrl(websiteUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      _showErrorDialog('Could not open website. Please visit https://www.studynotion.com');
    }
  }

  void _launchSocial(String platform) {
    final Map<String, String> socialUrls = {
      'facebook': 'https://www.facebook.com/studynotion',
      'twitter': 'https://www.twitter.com/studynotion',
      'instagram': 'https://www.instagram.com/studynotion',
    };
    
    final url = socialUrls[platform];
    if (url != null) {
      _showComingSoonDialog('Social media links will be available soon!');
    }
  }

  void _showLiveChatDialog() {
    _showComingSoonDialog('Live chat support will be available soon!');
  }

  void _showReportIssueDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report an Issue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Issue Title',
                hintText: 'Briefly describe the issue',
              ),
              maxLength: 100,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Provide details about the issue',
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              maxLength: 500,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Thank you for reporting the issue!'),
                  backgroundColor: Color(0xFF3AAFA9),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3AAFA9),
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showSuggestFeatureDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suggest a Feature'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Feature Title',
                hintText: 'Briefly describe your feature idea',
              ),
              maxLength: 100,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Explain how this feature would be useful',
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              maxLength: 500,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Thank you for your feature suggestion!'),
                  backgroundColor: Color(0xFF3AAFA9),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3AAFA9),
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Coming Soon'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem({
    required this.question,
    required this.answer,
  });
} 