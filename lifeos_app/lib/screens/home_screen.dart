import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import '../models/dashboard_model.dart';
import '../services/api_service.dart';
import '../widgets/currency_converter_sheet.dart';
import 'finances_screen.dart';
import 'profile_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  late Future<DashboardData> _dashboardData;
  final ValueNotifier<Map<String, dynamic>?> _currencyRatesNotifier = ValueNotifier(null);

  @override
  void initState() {
    super.initState();
    _dashboardData = _apiService.getDashboardData();
    _initializeCurrencyRates();
  }

  Future<void> _initializeCurrencyRates() async {
    // Load persisted rates first
    final persistedData = await _apiService.getPersistedRates();
    if (mounted && persistedData != null) {
      _currencyRatesNotifier.value = persistedData;
    }

    // Then fetch fresh rates
    try {
      final data = await _apiService.getCurrencyRates();
      if (mounted) {
        _currencyRatesNotifier.value = data;
      }
    } catch (e) {
      debugPrint('Error fetching currency rates: $e');
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DashboardData>(
      future: _dashboardData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData) {
          return const Center(child: Text('No data available'));
        }

        final data = snapshot.data!;
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 50.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(data.user),
                const SizedBox(height: 24),
                _buildFinanceSection(data.finance),
                const SizedBox(height: 24),
                _buildFocusSection(data.focus),
                const SizedBox(height: 24),
                _buildHealthSection(data.health),
                const SizedBox(height: 24),
                _buildToolsSection(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(User user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getGreeting(),
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF8E8E93),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 0),
            Text(
              user.name,
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileSettingsScreen()),
            );
          },
          child: FAvatar(
            fallback: const Text('A'),
            image: const NetworkImage('https://i.pravatar.cc/150?img=12'),
          ),
        ),
      ],
    );
  }

  Widget _buildFinanceSection(Finance finance) {
    return FCard(
      title: const Text('Total Assets'),
      subtitle: Text(
        '${finance.currency} ${finance.totalAssets.toStringAsFixed(0)}',
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Color(0xFF007AFF),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: Row(
          children: [
            Expanded(
              child: FButton(
                style: FButtonStyle.primary,
                label: const Text('Wallets'),
                onPress: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FinancesScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FButton(
                style: FButtonStyle.outline,
                label: const Text('Investments'),
                onPress: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFocusSection(List<FocusItem> focusItems) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Today\'s Focus',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: focusItems.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              return SizedBox(
                width: 200,
                child: _buildFocusCard(focusItems[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFocusCard(FocusItem item) {
    if (item.type == 'pomodoro') {
      return FCard(
        title: Text(item.title),
        subtitle: Text('${item.duration} minutes'),
        child: Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: FButton(
            label: const Text('Start Focus'),
            onPress: () {},
            style: FButtonStyle.primary,
          ),
        ),
      );
    }

    return FCard(
      title: Row(
        children: [
          if (item.type == 'reminder')
            const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: Icon(Icons.notifications, size: 16, color: Colors.blue),
            ),
          if (item.type == 'habit')
            const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: Icon(Icons.repeat, size: 16, color: Colors.purple),
            ),
          Text(item.title),
        ],
      ),
      subtitle: item.type == 'habit'
          ? Text('${item.current}/${item.target} ${item.unit}')
          : Text(item.time ?? ''),
      child: item.type == 'reminder' && item.completed == true
          ? const Padding(
              padding: EdgeInsets.only(top: 16.0),
              child: Icon(Icons.check_circle, color: Colors.green),
            )
          : null,
    );
  }

  Widget _buildHealthSection(Health health) {
    final progress = health.caloriesConsumed / health.caloriesTarget;

    return FCard(
      title: const Text('Health'),
      subtitle: Text('${health.caloriesConsumed} / ${health.caloriesTarget} kcal'),
      child: Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Calories'),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.orange.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                minHeight: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tools',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: [
            _buildToolCard('USD <-> INR', FAssets.icons.banknote, Colors.green),
            _buildToolCard('Time', FAssets.icons.clock, Colors.blue),
            _buildToolCard('Speed', FAssets.icons.gauge, Colors.red),
            _buildToolCard('Animal Age', FAssets.icons.pawPrint, Colors.purple),
          ],
        ),
      ],
    );
  }

  void _showToolDetails(String label, SvgAsset icon, Color color) {
    if (label == 'USD <-> INR') {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => CurrencyConverterSheet(ratesNotifier: _currencyRatesNotifier),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutQuint,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, 50 * (1 - value)),
            child: Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: child,
            ),
          );
        },
        child: Container(
          height: MediaQuery.of(context).size.height * 0.55,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 32),
              Hero(
                tag: label,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: FIcon(icon, color: color, size: 48),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Access powerful ${label.toLowerCase()} features to enhance your productivity and workflow.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    Expanded(
                      child: FButton(
                        label: const Text('Cancel'),
                        onPress: () => Navigator.pop(context),
                        style: FButtonStyle.outline,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FButton(
                        label: const Text('Open'),
                        onPress: () => Navigator.pop(context),
                        style: FButtonStyle.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolCard(String label, SvgAsset icon, Color color) {
    return GestureDetector(
      onTap: () => _showToolDetails(label, icon, color),
      child: FCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Hero(
                  tag: label,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: FIcon(icon, color: color, size: 22),
                  ),
                ),
                Icon(
                  Icons.arrow_outward,
                  size: 14,
                  color: Colors.grey[300],
                ),
              ],
            ),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
