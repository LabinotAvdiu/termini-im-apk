import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../appointments/presentation/screens/appointments_screen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../company/presentation/screens/company_dashboard_screen.dart';
import '../../../employee_schedule/presentation/screens/employee_schedule_screen.dart';
import '../../../employee_schedule/presentation/screens/schedule_settings_screen.dart';
import '../../../home/presentation/screens/home_screen.dart';

/// Main shell shown only to authenticated users.
///
/// Tab layout depends on the user's role:
///   - UserRole.user     → 2 tabs: Search, Mes RDV
///   - UserRole.company  → 3 tabs: Search, Mon Salon, Mes RDV
///   - UserRole.employee → 2 tabs: Search, Mon Planning
///
/// Tab switching is handled internally — no router involvement.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _selectedIndex = 0;

  void _onTabTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    // Owner:    Search, Mon Salon, Mon Planning, Horaires, Mes RDV
    // Employee: Search, Mon Planning, Horaires, Mes RDV
    // Client:   Search, Mes RDV
    final pages = <Widget>[
      const HomeScreen(),
      if (authState.isOwner) const CompanyDashboardScreen(),
      if (authState.isOwner || authState.isEmployee)
        const EmployeeScheduleScreen(),
      if (authState.isOwner || authState.isEmployee)
        const _LazyPage(child: ScheduleSettingsScreen()),
      const AppointmentsScreen(),
    ];

    final safeIndex = _selectedIndex.clamp(0, pages.length - 1);

    return Scaffold(
      body: IndexedStack(
        index: safeIndex,
        children: pages,
      ),
      bottomNavigationBar: _ShellBottomNav(
        selectedIndex: safeIndex,
        isOwner: authState.isOwner,
        isEmployee: authState.isEmployee,
        onTap: _onTabTapped,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom navigation bar
// ---------------------------------------------------------------------------

class _ShellBottomNav extends StatelessWidget {
  final int selectedIndex;
  final bool isOwner;
  final bool isEmployee;
  final ValueChanged<int> onTap;

  const _ShellBottomNav({
    required this.selectedIndex,
    required this.isOwner,
    required this.isEmployee,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    int idx = 0;
    final items = <_NavItem>[];

    // Tab 0: Search (always)
    final searchIdx = idx;
    items.add(_NavItem(
      icon: Icons.search_rounded,
      label: context.l10n.search,
      selected: selectedIndex == searchIdx,
      onTap: () => onTap(searchIdx),
    ));
    idx++;

    // Tab: Mon Salon (owner only)
    if (isOwner) {
      final salonIdx = idx;
      items.add(_NavItem(
        icon: Icons.storefront_rounded,
        label: context.l10n.mySalon,
        selected: selectedIndex == salonIdx,
        onTap: () => onTap(salonIdx),
      ));
      idx++;
    }

    // Tab: Mon Planning (owner + employee)
    if (isOwner || isEmployee) {
      final planningIdx = idx;
      items.add(_NavItem(
        icon: Icons.view_timeline_rounded,
        label: context.l10n.myPlanning,
        selected: selectedIndex == planningIdx,
        onTap: () => onTap(planningIdx),
      ));
      idx++;
    }

    // Tab: Horaires (owner + employee)
    if (isOwner || isEmployee) {
      final horaireIdx = idx;
      items.add(_NavItem(
        icon: Icons.schedule_rounded,
        label: context.l10n.scheduleSettings,
        selected: selectedIndex == horaireIdx,
        onTap: () => onTap(horaireIdx),
      ));
      idx++;
    }

    // Tab: Mes RDV (everyone)
    {
      final rdvIdx = idx;
      items.add(_NavItem(
        icon: Icons.calendar_month_rounded,
        label: context.l10n.myAppointments,
        selected: selectedIndex == rdvIdx,
        onTap: () => onTap(rdvIdx),
      ));
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(children: items),
        ),
      ),
    );
  }
}

/// Lazy-loads its child only when first made visible by IndexedStack.
/// This prevents API calls from screens the user never visits.
class _LazyPage extends StatefulWidget {
  final Widget child;
  const _LazyPage({required this.child});

  @override
  State<_LazyPage> createState() => _LazyPageState();
}

class _LazyPageState extends State<_LazyPage> {
  bool _built = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // IndexedStack sets TickerMode.of to false for non-visible children.
    // When visible, TickerMode is true.
    if (!_built && TickerMode.of(context)) {
      _built = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check on every build in case visibility changed
    if (!_built && TickerMode.of(context)) {
      _built = true;
    }
    return _built ? widget.child : const SizedBox.shrink();
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textSecondary;

    // Minimum 48dp touch target — full expanded row item satisfies this.
    return Expanded(
      child: Semantics(
        label: label,
        selected: selected,
        button: true,
        child: InkWell(
          onTap: onTap,
          splashColor: AppColors.primary.withValues(alpha: 0.08),
          highlightColor: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: selected ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                  color: color,
                  height: 1.2,
                ),
                child: Text(label, maxLines: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
