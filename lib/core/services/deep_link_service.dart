import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';

/// Wires Android App Links + iOS Universal Links into the GoRouter stack.
///
/// When the OS hands us a `https://www.termini-im.com/...` URI — either at
/// cold start (app not running before the tap) or during a hot session — we
/// strip the host and forward the path/query to the same router the in-app
/// navigation uses. The result: a salon link clicked in WhatsApp opens the
/// company detail page directly, with the same state, transitions and shell
/// that the user would get from the search tab.
///
/// On web this service is a no-op. GoRouter's path strategy already reads
/// the browser URL on first paint and reacts to popstate, so installing a
/// second listener would only cause double-routing.
class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();

  /// Hosts that we own. A link is consumed only when its host matches one
  /// of these — anything else is ignored so deep links forwarded to other
  /// apps (e.g. social OAuth callbacks) don't get hijacked.
  static const _trustedHosts = {
    'www.termini-im.com',
    'termini-im.com',
  };

  AppLinks? _appLinks;
  StreamSubscription<Uri>? _subscription;

  /// Initialise the listener. [router] must already be built — we read it
  /// directly each time a link arrives so a router rebuild (locale change)
  /// doesn't leave us holding a stale reference.
  Future<void> init(GoRouter Function() routerBuilder) async {
    if (kIsWeb) return;

    _appLinks = AppLinks();

    // Cold start — the URI that launched the app, if any.
    try {
      final initial = await _appLinks!.getInitialLink();
      if (initial != null) {
        _handle(initial, routerBuilder);
      }
    } catch (_) {
      // Plugin not registered (older platform versions, missing intent-
      // filter on a fresh install, etc.) — silent fallback to no-op.
    }

    // Warm start — links that arrive while the app is already running.
    _subscription = _appLinks!.uriLinkStream.listen(
      (uri) => _handle(uri, routerBuilder),
      onError: (_) {},
    );
  }

  /// Dispose the listener. Useful in tests; the singleton lives for the app
  /// lifetime in normal usage.
  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _appLinks = null;
  }

  /// Convert an incoming web URI into an in-app GoRouter navigation.
  ///
  /// Whitelisted paths:
  ///   /company/{id}                       → detail
  ///   /company/{id}?employee={eid}        → detail with employee preselect
  ///   /company/{id}/book                  → booking flow
  ///   anything else                       → /home (safe fallback)
  void _handle(Uri uri, GoRouter Function() routerBuilder) {
    if (!_trustedHosts.contains(uri.host)) return;

    final path = uri.path;
    final query = uri.query.isNotEmpty ? '?${uri.query}' : '';

    final router = routerBuilder();

    if (path.startsWith('/company/')) {
      router.push('$path$query');
      return;
    }

    // Unknown deep link target — drop the user on the home screen rather
    // than blow up. The browser fallback would have done the same thing.
    router.push('/home');
  }
}
