import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../../../appointments/presentation/screens/appointments_screen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../company/presentation/providers/company_dashboard_provider.dart';
import '../../../company/presentation/providers/pending_count_provider.dart';
import '../../../company/presentation/screens/company_dashboard_screen.dart';
import '../../../company/presentation/screens/company_planning_screen.dart';
import '../../../company/presentation/screens/pending_approvals_screen.dart';
import '../../../employee_schedule/presentation/screens/employee_schedule_screen.dart';
import '../../../employee_schedule/presentation/screens/schedule_settings_screen.dart';
import '../../../home/presentation/screens/home_screen.dart';

/// Main shell shown only to authenticated users.
///
/// Mobile → bottom nav bar. Desktop → left sidebar (matches the D3/D4 mockup).
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
    final companyBookingMode = authState.isOwner
        ? ref.watch(companyDashboardProvider.select(
            (s) => s.company?.bookingMode ?? 'employee_based'))
        : 'employee_based';
    final isCapacityOwner =
        authState.isOwner && companyBookingMode == 'capacity_based';
    final pendingCount =
        isCapacityOwner ? ref.watch(pendingCountProvider) : 0;

    final isClient = authState.isClient || authState.isGuest;
    final pages = <Widget>[
      const HomeScreen(),
      if (authState.isOwner) const CompanyDashboardScreen(),
      if ((authState.isOwner && !isCapacityOwner) || authState.isEmployee)
        const EmployeeScheduleScreen(),
      if (isCapacityOwner) const _LazyPage(child: CompanyPlanningScreen()),
      if ((authState.isOwner && !isCapacityOwner) || authState.isEmployee)
        const _LazyPage(child: ScheduleSettingsScreen()),
      if (isCapacityOwner) const _LazyPage(child: PendingApprovalsScreen()),
      if (isClient) const AppointmentsScreen(),
    ];

    if (authState.justSignedUp && authState.isOwner && _selectedIndex == 0) {
      _selectedIndex = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(authStateProvider.notifier).clearJustSignedUp();
        }
      });
    }

    final safeIndex = _selectedIndex.clamp(0, pages.length - 1);

    // Build a shared tab spec list used by both mobile (bottom nav) and
    // desktop (sidebar) — this is the single source of truth for the shell's
    // navigation.
    final tabs = _buildTabs(
      context: context,
      isOwner: authState.isOwner,
      isEmployee: authState.isEmployee,
      isCapacityOwner: isCapacityOwner,
      isClient: isClient,
      pendingCount: pendingCount,
      selectedIndex: safeIndex,
      onTap: _onTabTapped,
    );

    if (ResponsiveLayout.isDesktop(context)) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ShellSidebar(tabs: tabs),
            Expanded(
              child: IndexedStack(
                index: safeIndex,
                children: pages,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: safeIndex,
        children: pages,
      ),
      bottomNavigationBar: _ShellBottomNav(tabs: tabs),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab spec — data class shared between mobile bottom nav and desktop sidebar.
// ---------------------------------------------------------------------------

class _TabSpec {
  final IconData icon;
  final String label;
  final bool selected;
  final int badgeCount;
  final VoidCallback onTap;

  const _TabSpec({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });
}

List<_TabSpec> _buildTabs({
  required BuildContext context,
  required bool isOwner,
  required bool isEmployee,
  required bool isCapacityOwner,
  required bool isClient,
  required int pendingCount,
  required int selectedIndex,
  required ValueChanged<int> onTap,
}) {
  final list = <_TabSpec>[];
  int idx = 0;

  void add(_TabSpec Function(int i) builder) {
    list.add(builder(idx));
    idx++;
  }

  add((i) => _TabSpec(
        icon: Icons.search_rounded,
        label: context.l10n.search,
        selected: selectedIndex == i,
        onTap: () => onTap(i),
      ));

  if (isOwner) {
    add((i) => _TabSpec(
          icon: Icons.storefront_rounded,
          label: context.l10n.mySalon,
          selected: selectedIndex == i,
          onTap: () => onTap(i),
        ));
  }

  if ((isOwner && !isCapacityOwner) || isEmployee) {
    add((i) => _TabSpec(
          icon: Icons.view_timeline_rounded,
          label: context.l10n.myPlanning,
          selected: selectedIndex == i,
          onTap: () => onTap(i),
        ));
  }

  if (isCapacityOwner) {
    add((i) => _TabSpec(
          icon: Icons.view_timeline_rounded,
          label: context.l10n.myPlanning,
          selected: selectedIndex == i,
          onTap: () => onTap(i),
        ));
  }

  if ((isOwner && !isCapacityOwner) || isEmployee) {
    add((i) => _TabSpec(
          icon: Icons.schedule_rounded,
          label: context.l10n.scheduleSettings,
          selected: selectedIndex == i,
          onTap: () => onTap(i),
        ));
  }

  if (isCapacityOwner) {
    add((i) => _TabSpec(
          icon: Icons.pending_actions_rounded,
          label: context.l10n.pendingApprovalsShort,
          selected: selectedIndex == i,
          badgeCount: pendingCount,
          onTap: () => onTap(i),
        ));
  }

  if (isClient) {
    add((i) => _TabSpec(
          icon: Icons.calendar_month_rounded,
          label: context.l10n.myAppointments,
          selected: selectedIndex == i,
          onTap: () => onTap(i),
        ));
  }

  // Profile — routes out of the shell to the Settings screen (index is ignored).
  list.add(_TabSpec(
    icon: Icons.person_outline_rounded,
    label: context.l10n.profile,
    selected: false,
    onTap: () => context.go('/settings'),
  ));

  return list;
}

// ---------------------------------------------------------------------------
// Desktop sidebar — D3/D4 editorial pattern
// ---------------------------------------------------------------------------

class _ShellSidebar extends StatefulWidget {
  final List<_TabSpec> tabs;

  const _ShellSidebar({required this.tabs});

  @override
  State<_ShellSidebar> createState() => _ShellSidebarState();
}

class _ShellSidebarState extends State<_ShellSidebar> {
  static const _collapsedWidth = 72.0;
  static const _expandedWidth = 240.0;
  static const _animDuration = Duration(milliseconds: 220);

  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: _animDuration,
      curve: Curves.easeInOut,
      width: _isExpanded ? _expandedWidth : _collapsedWidth,
      color: AppColors.textPrimary,
      padding: EdgeInsets.symmetric(
        horizontal: _isExpanded ? AppSpacing.lg : AppSpacing.sm,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand — logo + (optional) wordmark
          _SidebarBrand(isExpanded: _isExpanded),
          const SizedBox(height: 38),
          // Nav
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: widget.tabs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, i) => _SidebarItem(
                spec: widget.tabs[i],
                isExpanded: _isExpanded,
              ),
            ),
          ),
          // Toggle at bottom — intentionally NOT aligned with nav icons
          const SizedBox(height: AppSpacing.sm),
          Divider(
              height: 1,
              thickness: 1,
              color: AppColors.background.withValues(alpha: 0.08)),
          const SizedBox(height: AppSpacing.md),
          _SidebarToggleButton(
            isExpanded: _isExpanded,
            onToggle: () => setState(() => _isExpanded = !_isExpanded),
          ),
        ],
      ),
    );
  }
}

class _SidebarBrand extends StatelessWidget {
  final bool isExpanded;

  const _SidebarBrand({required this.isExpanded});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
          isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
      children: [
        const BrandLogo(variant: BrandLogoVariant.ivory, size: 34),
        if (isExpanded) ...[
          const SizedBox(width: 10),
          Expanded(
            child: AnimatedOpacity(
              opacity: isExpanded ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              child: Text.rich(
                TextSpan(
                  style: GoogleFonts.fraunces(
                    fontSize: 18,
                    color: AppColors.background,
                    letterSpacing: -0.2,
                  ),
                  children: [
                    const TextSpan(text: 'Termini '),
                    TextSpan(
                      text: 'im',
                      style: GoogleFonts.instrumentSerif(
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.clip,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SidebarToggleButton extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onToggle;

  const _SidebarToggleButton({
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onToggle,
        child: Container(
          // Intentionally offset from the nav icon column:
          // collapsed → left-aligned (not centered like icons above),
          // expanded → flush-right with the label column.
          alignment:
              isExpanded ? Alignment.centerRight : Alignment.centerLeft,
          padding: EdgeInsets.symmetric(
            horizontal: isExpanded ? 8 : 6,
            vertical: 4,
          ),
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.background.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            child: Icon(
              isExpanded ? Icons.menu_open_rounded : Icons.menu_rounded,
              size: 16,
              color: AppColors.background.withValues(alpha: 0.85),
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final _TabSpec spec;
  final bool isExpanded;

  const _SidebarItem({
    required this.spec,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = spec.selected;
    final content = Stack(
      children: [
        if (isActive)
          Positioned(
            left: 0,
            top: 8,
            bottom: 8,
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isExpanded ? 14 : 10,
            vertical: 10,
          ),
          child: Row(
            mainAxisAlignment: isExpanded
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    spec.icon,
                    size: 18,
                    color: isActive
                        ? AppColors.background
                        : AppColors.background.withValues(alpha: 0.7),
                  ),
                  if (!isExpanded && spec.badgeCount > 0)
                    Positioned(
                      right: -6,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        constraints:
                            const BoxConstraints(minWidth: 14, minHeight: 14),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                              color: AppColors.textPrimary, width: 1),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          spec.badgeCount > 9 ? '9+' : '${spec.badgeCount}',
                          style: GoogleFonts.instrumentSans(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: AppColors.background,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (isExpanded) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    spec.label,
                    style: GoogleFonts.instrumentSans(
                      fontSize: 13,
                      color: isActive
                          ? AppColors.background
                          : AppColors.background.withValues(alpha: 0.7),
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (spec.badgeCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      spec.badgeCount > 9 ? '9+' : '${spec.badgeCount}',
                      style: GoogleFonts.instrumentSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.background,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );

    final tile = MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: spec.onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.background.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: content,
        ),
      ),
    );

    return isExpanded
        ? tile
        : Tooltip(
            message: spec.label,
            preferBelow: false,
            child: tile,
          );
  }
}

// ---------------------------------------------------------------------------
// Mobile bottom nav
// ---------------------------------------------------------------------------

class _ShellBottomNav extends StatelessWidget {
  final List<_TabSpec> tabs;

  const _ShellBottomNav({required this.tabs});

  @override
  Widget build(BuildContext context) {
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
          child: Row(
            children: tabs.map((t) => _BottomNavItem(spec: t)).toList(),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final _TabSpec spec;

  const _BottomNavItem({required this.spec});

  Widget _iconWithBadge(IconData icon, Color color) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, color: color, size: 24),
        if (spec.badgeCount > 0)
          Positioned(
            top: -6,
            right: -8,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints:
                  const BoxConstraints(minWidth: 18, minHeight: 18),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                spec.badgeCount > 9 ? '9+' : '${spec.badgeCount}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = spec.selected ? AppColors.primary : AppColors.textSecondary;
    return Expanded(
      child: Semantics(
        label: spec.label,
        selected: spec.selected,
        button: true,
        child: InkWell(
          onTap: spec.onTap,
          splashColor: AppColors.primary.withValues(alpha: 0.08),
          highlightColor: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: spec.selected ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                child: _iconWithBadge(spec.icon, color),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      spec.selected ? FontWeight.w600 : FontWeight.w400,
                  color: color,
                  height: 1.2,
                ),
                child: Text(spec.label, maxLines: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Lazy-loaded page — keeps the IndexedStack from eagerly building every tab.
// ---------------------------------------------------------------------------

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
    if (!_built && TickerMode.of(context)) {
      _built = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_built && TickerMode.of(context)) {
      _built = true;
    }
    return _built ? widget.child : const SizedBox.shrink();
  }
}
