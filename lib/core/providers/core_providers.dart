import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';

/// Shared, application-wide providers live here.
///
/// Feature providers should depend on these rather than constructing their own
/// clients, which keeps a single [ApiClient] (and its Dio instance) alive for
/// the whole session.

/// The singleton HTTP client used by every feature data source.
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});
