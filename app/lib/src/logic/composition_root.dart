import 'package:auth/auth.dart';
import 'package:clock/clock.dart';
import 'package:error_reporter/error_reporter.dart';
import 'package:intercepted_client/intercepted_client.dart';
import 'package:logger/logger.dart';
import 'package:navigator_api/home_navigator.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:rest_client/rest_client.dart';
import 'package:settings_api/settings_api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:take_short/src/model/application_config.dart';
import 'package:take_short/src/model/dependencies_container.dart';
import 'package:take_short/src/navigation/navigators/home_navigator.dart';

/// A place where Application-Wide dependencies are initialized.
///
/// Application-Wide dependencies are dependencies that have a global scope,
/// used in the entire application and have a lifetime that is the same as the application.
/// Composes dependencies and returns the result of composition.
Future<CompositionResult> composeDependencies({
  required ApplicationConfig config,
  required Logger logger,
  required ErrorReporter errorReporter,
}) async {
  final stopwatch = clock.stopwatch()..start();

  logger.info('Initializing dependencies...');

  // Create the dependencies container using functions.
  final dependencies = await createDependenciesContainer(config, logger, errorReporter);

  stopwatch.stop();
  logger.info('Dependencies initialized successfully in ${stopwatch.elapsedMilliseconds} ms.');

  return CompositionResult(
    dependencies: dependencies,
    millisecondsSpent: stopwatch.elapsedMilliseconds,
  );
}

final class CompositionResult {
  const CompositionResult({required this.dependencies, required this.millisecondsSpent});

  final DependenciesContainer dependencies;
  final int millisecondsSpent;

  @override
  String toString() =>
      'CompositionResult('
      'dependencies: $dependencies, '
      'millisecondsSpent: $millisecondsSpent'
      ')';
}

/// Creates the initialized [DependenciesContainer].
Future<DependenciesContainer> createDependenciesContainer(
  ApplicationConfig config,
  Logger logger,
  ErrorReporter errorReporter,
) async {
  // Create or obtain the shared preferences instance.
  final sharedPreferences = SharedPreferencesAsync();

  final clinet = createDefaultHttpClient();

  final storage = TokenStorageSP(sharedPreferences: sharedPreferences);
  final token = await storage.load();

  // Get package info.
  final packageInfo = await PackageInfo.fromPlatform();

  final settingsContainer = await SettingsContainer.create(sharedPreferences);

  final baseUrl = config.baseUrl;

  final authInterceptor = AuthInterceptor(
    tokenStorage: storage,
    authorizationClient: JWTAuthorizationClient(clinet, baseUrl: baseUrl),
    retryClient: clinet,
    token: token,
  );

  final interceptedClient = InterceptedClient(
    inner: clinet,
    interceptors: [authInterceptor],
  );
  final RestClientBase restClient = RestClientHttp(
    baseUrl: config.baseUrl,
    client: interceptedClient,
  );

  final authDataSource = AuthDataSourceNetwork(client: clinet, baseUrl: baseUrl);

  final authRepository = AuthRepositoryImpl(
    dataSource: authDataSource,
    storage: storage,
  );
  final authBloc = AuthBloc(
    AuthState.idle(
      status: token != null
          ? AuthenticationStatus.authenticated
          : AuthenticationStatus.unauthenticated,
    ),
    authRepository: authRepository,
  );
  const HomeNavigator homeNavigator = HomeNavigatorRouter();

  final authDependencies = buildAuthDependencies(authBloc, homeNavigator);

  return DependenciesContainer(
    logger: logger,
    config: config,
    errorReporter: errorReporter,
    packageInfo: packageInfo,
    settingsContainer: settingsContainer,
    authDependencies: authDependencies,
  );
}

/// Creates the [Logger] instance and attaches any provided observers.
Logger createAppLogger({List<LogObserver> observers = const []}) {
  final logger = Logger();

  for (final observer in observers) {
    logger.addObserver(observer);
  }

  return logger;
}

/// Creates the [ErrorReporter] instance and initializes it if needed.
Future<ErrorReporter> createErrorReporter(ApplicationConfig config) async {
  final errorReporter = SentryErrorReporter(
    sentryDsn: config.sentryDsn,
    environment: config.environment.value,
  );

  if (config.sentryDsn.isNotEmpty) {
    await errorReporter.initialize();
  }

  return errorReporter;
}

AuthDependencies buildAuthDependencies(
  AuthBloc authBloc,
  HomeNavigator homeNavigator,
) {
  return AuthDependencies(authBloc: authBloc, homeNavigator: homeNavigator);
}
