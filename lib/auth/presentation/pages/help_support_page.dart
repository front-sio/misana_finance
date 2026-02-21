import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:misana_finance_app/core/i18n/locale_cubit.dart';
import 'package:misana_finance_app/core/theme/app_theme.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );
    _tabController = TabController(length: 3, vsync: this);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  String _t(String key) {
    final isSw = context.watch<LocaleCubit>().state.languageCode == 'sw';
    final translations = {
      'title': isSw ? 'Usaidizi na Msaada' : 'Help & Support',
      'subtitle': isSw ? 'Pata majibu ya maswali yako na msaada wa haraka' : 'Get answers to your questions and quick help',
      'faq': isSw ? 'Maswali Yanayoulizwa Sana' : 'Frequently Asked Questions',
      'contact': isSw ? 'Wasiliana Nasi' : 'Contact Us',
      'guides': isSw ? 'Mwongozo na Mafunzo' : 'Guides & Tutorials',
      
      // FAQ Items
      'faq1_q': isSw ? 'Ninawezaje kuunda akaunti?' : 'How do I create an account?',
      'faq1_a': isSw ? 'Bonyeza kitufe cha \'Fungua Akaunti\', jaza maelezo yako, na fuata hatua za uthibitisho.' : 'Click the \'Create Account\' button, fill in your details, and follow the verification steps.',
      'faq2_q': isSw ? 'Ninawezaje kuweka akiba?' : 'How do I make a deposit?',
      'faq2_a': isSw ? 'Nenda kwenye ukurasa wa \'Depositi\', chagua kiasi, na uweke kwa kutumia njia za malipo zilizopendekezwwa.' : 'Go to the \'Deposit\' page, select an amount, and pay using the available payment methods.',
      'faq3_q': isSw ? 'Lengo la mpango wa akiba ni nini?' : 'What is a savings plan goal?',
      'faq3_a': isSw ? 'Ni kiasi unachotaka kufikia ndani ya muda maalum kwa ajili ya lengo lako la kifedha.' : 'It\'s the amount you want to reach within a specific timeframe for your financial goal.',
      'faq4_q': isSw ? 'Ninawezaje kutoa pesa yangu?' : 'How do I withdraw my money?',
      'faq4_a': isSw ? 'Nenda kwenye ukurasa wa \'Matumizi\', chango akaunti yako, na uweke ombi lako la kutoa.' : 'Go to the \'Withdraw\' page, select your account, and submit your withdrawal request.',
      'faq5_q': isSw ? 'Je, ninaweza kubadili mpango wangu wa akiba?' : 'Can I change my savings plan?',
      'faq5_a': isSw ? 'Ndio, unaweza kubadili mpango wako ndani ya saa 24 baada ya kuunda.' : 'Yes, you can modify your plan within 24 hours of creation.',
      
      // Contact
      'email_support': isSw ? 'Barua pepe ya Msaada' : 'Support Email',
      'phone_support': isSw ? 'Simu ya Msaada' : 'Support Phone',
      'whatsapp_support': isSw ? 'WhatsApp Support' : 'WhatsApp Support',
      'office_hours': isSw ? 'Masaa ya Ofisi' : 'Office Hours',
      'response_time': isSw ? 'Muda wa Majibu' : 'Response Time',
      'send_message': isSw ? 'Tuma Ujumbe' : 'Send Message',
      'your_message': isSw ? 'Ujumbe Wako' : 'Your Message',
      'subject': isSw ? 'Mada' : 'Subject',
      'type_subject': isSw ? 'Andika mada ya ujumbe wako' : 'Type the subject of your message',
      'type_message': isSw ? 'Andika ujumbe wako hapa' : 'Type your message here',
      'message_sent': isSw ? 'Ujumbe umetumwa! Tutakujibu haraka iwezekanavyo.' : 'Message sent! We\'ll respond as soon as possible.',
      
      // Guides
      'getting_started': isSw ? 'Anza Kutumia' : 'Getting Started',
      'getting_started_desc': isSw ? 'Jifunze jinsi ya kuunda akaunti na kuanza kuweka akiba' : 'Learn how to create an account and start saving',
      'creating_plans': isSw ? 'Kuunda Mipango' : 'Creating Plans',
      'creating_plans_desc': isSw ? 'Jifunze jinsi ya kuunda mipango ya akiba yenye ufanisi' : 'Learn how to create effective savings plans',
      'making_deposits': isSw ? 'Kuweka Akiba' : 'Making Deposits',
      'making_deposits_desc': isSw ? 'Njia tofauti za kuweka pesa kwenye akaunti yako' : 'Different ways to add money to your account',
      'withdrawal_guide': isSw ? 'Jinsi ya Kutoa' : 'Withdrawal Guide',
      'withdrawal_desc': isSw ? 'Jifunze mchakato wa kutoa pesa na nyakati za malipo' : 'Learn the withdrawal process and payment timelines',
      'security_tips': isSw ? 'Mashauri ya Usalama' : 'Security Tips',
      'security_desc': isSw ? 'Dumisha akaunti yako salama na mbinu bora za usalama' : 'Keep your account safe with best security practices',
      
      // Common
      'learn_more': isSw ? 'Jifunze Zaidi' : 'Learn More',
      'view_all': isSw ? 'Ona Zote' : 'View All',
      'contact_info': isSw ? 'Maelezo ya Wasiliana' : 'Contact Information',
      'mon_fri': isSw ? 'Jumatatu - Ijumaa' : 'Monday - Friday',
      'sat_sun': isSw ? 'Jumamosi - Jumapili' : 'Saturday - Sunday',
      'hours_8_6': isSw ? '8:00 AM - 6:00 PM' : '8:00 AM - 6:00 PM',
      'hours_9_1': isSw ? '9:00 AM - 1:00 PM' : '9:00 AM - 1:00 PM',
      'within_24h': isSw ? 'Ndani ya masaa 24' : 'Within 24 hours',
      'within_48h': isSw ? 'Ndani ya masaa 48' : 'Within 48 hours',
    };
    return translations[key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_t('title')),
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: scheme.scrim.withValues(alpha: 0.1),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: _t('faq')),
            Tab(text: _t('contact')),
            Tab(text: _t('guides')),
          ],
          indicatorColor: BrandColors.orange,
          labelColor: BrandColors.orange,
          unselectedLabelColor: scheme.onSurfaceVariant,
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildFAQTab(),
            _buildContactTab(),
            _buildGuidesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subtitle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: BrandColors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: BrandColors.orange.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.help_rounded, color: BrandColors.orange, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _t('subtitle'),
                    style: TextStyle(
                      color: BrandColors.orange,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // FAQ Items
          _buildFAQItem(
            question: _t('faq1_q'),
            answer: _t('faq1_a'),
          ),
          const SizedBox(height: 16),
          _buildFAQItem(
            question: _t('faq2_q'),
            answer: _t('faq2_a'),
          ),
          const SizedBox(height: 16),
          _buildFAQItem(
            question: _t('faq3_q'),
            answer: _t('faq3_a'),
          ),
          const SizedBox(height: 16),
          _buildFAQItem(
            question: _t('faq4_q'),
            answer: _t('faq4_a'),
          ),
          const SizedBox(height: 16),
          _buildFAQItem(
            question: _t('faq5_q'),
            answer: _t('faq5_a'),
          ),
          const SizedBox(height: 24),

          // View All Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: Navigate to full FAQ page
              },
              icon: const Icon(Icons.article_rounded),
              label: Text(_t('view_all')),
              style: OutlinedButton.styleFrom(
                foregroundColor: BrandColors.orange,
                side: BorderSide(color: BrandColors.orange),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTab() {
    final _subjectController = TextEditingController();
    final _messageController = TextEditingController();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Contact Information
          _buildContactInfo(),
          const SizedBox(height: 24),

          // Contact Form
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t('send_message'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _subjectController,
                    decoration: InputDecoration(
                      labelText: _t('subject'),
                      hintText: _t('type_subject'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _messageController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: _t('your_message'),
                      hintText: _t('type_message'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implement message sending
                        _showMessageSent();
                      },
                      icon: const Icon(Icons.send_rounded),
                      label: Text(_t('send_message')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BrandColors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidesTab() {
              final guides = [
      {
        'title': _t('getting_started'),
        'description': _t('getting_started_desc'),
        'icon': Icons.rocket_launch_rounded,
      },
      {
        'title': _t('creating_plans'),
        'description': _t('creating_plans_desc'),
        'icon': Icons.savings_rounded,
      },
      {
        'title': _t('making_deposits'),
        'description': _t('making_deposits_desc'),
        'icon': Icons.account_balance_wallet_rounded,
      },
      {
        'title': _t('withdrawal_guide'),
        'description': _t('withdrawal_desc'),
        'icon': Icons.money_off_rounded,
      },
      {
        'title': _t('security_tips'),
        'description': _t('security_desc'),
        'icon': Icons.security_rounded,
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Guides Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
            ),
            itemCount: guides.length,
            itemBuilder: (context, index) {
              final guide = guides[index];
              return _buildGuideCard(
                title: guide['title']! as String,
                description: guide['description']! as String,
                icon: guide['icon'] as IconData,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem({required String question, required String answer}) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ExpansionTile(
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: BrandColors.orange.withValues(alpha: 0.1),
          child: Icon(
            Icons.question_answer_rounded,
            color: BrandColors.orange,
            size: 22,
          ),
        ),
        title: Text(
          question,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              answer,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _t('contact_info'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildContactItem(
              icon: Icons.email_rounded,
              title: _t('email_support'),
              value: 'support@misana.co.tz',
            ),
            const SizedBox(height: 12),
            
            _buildContactItem(
              icon: Icons.phone_rounded,
              title: _t('phone_support'),
              value: '+255 712 345 678',
            ),
            const SizedBox(height: 12),
            
            _buildContactItem(
              icon: Icons.message_rounded,
              title: _t('whatsapp_support'),
              value: '+255 712 345 678',
            ),
            const SizedBox(height: 16),
            
            Divider(color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            
            _buildContactItem(
              icon: Icons.schedule_rounded,
              title: _t('office_hours'),
              value: '${_t('mon_fri')}: ${_t('hours_8_6')}',
            ),
            const SizedBox(height: 8),
            
            _buildContactItem(
              icon: Icons.schedule_rounded,
              title: '',
              value: '${_t('sat_sun')}: ${_t('hours_9_1')}',
            ),
            const SizedBox(height: 12),
            
            _buildContactItem(
              icon: Icons.timelapse_rounded,
              title: _t('response_time'),
              value: _t('within_24h'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: BrandColors.orange.withValues(alpha: 0.1),
          child: Icon(
            icon,
            color: BrandColors.orange,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title.isNotEmpty) ...[
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
              ],
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGuideCard({
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to guide detail page
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: BrandColors.orange.withValues(alpha: 0.1),
                child: Icon(
                  icon,
                  color: BrandColors.orange,
                  size: 22,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  _t('learn_more'),
                  style: TextStyle(
                    color: BrandColors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessageSent() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _t('message_sent'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
