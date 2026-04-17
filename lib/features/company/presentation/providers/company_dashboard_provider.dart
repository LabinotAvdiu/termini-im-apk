import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/datasources/my_company_remote_datasource.dart';
import '../../data/models/my_company_model.dart';

// ---------------------------------------------------------------------------
// Datasource provider
// ---------------------------------------------------------------------------

final myCompanyDatasourceProvider = Provider<MyCompanyRemoteDatasource>((ref) {
  return MyCompanyRemoteDatasource(client: ref.watch(dioClientProvider));
});

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class CompanyDashboardState {
  final MyCompanyModel? company;
  final bool isLoading;
  final String? error;

  /// Tracks which category IDs are expanded in the services section.
  final Set<String> expandedCategories;

  const CompanyDashboardState({
    this.company,
    this.isLoading = false,
    this.error,
    this.expandedCategories = const {},
  });

  CompanyDashboardState copyWith({
    MyCompanyModel? company,
    bool? isLoading,
    String? error,
    Set<String>? expandedCategories,
  }) =>
      CompanyDashboardState(
        company: company ?? this.company,
        isLoading: isLoading ?? this.isLoading,
        // Pass null explicitly to clear the error field.
        error: error,
        expandedCategories: expandedCategories ?? this.expandedCategories,
      );
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class CompanyDashboardNotifier extends StateNotifier<CompanyDashboardState> {
  final MyCompanyRemoteDatasource _datasource;

  CompanyDashboardNotifier({required MyCompanyRemoteDatasource datasource})
      : _datasource = datasource,
        super(const CompanyDashboardState());

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Load company info, categories, and employees in parallel
      final results = await Future.wait([
        _datasource.getMyCompany(),
        _datasource.getCategories(),
        _datasource.getEmployees(),
      ]);

      final company = results[0] as MyCompanyModel;
      final categories = results[1] as List<MyCategoryModel>;
      final employees = results[2] as List<MyEmployeeModel>;

      state = state.copyWith(
        isLoading: false,
        company: company.copyWith(
          categories: categories,
          employees: employees,
        ),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Company info ──────────────────────────────────────────────────────────

  Future<bool> updateCompanyInfo(Map<String, dynamic> data) async {
    try {
      final updated = await _datasource.updateCompany(data);
      state = state.copyWith(company: updated, error: null);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // ── Categories ────────────────────────────────────────────────────────────

  void toggleCategory(String id) {
    final current = Set<String>.from(state.expandedCategories);
    if (current.contains(id)) {
      current.remove(id);
    } else {
      current.add(id);
    }
    state = state.copyWith(expandedCategories: current, error: null);
  }

  Future<bool> addCategory(String name) async {
    try {
      final created = await _datasource.createCategory(name);
      final categories = [
        ...?state.company?.categories,
        created,
      ];
      state = state.copyWith(
        company: state.company?.copyWith(categories: categories),
        error: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> editCategory(String id, String name) async {
    try {
      final updated = await _datasource.updateCategory(id, name);
      final categories = state.company?.categories
              .map((c) => c.id == id ? updated.copyWith(services: c.services) : c)
              .toList() ??
          [];
      state = state.copyWith(
        company: state.company?.copyWith(categories: categories),
        error: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> removeCategory(String id) async {
    try {
      await _datasource.deleteCategory(id);
      final categories =
          state.company?.categories.where((c) => c.id != id).toList() ?? [];
      state = state.copyWith(
        company: state.company?.copyWith(categories: categories),
        error: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // ── Services ──────────────────────────────────────────────────────────────

  Future<bool> addService({
    required String categoryId,
    required String name,
    required int durationMinutes,
    required double price,
    int? maxConcurrent,
  }) async {
    try {
      final created = await _datasource.createService({
        'category_id': categoryId,
        'name': name,
        'duration': durationMinutes,
        'price': price,
        if (maxConcurrent != null) 'max_concurrent': maxConcurrent,
      });
      final categories = state.company?.categories.map((c) {
            if (c.id != categoryId) return c;
            return c.copyWith(services: [...c.services, created]);
          }).toList() ??
          [];
      state = state.copyWith(
        company: state.company?.copyWith(categories: categories),
        error: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> editService({
    required String serviceId,
    required String categoryId,
    required String name,
    required int durationMinutes,
    required double price,
    int? maxConcurrent,
  }) async {
    try {
      final updated = await _datasource.updateService(serviceId, {
        'name': name,
        'duration': durationMinutes,
        'price': price,
        if (maxConcurrent != null) 'max_concurrent': maxConcurrent,
      });
      final categories = state.company?.categories.map((c) {
            if (c.id != categoryId) return c;
            return c.copyWith(
              services: c.services
                  .map((s) => s.id == serviceId ? updated : s)
                  .toList(),
            );
          }).toList() ??
          [];
      state = state.copyWith(
        company: state.company?.copyWith(categories: categories),
        error: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> removeService({
    required String serviceId,
    required String categoryId,
  }) async {
    try {
      await _datasource.deleteService(serviceId);
      final categories = state.company?.categories.map((c) {
            if (c.id != categoryId) return c;
            return c.copyWith(
              services: c.services.where((s) => s.id != serviceId).toList(),
            );
          }).toList() ??
          [];
      state = state.copyWith(
        company: state.company?.copyWith(categories: categories),
        error: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // ── Employees ─────────────────────────────────────────────────────────────

  Future<bool> inviteEmployee({
    required String email,
    required List<String> specialties,
  }) async {
    try {
      final employee = await _datasource.inviteEmployee(
        email: email,
        specialties: specialties,
      );
      final employees = [...?state.company?.employees, employee];
      state = state.copyWith(
        company: state.company?.copyWith(employees: employees),
        error: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> createEmployee(Map<String, dynamic> data) async {
    try {
      final employee = await _datasource.createEmployee(data);
      final employees = [...?state.company?.employees, employee];
      state = state.copyWith(
        company: state.company?.copyWith(employees: employees),
        error: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> editEmployee(String id, Map<String, dynamic> data) async {
    try {
      final updated = await _datasource.updateEmployee(id, data);
      final employees = state.company?.employees
              .map((e) => e.id == id ? updated : e)
              .toList() ??
          [];
      state = state.copyWith(
        company: state.company?.copyWith(employees: employees),
        error: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> removeEmployee(String id) async {
    try {
      await _datasource.removeEmployee(id);
      final employees =
          state.company?.employees.where((e) => e.id != id).toList() ?? [];
      state = state.copyWith(
        company: state.company?.copyWith(employees: employees),
        error: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // ── Opening hours ─────────────────────────────────────────────────────────

  Future<bool> saveHours(List<OpeningHourModel> hours) async {
    try {
      final updated = await _datasource.updateHours(hours);
      state = state.copyWith(
        company: state.company?.copyWith(openingHours: updated),
        error: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final companyDashboardProvider =
    StateNotifierProvider<CompanyDashboardNotifier, CompanyDashboardState>(
  (ref) => CompanyDashboardNotifier(
    datasource: ref.watch(myCompanyDatasourceProvider),
  ),
);
