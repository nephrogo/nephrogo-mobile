import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:nephrogo_api_client/nephrogo_api_client.dart';

class SpeedDialFloatingActionButton extends StatefulWidget {
  final String label;
  final List<SpeedDialChild> children;
  final VoidCallback? onPress;
  final IconData icon;

  const SpeedDialFloatingActionButton({
    Key? key,
    required this.label,
    this.onPress,
    this.icon = Icons.add,
    this.children = const [],
  }) : super(key: key);

  @override
  _SpeedDialFloatingActionButtonState createState() =>
      _SpeedDialFloatingActionButtonState();
}

class _SpeedDialFloatingActionButtonState
    extends State<SpeedDialFloatingActionButton> {
  late ValueNotifier<bool> _isDialOpen;

  @override
  void initState() {
    super.initState();

    _isDialOpen = ValueNotifier(false);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isDialOpen.value) {
          _isDialOpen.value = false;
          return false;
        }
        return true;
      },
      child: SpeedDial(
        overlayOpacity: 0.9,
        openCloseDial: _isDialOpen,
        icon: widget.icon,
        activeIcon: Icons.close,
        backgroundColor: Colors.redAccent,
        label: Text(
          widget.label.toUpperCase(),
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        children: widget.children,
        onPress: widget.onPress,
      ),
    );
  }

  @override
  void dispose() {
    _isDialOpen.dispose();

    super.dispose();
  }
}

class BasicSection extends StatelessWidget {
  final Widget? header;
  final Widget? footer;
  final List<Widget> children;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry innerPadding;
  final bool showDividers;
  final bool showHeaderDivider;
  final CrossAxisAlignment crossAxisAlignment;

  BasicSection({
    Key? key,
    this.header,
    this.footer,
    this.children = const [],
    this.showDividers = false,
    this.showHeaderDivider = false,
    EdgeInsetsGeometry? margin,
    this.innerPadding = EdgeInsets.zero,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  })  : assert(header != null || children.isNotEmpty,
            'Either header or at least one child should be passed'),
        assert(!showHeaderDivider || (showHeaderDivider && header != null)),
        margin = margin ?? const EdgeInsets.only(bottom: 16),
        super(key: key);

  const BasicSection.single({
    required Widget child,
    this.margin = const EdgeInsets.only(bottom: 16),
    this.innerPadding = EdgeInsets.zero,
    this.footer,
  })
  // ignore: prefer_initializing_formals
  : header = child,
        children = const [],
        showHeaderDivider = false,
        showDividers = false,
        crossAxisAlignment = CrossAxisAlignment.start;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin,
      shape: const RoundedRectangleBorder(),
      clipBehavior: Clip.none,
      elevation: 0,
      child: Padding(
        padding: innerPadding,
        child: _buildHeaderAndChildren(context),
      ),
    );
  }

  Widget _buildHeaderAndChildren(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: _getPreparedChildren(context).toList(),
    );
  }

  Iterable<Widget> _getPreparedChildren(BuildContext context) sync* {
    if (header != null && !showHeaderDivider) {
      yield header!;
    }

    if (showDividers) {
      final allChildren = <Widget>[
        if (header != null && showHeaderDivider) header!,
        ...children
      ];

      if (allChildren.isNotEmpty) {
        yield* ListTile.divideTiles(
          context: context,
          tiles: allChildren,
        );
      }
    } else {
      yield* children;
    }

    if (footer != null) {
      yield const Divider(height: 1);
      yield footer!;
    }
  }
}

class LargeSection extends StatelessWidget {
  final List<Widget> children;
  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final Widget? footer;
  final bool showDividers;
  final bool showHeaderDivider;
  final GestureTapCallback? onTap;

  const LargeSection({
    Key? key,
    required this.title,
    required this.children,
    this.subtitle,
    this.leading,
    this.trailing,
    this.footer,
    this.onTap,
    this.showDividers = false,
    this.showHeaderDivider = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BasicSection(
      showDividers: showDividers,
      showHeaderDivider: showHeaderDivider,
      header: LargeAppListTile(
        title: title,
        subtitle: subtitle,
        leading: leading,
        trailing: trailing,
        onTap: onTap,
      ),
      footer: footer,
      children: children,
    );
  }
}

class SmallSection extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final List<Widget> children;
  final bool showDividers;
  final EdgeInsets innerPadding;

  const SmallSection({
    Key? key,
    required this.title,
    required this.children,
    this.trailing,
    this.showDividers = false,
    this.innerPadding = const EdgeInsets.only(bottom: 4),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BasicSection(
      showDividers: showDividers,
      header: AppListTile(
        title: Text(
          title,
          style: Theme.of(context)
              .textTheme
              .subtitle1!
              .copyWith(color: Colors.grey),
        ),
        trailing: trailing,
        dense: true,
      ),
      innerPadding: innerPadding,
      children: children,
    );
  }
}

class LargeAppListTile extends StatelessWidget {
  final Widget title;
  final Widget? leading;
  final Widget? subtitle;
  final Widget? trailing;
  final GestureTapCallback? onTap;

  const LargeAppListTile({
    Key? key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppListTile(
      title: titleWithStyleApplied,
      subtitle: subtitleWithStyleApplied,
      leading: leading,
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget get titleWithStyleApplied {
    return DefaultTextStyle.merge(
      style: const TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.bold,
      ),
      child: title,
    );
  }

  Widget? get subtitleWithStyleApplied {
    if (subtitle == null) {
      return null;
    }

    return DefaultTextStyle.merge(
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
      child: subtitle!,
    );
  }
}

class AppListTile extends StatelessWidget {
  final Widget title;

  final Widget? leading;
  final Widget? subtitle;
  final Widget? trailing;
  final GestureTapCallback? onTap;
  final bool selected;
  final bool dense;
  final bool isThreeLine;
  final EdgeInsetsGeometry? contentPadding;

  const AppListTile({
    Key? key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.contentPadding,
    this.selected = false,
    this.dense = false,
    this.isThreeLine = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      contentPadding: contentPadding,
      dense: dense,
      isThreeLine: isThreeLine,
      trailing:
          trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
      onTap: onTap,
      selected: selected,
    );
  }
}

class AppExpansionTile extends StatelessWidget {
  final Widget title;
  final Widget? leading;
  final Widget? subtitle;
  final List<Widget> children;

  final bool initiallyExpanded;

  final GestureLongPressCallback? onLongPress;

  const AppExpansionTile({
    Key? key,
    required this.title,
    required this.children,
    this.subtitle,
    this.leading,
    this.onLongPress,
    this.initiallyExpanded = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Material is needed for workaround https://github.com/flutter/flutter/issues/3782
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Material(
        color: Theme.of(context).dialogBackgroundColor,
        child: GestureDetector(
          onLongPress: onLongPress,
          child: ExpansionTile(
            initiallyExpanded: initiallyExpanded,
            leading: leading,
            title: DefaultTextStyle.merge(
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyText1!.color,
              ),
              child: title,
            ),
            subtitle: _getSubtitle(context),
            children: children,
          ),
        ),
      ),
    );
  }

  Widget? _getSubtitle(BuildContext context) {
    if (subtitle == null) {
      return null;
    }

    return DefaultTextStyle.merge(
      style: TextStyle(color: Theme.of(context).textTheme.caption!.color),
      child: subtitle!,
    );
  }
}

class AppCheckboxListTile extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  final Widget title;
  final Widget? subtitle;
  final bool dense;

  const AppCheckboxListTile({
    Key? key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.dense = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Material is needed for workaround https://github.com/flutter/flutter/issues/3782
    return Material(
      color: Theme.of(context).dialogBackgroundColor,
      child: CheckboxListTile(
        value: value,
        activeColor: Colors.teal,
        controlAffinity: ListTileControlAffinity.leading,
        onChanged: _onChanged,
        title: title,
        subtitle: subtitle,
        dense: dense,
      ),
    );
  }

  void _onChanged(bool? b) {
    onChanged(b ?? false);
  }
}

class ProductKindIcon extends StatelessWidget {
  final ProductKindEnum productKind;

  ProductKindIcon({required this.productKind})
      : super(key: ObjectKey(productKind));

  @override
  Widget build(BuildContext context) {
    final icon = (productKind == ProductKindEnum.drink)
        ? Icons.local_cafe
        : Icons.local_dining;

    return ExcludeSemantics(child: CircleAvatar(child: Icon(icon)));
  }
}

class EmptyStateContainer extends StatelessWidget {
  final String text;

  const EmptyStateContainer({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(
              'assets/empty.png',
              excludeFromSemantics: true,
            ),
          ),
          Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headline6,
          )
        ],
      ),
    );
  }
}

class AppBarTextButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;

  const AppBarTextButton({
    Key? key,
    required this.onPressed,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(primary: Colors.white),
      onPressed: onPressed,
      child: child,
    );
  }
}

class TextWithLeadingIcon extends StatelessWidget {
  final Text text;
  final IconData icon;
  final String? semanticLabel;

  const TextWithLeadingIcon({
    Key? key,
    required this.text,
    required this.icon,
    this.semanticLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Icon(
            icon,
            semanticLabel: semanticLabel,
            size: 14,
          ),
        ),
        text
      ],
    );
  }
}
