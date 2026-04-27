import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/admin_support_tickets_datasource.dart';
import '../../data/models/admin_support_ticket_model.dart';

const _noValue = Object();

class AdminSupportTicketsState {
  final List<AdminSupportTicket> tickets;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final Object? error;

  const AdminSupportTicketsState({
    this.tickets = const [],
    this.isLoading = false,
    this.hasMore = false,
    this.currentPage = 0,
    this.error,
  });

  AdminSupportTicketsState copyWith({
    List<AdminSupportTicket>? tickets,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    Object? error = _noValue,
  }) {
    return AdminSupportTicketsState(
      tickets: tickets ?? this.tickets,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: identical(error, _noValue) ? this.error : error,
    );
  }
}

class AdminSupportTicketsNotifier extends StateNotifier<AdminSupportTicketsState> {
  final AdminSupportTicketsDatasource _datasource;

  AdminSupportTicketsNotifier(this._datasource)
      : super(const AdminSupportTicketsState());

  Future<void> load() async {
    if (!mounted) return;
    state = state.copyWith(
      isLoading: true,
      tickets: const [],
      currentPage: 0,
      error: null,
    );
    try {
      final result = await _datasource.listTickets(page: 1);
      if (!mounted) return;
      state = state.copyWith(
        tickets: result.tickets,
        isLoading: false,
        hasMore: result.hasMore,
        currentPage: 1,
        error: null,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (!mounted || !state.hasMore || state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final nextPage = state.currentPage + 1;
      final result = await _datasource.listTickets(page: nextPage);
      if (!mounted) return;
      state = state.copyWith(
        tickets: [...state.tickets, ...result.tickets],
        isLoading: false,
        hasMore: result.hasMore,
        currentPage: nextPage,
        error: null,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> markResolved(int id) async {
    final previous = state.tickets;
    state = state.copyWith(
      tickets: previous
          .map((t) => t.id == id ? t.copyWith(status: 'resolved') : t)
          .toList(),
    );
    try {
      await _datasource.markResolved(id);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(tickets: previous);
      rethrow;
    }
  }
}

final adminSupportTicketsProvider = StateNotifierProvider<
    AdminSupportTicketsNotifier, AdminSupportTicketsState>((ref) {
  return AdminSupportTicketsNotifier(
    ref.watch(adminSupportTicketsDatasourceProvider),
  );
});
