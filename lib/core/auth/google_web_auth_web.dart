import 'dart:js_interop';

/// Bridge to `window.terminiGoogleSignIn()` declared in `web/index.html`.
///
/// `google_sign_in 6.2.2` relies on GIS' Token Client internally but does not
/// forward the resolved `access_token` back to Dart — calling `signIn()` on
/// web returns a Future that never completes. We drive the GIS SDK ourselves
/// and return the raw `access_token`; the backend accepts it alongside the
/// mobile id_token flow.
@JS('terminiGoogleSignIn')
external JSPromise<JSAny?> _terminiGoogleSignIn();

Future<String?> signInWithGoogleWeb() async {
  final result = await _terminiGoogleSignIn().toDart;
  if (result == null) return null;
  return (result as JSString).toDart;
}
