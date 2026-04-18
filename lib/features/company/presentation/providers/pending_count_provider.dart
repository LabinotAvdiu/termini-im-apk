import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/my_company_remote_datasource.dart';
import 'company_dashboard_provider.dart';

class PendingCountNotifier extends StateNotifier<int> {
  final MyCompanyRemoteDatasource _datasource;
  Timer? _timer;

  PendingCountNotifier(this._datasource) : super(0) {
    refresh();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> refresh() async {
    if (!mounted) return;
    try {
      final list = await _datasource.getPendingAppointments();
      if (!mounted) return;
      state = list.length;
    } catch (_) {}
  }
}

final pendingCountProvider =
    StateNotifierProvider<PendingCountNotifier, int>((ref) {
  return PendingCountNotifier(ref.watch(myCompanyDatasourceProvider));
});
