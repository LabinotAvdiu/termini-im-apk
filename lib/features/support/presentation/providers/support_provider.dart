import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exceptions.dart';
import '../../data/datasources/support_remote_datasource.dart';
import '../../data/models/support_models.dart';

/// Lightweight, stateless notifier — each dialog opens a fresh submission.
///
/// Kept as a Notifier (not a StateNotifier with state) because the dialog
/// manages its own local state; the provider just exposes `submit()` so it
/// can be mocked in tests.
class SupportController {
  final Ref _ref;
  SupportController(this._ref);

  Future<SubmitSupportResult> submit(SupportTicketRequest request) async {
    try {
      final ds = _ref.read(supportRemoteDataSourceProvider);
      final id = await ds.submitTicket(request);
      return SubmitSupportSuccess(id);
    } on ValidationException catch (e) {
      return SubmitSupportError(cause: e, validationMessage: e.message);
    } on ApiException catch (e) {
      return SubmitSupportError(cause: e);
    } catch (e) {
      return SubmitSupportError(cause: e);
    }
  }
}

final supportControllerProvider = Provider<SupportController>((ref) {
  return SupportController(ref);
});
