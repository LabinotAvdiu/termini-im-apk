import 'dart:typed_data';

/// Where the ticket was sent from — lets support prioritize and debug.
///
/// Kept as a sealed enum so the i18n layer can render human labels and the
/// backend can persist the raw wire value.
enum SupportSourcePage {
  settings('settings'),
  myCompany('my_company'),
  companyDetail('company_detail'),
  login('login'),
  signup('signup'),
  desktopMenu('desktop_menu');

  const SupportSourcePage(this.wireValue);
  final String wireValue;
}

/// One file staged for upload. Holds raw bytes so the widget works on Web
/// (dart:io File is not available there).
class SupportAttachment {
  final String name;
  final Uint8List bytes;
  final String mime; // image/jpeg, image/png, image/webp, application/pdf
  final int sizeBytes;

  const SupportAttachment({
    required this.name,
    required this.bytes,
    required this.mime,
    required this.sizeBytes,
  });

  bool get isPdf => mime == 'application/pdf';
  bool get isImage => mime.startsWith('image/');
}

class SupportTicketRequest {
  final String firstName;
  final String phone;
  final String? email;
  final String message;
  final SupportSourcePage sourcePage;
  final Map<String, Object?>? sourceContext;
  final List<SupportAttachment> attachments;

  const SupportTicketRequest({
    required this.firstName,
    required this.phone,
    this.email,
    required this.message,
    required this.sourcePage,
    this.sourceContext,
    this.attachments = const [],
  });
}

/// Structured result for the dialog to dispatch on.
sealed class SubmitSupportResult {
  const SubmitSupportResult();
}

class SubmitSupportSuccess extends SubmitSupportResult {
  final int ticketId;
  const SubmitSupportSuccess(this.ticketId);
}

class SubmitSupportError extends SubmitSupportResult {
  /// Raw exception (usually [ApiException]) — pass to
  /// `context.errorMessage(...)` for a localized message, or to
  /// [validationMessage] for already-user-facing validation text.
  final Object? cause;
  /// Server-provided user-facing validation message, when kind == validation.
  final String? validationMessage;
  const SubmitSupportError({this.cause, this.validationMessage});
}
