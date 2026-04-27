import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import 'api_interceptor.dart';
import 'dio_client.dart';

/// Singleton secure storage shared across providers.
final _secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

/// Provides the configured [ApiInterceptor] (reads token from storage).
/// The "session expired" callback is wired AFTER construction in main.dart
/// to avoid a Riverpod dependency cycle (auth provider depends on the
/// repository which depends on this interceptor).
final apiInterceptorProvider = Provider<ApiInterceptor>((ref) {
  final storage = ref.watch(_secureStorageProvider);
  return ApiInterceptor(storage: storage);
});

/// Provides the singleton [DioClient] wired with the [ApiInterceptor].
final dioClientProvider = Provider<DioClient>((ref) {
  final interceptor = ref.watch(apiInterceptorProvider);
  return DioClient(apiInterceptor: interceptor);
});

/// Provides the [AuthRemoteDatasource] backed by the [DioClient].
final authRemoteDatasourceProvider = Provider<AuthRemoteDatasource>((ref) {
  final client = ref.watch(dioClientProvider);
  return AuthRemoteDatasource(client: client);
});

/// Provides the [AuthRepository] wired with datasource + storage + interceptor.
/// The interceptor reference lets the repo push the in-memory refresh token
/// into the interceptor so silent refresh works for rememberMe=false sessions.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final datasource = ref.watch(authRemoteDatasourceProvider);
  final storage = ref.watch(_secureStorageProvider);
  final interceptor = ref.watch(apiInterceptorProvider);
  return AuthRepository(
    datasource: datasource,
    storage: storage,
    interceptor: interceptor,
  );
});
