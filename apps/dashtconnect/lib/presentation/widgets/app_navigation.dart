import 'package:flutter/material.dart';

class AppNavigation extends StatelessWidget {
  const AppNavigation({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    this.rail = false,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool rail;

  static const destinations = [
    (Icons.space_dashboard_outlined, Icons.space_dashboard_rounded, 'Beranda'),
    (Icons.route_outlined, Icons.route_rounded, 'Panduan'),
    (Icons.tune_outlined, Icons.tune_rounded, 'Pengaturan'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final items = List.generate(destinations.length, (index) {
      final item = destinations[index];
      return _NavigationItem(
        selected: selectedIndex == index,
        icon: selectedIndex == index ? item.$2 : item.$1,
        label: item.$3,
        rail: rail,
        onTap: () => onSelected(index),
      );
    });
    final navigation = Material(
      color: scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: rail
          ? SizedBox(
              width: MediaQuery.textScalerOf(context).scale(12) > 16 ? 112 : 96,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(4),
                child: Column(mainAxisSize: MainAxisSize.min, children: items),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(6),
              child: Row(
                children: [for (final item in items) Expanded(child: item)],
              ),
            ),
    );
    if (rail) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(6, 8, 0, 8),
        child: Align(
          alignment: Alignment.topCenter,
          widthFactor: 1,
          child: navigation,
        ),
      );
    }
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
        child: navigation,
      ),
    );
  }
}

class _NavigationItem extends StatefulWidget {
  const _NavigationItem({
    required this.selected,
    required this.icon,
    required this.label,
    required this.rail,
    required this.onTap,
  });
  final bool selected, rail;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_NavigationItem> createState() => _NavigationItemState();
}

class _NavigationItemState extends State<_NavigationItem> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = widget.selected ? scheme.primary : scheme.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.label,
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: widget.selected ? scheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _focused ? scheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onFocusChange: (value) => setState(() => _focused = value),
            borderRadius: BorderRadius.circular(14),
            child: ExcludeSemantics(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 52),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 6,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final inline =
                          !widget.rail &&
                          constraints.maxWidth >= 96 &&
                          MediaQuery.textScalerOf(context).scale(12) <= 14;
                      final icon = Icon(widget.icon, size: 21, color: color);
                      final label = Text(
                        widget.label,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: color,
                          fontWeight: widget.selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      );
                      return inline
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                icon,
                                const SizedBox(width: 6),
                                Flexible(child: label),
                              ],
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                icon,
                                const SizedBox(height: 5),
                                label,
                              ],
                            );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
