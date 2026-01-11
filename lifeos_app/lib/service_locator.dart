import 'services/offline/local_database_service.dart';
import 'services/offline/outbox_service.dart';
import 'services/offline/sync_engine.dart';
import 'services/offline/connectivity_service.dart';
import 'services/offline/dashboard_service.dart';
import 'repositories/account_repository.dart';
import 'repositories/transaction_repository.dart';
import 'repositories/budget_repository.dart';
import 'repositories/goal_repository.dart';
import 'repositories/event_repository.dart';
import 'repositories/category_repository.dart';

/// Service locator for dependency injection
/// 
/// Provides access to all services and repositories in the app.
/// This implements a simple service locator pattern for managing
/// dependencies without external packages.
class ServiceLocator {
  static ServiceLocator? _instance;
  static ServiceLocator get instance {
    _instance ??= ServiceLocator._();
    return _instance!;
  }

  ServiceLocator._();

  // Services
  late final LocalDatabaseService _database;
  late final OutboxService _outbox;
  late final ConnectivityService _connectivity;
  late final SyncEngine _syncEngine;

  // Repositories
  late final AccountRepository _accountRepository;
  late final TransactionRepository _transactionRepository;
  late final BudgetRepository _budgetRepository;
  late final GoalRepository _goalRepository;
  late final EventRepository _eventRepository;
  late final CategoryRepository _categoryRepository;
  
  // Services (non-core)
  late final LocalDashboardService _dashboardService;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// Base URL for API (can be overridden)
  String _baseUrl = 'http://169.254.13.210:3000';
  String get baseUrl => _baseUrl;
  set baseUrl(String value) => _baseUrl = value;

  /// Initialize all services and repositories
  Future<void> initialize({String? apiBaseUrl}) async {
    if (_initialized) return;

    if (apiBaseUrl != null) {
      _baseUrl = apiBaseUrl;
    }

    // Initialize services in order
    _database = LocalDatabaseService.instance;
    await _database.database; // Ensure database is created

    _connectivity = ConnectivityService();
    await _connectivity.initialize();

    _outbox = OutboxService(_database);

    _syncEngine = SyncEngine(
      db: _database,
      outbox: _outbox,
      connectivity: _connectivity,
      baseUrl: _baseUrl,
    );

    // Initialize repositories
    _accountRepository = AccountRepository(
      db: _database,
      outbox: _outbox,
      syncEngine: _syncEngine,
    );

    _transactionRepository = TransactionRepository(
      db: _database,
      outbox: _outbox,
      syncEngine: _syncEngine,
    );

    _budgetRepository = BudgetRepository(
      db: _database,
      outbox: _outbox,
      syncEngine: _syncEngine,
    );

    _goalRepository = GoalRepository(
      db: _database,
      outbox: _outbox,
      syncEngine: _syncEngine,
    );

    _eventRepository = EventRepository(
      db: _database,
      outbox: _outbox,
      syncEngine: _syncEngine,
    );

    _categoryRepository = CategoryRepository(
      db: _database,
      outbox: _outbox,
      syncEngine: _syncEngine,
    );

    // Initialize non-core services
    _dashboardService = LocalDashboardService(this);

    // Start sync engine
    await _syncEngine.initialize();

    _initialized = true;
  }

  /// Get services
  LocalDatabaseService get database {
    _assertInitialized();
    return _database;
  }

  OutboxService get outbox {
    _assertInitialized();
    return _outbox;
  }

  ConnectivityService get connectivity {
    _assertInitialized();
    return _connectivity;
  }

  SyncEngine get syncEngine {
    _assertInitialized();
    return _syncEngine;
  }

  /// Get repositories
  AccountRepository get accounts {
    _assertInitialized();
    return _accountRepository;
  }

  TransactionRepository get transactions {
    _assertInitialized();
    return _transactionRepository;
  }

  BudgetRepository get budgets {
    _assertInitialized();
    return _budgetRepository;
  }

  GoalRepository get goals {
    _assertInitialized();
    return _goalRepository;
  }

  EventRepository get events {
    _assertInitialized();
    return _eventRepository;
  }

  CategoryRepository get categories {
    _assertInitialized();
    return _categoryRepository;
  }

  LocalDashboardService get dashboard {
    _assertInitialized();
    return _dashboardService;
  }

  void _assertInitialized() {
    if (!_initialized) {
      throw StateError(
        'ServiceLocator not initialized. Call initialize() first.',
      );
    }
  }

  /// Dispose all resources
  Future<void> dispose() async {
    if (!_initialized) return;

    _syncEngine.dispose();
    _connectivity.dispose();
    _accountRepository.dispose();
    _transactionRepository.dispose();
    _budgetRepository.dispose();
    _goalRepository.dispose();
    _eventRepository.dispose();
    _categoryRepository.dispose();
    await _database.close();

    _initialized = false;
  }

  /// Reset for testing
  Future<void> reset() async {
    await dispose();
    _instance = null;
  }
}

/// Convenience getter for service locator
ServiceLocator get locator => ServiceLocator.instance;
