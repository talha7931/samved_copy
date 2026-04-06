import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ShellNavItem {
  const ShellNavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.location,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String location;
}

class RoleShellScaffold extends StatelessWidget {
  const RoleShellScaffold({
    super.key,
    required this.child,
    required this.items,
    required this.activeLocationPrefix,
  });

  final Widget child;
  final List<ShellNavItem> items;
  final String activeLocationPrefix;

  int _resolveIndex(BuildContext context) {
    final current = GoRouterState.of(context).uri.path;
    final exact = items.indexWhere((e) => e.location == current);
    if (exact != -1) return exact;
    final prefix = items.indexWhere((e) => current.startsWith(e.location));
    if (prefix != -1) return prefix;
    final fallback = items.indexWhere((e) => e.location.startsWith(activeLocationPrefix));
    return fallback == -1 ? 0 : fallback;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final currentIndex = _resolveIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => context.go(items[i].location),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                        decoration: BoxDecoration(
                          color: currentIndex == i ? cs.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              currentIndex == i ? items[i].activeIcon : items[i].icon,
                              size: 20,
                              color: currentIndex == i ? cs.onPrimary : cs.onSurfaceVariant,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              items[i].label,
                              style: tt.labelSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: currentIndex == i ? cs.onPrimary : cs.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
