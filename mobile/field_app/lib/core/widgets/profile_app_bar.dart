import 'package:flutter/material.dart';

class ProfileAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ProfileAppBar({
    super.key,
    required this.greeting,
    required this.name,
    this.subtitle,
    this.actions = const [],
  });

  final String greeting;
  final String name;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'RN';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return AppBar(
      toolbarHeight: 72,
      titleSpacing: 16,
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: cs.primary.withValues(alpha: 0.12),
            child: Text(
              _initials(name),
              style: tt.labelLarge?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  name,
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Text(
                    subtitle!,
                    style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: actions,
    );
  }
}
