// Web implementation: write the selected locale to window.localStorage so the
// splash screen (index.html) can localize before Flutter boots.
import 'dart:html' as html;

void writeWebLocale(String code) {
  try {
    html.window.localStorage['termini_locale'] = code;
  } catch (_) {
    // Storage disabled (private mode, quota, etc.) — ignore.
  }
}
