import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class AppContent extends StatelessWidget {
  const AppContent({
    super.key,
    required this.child,
    this.controller,
    this.maxWidth = 1080,
  });
  final Widget child;
  final ScrollController? controller;
  final double maxWidth;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    controller: controller,
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    padding: EdgeInsets.fromLTRB(
      20,
      MediaQuery.sizeOf(context).height < 480 ? 12 : 16,
      20,
      20,
    ),
    child: Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    ),
  );
}

class AdaptiveColumns extends StatelessWidget {
  const AdaptiveColumns({super.key, required this.first, required this.second});
  final Widget first, second;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final split =
          constraints.maxWidth >= 600 &&
          MediaQuery.textScalerOf(context).scale(16) <= 24;
      if (split) {
        return _EqualHeightColumns(children: [first, second]);
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [first, const SizedBox(height: 16), second],
      );
    },
  );
}

class _EqualHeightColumns extends MultiChildRenderObjectWidget {
  const _EqualHeightColumns({required super.children});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderEqualColumns();
}

class _ColumnParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderEqualColumns extends RenderBox
    with
        ContainerRenderObjectMixin<
          RenderBox,
          ContainerBoxParentData<RenderBox>
        >,
        RenderBoxContainerDefaultsMixin<
          RenderBox,
          ContainerBoxParentData<RenderBox>
        > {
  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! ContainerBoxParentData<RenderBox>) {
      child.parentData = _ColumnParentData();
    }
  }

  @override
  void performLayout() {
    final width = (constraints.maxWidth - 16) / 2;
    final left = firstChild!;
    final right = childAfter(left)!;
    final natural = BoxConstraints.tightFor(width: width);
    left.layout(natural, parentUsesSize: true);
    right.layout(natural, parentUsesSize: true);
    final height = left.size.height > right.size.height
        ? left.size.height
        : right.size.height;
    // Keep height unbounded so expanding content requests a fresh parent layout.
    final matched = BoxConstraints(
      minWidth: width,
      maxWidth: width,
      minHeight: height,
    );
    left.layout(matched, parentUsesSize: true);
    right.layout(matched, parentUsesSize: true);
    (right.parentData! as ContainerBoxParentData<RenderBox>).offset = Offset(
      width + 16,
      0,
    );
    size = constraints.constrain(Size(constraints.maxWidth, height));
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}

class AppPanel extends StatelessWidget {
  const AppPanel({
    super.key,
    required this.child,
    this.tinted = false,
    this.padding = 16,
  });
  final Widget child;
  final bool tinted;
  final double padding;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: tinted
          ? scheme.surfaceContainerLow
          : scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(padding: EdgeInsets.all(padding), child: child),
    );
  }
}

class PageIntro extends StatelessWidget {
  const PageIntro(this.title, this.description, {super.key});
  final String title, description;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Semantics(
        header: true,
        child: Text(
          title,
          style: MediaQuery.sizeOf(context).height < 480
              ? Theme.of(context).textTheme.titleLarge
              : Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        description,
        style:
            (MediaQuery.sizeOf(context).height < 480
                    ? Theme.of(context).textTheme.bodySmall
                    : Theme.of(context).textTheme.bodyLarge)
                ?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
      ),
    ],
  );
}

class AppActionTile extends StatefulWidget {
  const AppActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title, subtitle;
  final VoidCallback? onTap;
  @override
  State<AppActionTile> createState() => _AppActionTileState();
}

class _AppActionTileState extends State<AppActionTile> {
  bool _focused = false;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final largeText = MediaQuery.textScalerOf(context).scale(16) > 20;
    return Material(
      color: theme.colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: _focused
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: widget.onTap,
        onFocusChange: (value) => setState(() => _focused = value),
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight:
                (largeText ? 104 : 80) *
                MediaQuery.textScalerOf(context).scale(16) /
                16,
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                if (!largeText) ...[
                  SizedBox(width: 40, height: 40, child: IconTile(widget.icon)),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class IconTile extends StatelessWidget {
  const IconTile(this.icon, {super.key});
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    width: 48,
    height: 48,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(icon, color: Theme.of(context).colorScheme.onPrimaryContainer),
  );
}

class AppNotice extends StatelessWidget {
  const AppNotice(
    this.message, {
    super.key,
    this.error = false,
    this.icon = Icons.info_outline,
  }) : _warning = false;
  const AppNotice.warning(this.message, {super.key})
    : error = false,
      icon = Icons.warning_amber_rounded,
      _warning = true;
  final String message;
  final bool error;
  final IconData icon;
  final bool _warning;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final warningBackground = dark
        ? const Color(0xFF302719)
        : const Color(0xFFFFF4D6);
    final warningForeground = dark
        ? const Color(0xFFFFD985)
        : const Color(0xFF5D3B00);
    return Semantics(
      liveRegion: error,
      child: Container(
        padding: EdgeInsets.all(_warning ? 12 : 16),
        decoration: BoxDecoration(
          color: _warning
              ? warningBackground
              : error
              ? scheme.errorContainer
              : scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: _warning
              ? Border.all(
                  color: dark
                      ? const Color(0xFF735B25)
                      : const Color(0xFFD89B1D),
                )
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              error ? Icons.error_outline : icon,
              size: 20,
              semanticLabel: _warning ? 'Peringatan' : null,
              color: _warning
                  ? warningForeground
                  : error
                  ? scheme.onErrorContainer
                  : scheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _warning
                      ? warningForeground
                      : error
                      ? scheme.onErrorContainer
                      : scheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ConnectionRoute extends StatelessWidget {
  const ConnectionRoute({super.key});
  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 480;
    final devices = [
      (Icons.phone_iphone, 'iPhone', 'Sumber CarPlay'),
      (Icons.smartphone, 'Android', 'Receiver lokal'),
      (Icons.directions_car_outlined, 'Head unit', 'Tampilan T-Link'),
    ];
    final horizontal =
        MediaQuery.sizeOf(context).width >= 360 &&
        MediaQuery.textScalerOf(context).scale(16) < 24;
    final children = <Widget>[
      for (final (icon, title, description) in devices)
        Padding(
          padding: EdgeInsets.symmetric(vertical: compact ? 4 : 8),
          child: horizontal
              ? Column(
                  children: [
                    SizedBox(
                      width: compact ? 36 : 48,
                      height: compact ? 36 : 48,
                      child: IconTile(icon),
                    ),
                    SizedBox(height: compact ? 6 : 10),
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    Text(
                      description,
                      style: compact
                          ? Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontSize: 12)
                          : Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              : Row(
                  children: [
                    IconTile(icon),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            description,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
    ];
    return horizontal
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [for (final child in children) Expanded(child: child)],
          )
        : Column(children: children);
  }
}
