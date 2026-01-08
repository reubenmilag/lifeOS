import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  final List<_SectionData> _sections = const [
    _SectionData(
      title: 'Calculators',
      items: [
        _ItemData(icon: Icons.calculate_outlined, title: 'SIP', route: '/sip-calc'),
        _ItemData(icon: Icons.account_balance_outlined, title: 'Loan', route: '/loan-calc'),
        _ItemData(icon: Icons.pie_chart_outline, title: 'EMI', route: '/emi-calc'),
        _ItemData(icon: Icons.beach_access_outlined, title: 'Retirement', route: '/retirement-calc'),
        _ItemData(icon: Icons.receipt_long_outlined, title: 'Tax', route: '/tax-calc'),
        _ItemData(icon: Icons.trending_up, title: 'Inflation', route: '/inflation-calc'),
      ],
    ),
    _SectionData(
      title: 'Life',
      items: [
        _ItemData(icon: Icons.account_balance_wallet_outlined, title: 'Expenses', route: '/expenses'),
        _ItemData(icon: Icons.flag_outlined, title: 'Goals', route: '/goals'),
        _ItemData(icon: Icons.savings_outlined, title: 'Savings', route: '/savings'),
        _ItemData(icon: Icons.currency_exchange, title: 'Net Worth', route: '/net-worth'),
        _ItemData(icon: Icons.add_moderator_outlined, title: 'Habits', route: '/habits'),
      ],
    ),
    _SectionData(
      title: 'Health',
      items: [
        _ItemData(icon: Icons.monitor_weight_outlined, title: 'BMI', route: '/bmi'),
        _ItemData(icon: Icons.local_fire_department_outlined, title: 'Calories', route: '/calories'),
        _ItemData(icon: Icons.water_drop_outlined, title: 'Water', route: '/water'),
        _ItemData(icon: Icons.directions_walk, title: 'Steps', route: '/steps'),
      ],
    ),
    _SectionData(
      title: 'Insights & Tools',
      items: [
        _ItemData(icon: Icons.insights, title: 'Market', route: '/market'),
        _ItemData(icon: Icons.newspaper_outlined, title: 'News', route: '/news'),
        _ItemData(icon: Icons.security_outlined, title: 'Risk Profile', route: '/risk-profile'),
        _ItemData(icon: Icons.school_outlined, title: 'Education', route: '/education'),
      ],
    ),
    _SectionData(
      title: 'Settings & Support',
      items: [
        _ItemData(icon: Icons.person_outline, title: 'Profile', route: '/profile'),
        _ItemData(icon: Icons.notifications_none_outlined, title: 'Notifications', route: '/notifications'),
        _ItemData(icon: Icons.privacy_tip_outlined, title: 'Privacy', route: '/privacy'),
        _ItemData(icon: Icons.help_outline, title: 'Help', route: '/help'),
        _ItemData(icon: Icons.info_outline, title: 'About', route: '/about'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Using Scaffold to match other screens, with white background for clean enterprise look
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _sections.map((section) => _SectionWidget(section: section)).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          const Text(
            'More',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          // Placeholder for search or other action if needed
          // FIcon(FAssets.icons.search, size: 20),
        ],
      ),
    );
  }
}

class _SectionWidget extends StatelessWidget {
  final _SectionData section;

  const _SectionWidget({required this.section});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Text(
            section.title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12, // Reduced spacing
            childAspectRatio: 0.85, // Taller for icon + vertical text
          ),
          itemCount: section.items.length,
          itemBuilder: (context, index) {
            return _CardWidget(item: section.items[index]);
          },
        ),
      ],
    );
  }
}

class _CardWidget extends StatelessWidget {
  final _ItemData item;

  const _CardWidget({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Material(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          // Subtle elevation for enterprise feel
          elevation: 0, 
          // Use border instead of high elevation for cleaner look
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200, 
                width: 1
              )
          ),
          child: InkWell(
            onTap: () {
              // Navigation stub
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => _PlaceholderScreen(title: item.title)),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item.icon, 
                    size: 22, 
                    color: isDark ? Colors.white70 : Colors.blueGrey.shade800
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    item.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11, // Small, compact text
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('Placeholder for $title')),
    );
  }
}

class _SectionData {
  final String title;
  final List<_ItemData> items;
  const _SectionData({required this.title, required this.items});
}

class _ItemData {
  final IconData icon;
  final String title;
  final String route;
  const _ItemData({required this.icon, required this.title, required this.route});
}
