import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../network/api_exceptions.dart';

extension BuildContextExtensions on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;

  ThemeData get theme => Theme.of(this);

  ColorScheme get colorScheme => theme.colorScheme;

  TextTheme get textTheme => theme.textTheme;

  MediaQueryData get mediaQuery => MediaQuery.of(this);

  Size get screenSize => mediaQuery.size;

  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colorScheme.error : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Map any caught error into a user-facing, localized message.
  ///
  /// Use this instead of `e.toString()` when displaying errors in snackbars,
  /// dialogs, or inline banners. Validation errors from the backend already
  /// carry a human-readable message and are passed through.
  String errorMessage(Object? error) {
    if (error is ApiException) {
      switch (error.kind) {
        case ApiErrorKind.network:
          return l10n.errorNetwork;
        case ApiErrorKind.unauthorized:
          return l10n.errorUnauthorized;
        case ApiErrorKind.notFound:
          return l10n.errorNotFound;
        case ApiErrorKind.server:
          return l10n.errorServer;
        case ApiErrorKind.validation:
          return error.message;
        case ApiErrorKind.unknown:
          return l10n.errorUnknown;
      }
    }
    return l10n.errorUnknown;
  }

  /// Convenience: show a snackbar with the localized error message.
  void showErrorSnackBar(Object? error) {
    showSnackBar(errorMessage(error), isError: true);
  }
}

extension DateTimeExtensions on DateTime {
  String get dayAbbreviation {
    const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return '${days[weekday - 1]}.$day';
  }

  String get formattedDate {
    return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year';
  }

  String get formattedTime {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}

extension StringExtensions on String {
  String get priceLevel {
    final level = int.tryParse(this) ?? 0;
    return List.generate(level, (_) => '€').join();
  }

  /// Trim then uppercase the first character of each whitespace-separated word.
  /// "john  doe " → "John Doe"
  String get titleCase {
    final trimmed = trim();
    if (trimmed.isEmpty) return trimmed;
    return trimmed
        .split(RegExp(r'\s+'))
        .map((w) => w.isEmpty
            ? w
            : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  /// Uppercase only the first character, leaving the rest untouched.
  /// "coupe homme" → "Coupe homme"
  String get capitalize {
    final trimmed = trim();
    if (trimmed.isEmpty) return trimmed;
    return '${trimmed[0].toUpperCase()}${trimmed.substring(1)}';
  }
}

extension IntExtensions on int {
  String get priceLevel => List.generate(this, (_) => '€').join();
}
