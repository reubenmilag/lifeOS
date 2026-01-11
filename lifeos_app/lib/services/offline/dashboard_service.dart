import 'package:lifeos_app/models/dashboard_model.dart';
import 'package:lifeos_app/service_locator.dart';

/// Service for computing dashboard data locally from repositories
class LocalDashboardService {
  final ServiceLocator _locator;

  LocalDashboardService(this._locator);

  /// Computes dashboard data from local repositories
  Future<DashboardData> getDashboardData() async {
    final accounts = await _locator.accounts.getAll();
    final transactions = await _locator.transactions.getAll();
    final goals = await _locator.goals.getAll();
    final events = await _locator.events.getAll();

    // Calculate total assets from accounts
    double totalAssets = 0.0;
    for (final account in accounts) {
      totalAssets += account.balance ?? 0.0;
    }

    // Calculate daily change from today's transactions
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayTransactions = transactions.where((t) {
      return t.date.isAfter(todayStart) || 
             (t.date.year == todayStart.year && 
              t.date.month == todayStart.month && 
              t.date.day == todayStart.day);
    }).toList();

    double dailyChange = 0.0;
    for (final t in todayTransactions) {
      if (t.type == 'income') {
        dailyChange += t.amount;
      } else if (t.type == 'expense') {
        dailyChange -= t.amount;
      }
    }

    // Build focus items from today's events
    final todayEvents = events.where((e) {
      final eventDate = e.startTime;
      return eventDate.year == now.year && 
             eventDate.month == now.month && 
             eventDate.day == now.day;
    }).toList();

    final focusItems = <FocusItem>[];
    
    for (final e in todayEvents) {
      focusItems.add(FocusItem(
        type: 'event',
        title: e.title,
        time: '${e.startTime.hour}:${e.startTime.minute.toString().padLeft(2, '0')}',
        completed: false,
      ));
    }

    // Add active goals as focus items (goals with progress < 100%)
    final activeGoals = goals.where((g) => g.progress < 1.0).take(3);
    for (final goal in activeGoals) {
      focusItems.add(FocusItem(
        type: 'goal',
        title: goal.name,
        current: goal.saved.toInt(),
        target: goal.target.toInt(),
        unit: 'INR',
      ));
    }

    return DashboardData(
      user: User(name: 'User', greeting: _getGreeting()),
      finance: Finance(
        totalAssets: totalAssets,
        currency: 'INR', // Default currency
        dailyChange: dailyChange,
      ),
      focus: focusItems,
      health: Health(
        caloriesConsumed: 0,
        caloriesTarget: 2000,
      ),
    );
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
}
