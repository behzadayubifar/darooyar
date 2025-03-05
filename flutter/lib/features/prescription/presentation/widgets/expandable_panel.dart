import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_size.dart';

class ExpandablePanel extends StatefulWidget {
  final String title;
  final String content;
  final Color color;
  final IconData icon;
  final bool initiallyExpanded;

  const ExpandablePanel({
    Key? key,
    required this.title,
    required this.content,
    required this.color,
    required this.icon,
    this.initiallyExpanded = false,
  }) : super(key: key);

  @override
  State<ExpandablePanel> createState() => _ExpandablePanelState();
}

class _ExpandablePanelState extends State<ExpandablePanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _iconTurns;
  late Animation<double> _heightFactor;
  late Animation<double> _borderRadius;
  late Animation<Color?> _headerColor;
  late Animation<Color?> _iconColor;
  late Animation<Color?> _titleColor;
  late Animation<double> _elevation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _heightFactor = _controller.drive(CurveTween(curve: Curves.easeInOut));
    _iconTurns = _controller.drive(Tween<double>(begin: 0.0, end: 0.5)
        .chain(CurveTween(curve: Curves.easeInOut)));
    _borderRadius = _controller.drive(Tween<double>(begin: 16.0, end: 16.0)
        .chain(CurveTween(curve: Curves.easeInOut)));
    _elevation = _controller.drive(Tween<double>(begin: 2.0, end: 4.0)
        .chain(CurveTween(curve: Curves.easeInOut)));

    _headerColor = _controller.drive(ColorTween(
      begin: widget.color.withOpacity(0.1),
      end: widget.color,
    ).chain(CurveTween(curve: Curves.easeInOut)));

    _iconColor = _controller.drive(ColorTween(
      begin: widget.color,
      end: Colors.white,
    ).chain(CurveTween(curve: Curves.easeInOut)));

    _titleColor = _controller.drive(ColorTween(
      begin: widget.color,
      end: Colors.white,
    ).chain(CurveTween(curve: Curves.easeInOut)));

    _isExpanded = PageStorage.of(context).readState(context) as bool? ??
        widget.initiallyExpanded;
    if (_isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
      PageStorage.of(context).writeState(context, _isExpanded);
    });
  }

  Widget _buildChildren(BuildContext context, Widget? child) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: EdgeInsets.symmetric(
          vertical: ResponsiveSize.vertical(1),
          horizontal: ResponsiveSize.horizontal(0.5)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_borderRadius.value),
        boxShadow: [
          BoxShadow(
            color: widget.color.withOpacity(_isExpanded ? 0.2 : 0.1),
            blurRadius:
                _isExpanded ? ResponsiveSize.size(8) : ResponsiveSize.size(4),
            offset: Offset(0,
                _isExpanded ? ResponsiveSize.size(3) : ResponsiveSize.size(2)),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(_borderRadius.value),
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            InkWell(
              onTap: _handleTap,
              splashColor: widget.color.withOpacity(0.3),
              highlightColor: widget.color.withOpacity(0.2),
              child: AnimatedBuilder(
                animation: _controller.view,
                builder: (BuildContext context, Widget? _) {
                  return Container(
                    decoration: BoxDecoration(
                      color: _isExpanded ? widget.color : _headerColor.value,
                      borderRadius: _isExpanded
                          ? BorderRadius.only(
                              topLeft: Radius.circular(_borderRadius.value),
                              topRight: Radius.circular(_borderRadius.value),
                            )
                          : BorderRadius.circular(_borderRadius.value),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: ResponsiveSize.vertical(1.5),
                          horizontal: ResponsiveSize.horizontal(2.5)),
                      child: LayoutBuilder(builder: (context, constraints) {
                        final bool isNarrow =
                            constraints.maxWidth < ResponsiveSize.width(25);
                        final double iconSize = isNarrow
                            ? ResponsiveSize.size(18)
                            : ResponsiveSize.size(22);
                        final double iconInnerSize = isNarrow
                            ? ResponsiveSize.size(12)
                            : ResponsiveSize.size(14);
                        final double spacing = isNarrow
                            ? ResponsiveSize.size(4)
                            : ResponsiveSize.size(8);

                        return Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: spacing,
                          children: <Widget>[
                            SizedBox(
                              width: iconSize,
                              height: iconSize,
                              child: Container(
                                padding: EdgeInsets.all(isNarrow
                                    ? ResponsiveSize.size(2)
                                    : ResponsiveSize.size(3)),
                                decoration: BoxDecoration(
                                  color: _isExpanded
                                      ? Colors.white.withOpacity(0.2)
                                      : widget.color.withOpacity(0.2),
                                  borderRadius: ResponsiveSize.borderRadius(4),
                                ),
                                child: Icon(
                                  widget.icon,
                                  color:
                                      _isExpanded ? Colors.white : widget.color,
                                  size: iconInnerSize,
                                ),
                              ),
                            ),
                            Container(
                              constraints: BoxConstraints(
                                maxWidth: constraints.maxWidth >
                                        (iconSize * 2 +
                                            spacing * 2 +
                                            ResponsiveSize.size(20))
                                    ? constraints.maxWidth -
                                        (iconSize * 2) -
                                        (spacing * 2) -
                                        ResponsiveSize.size(20)
                                    : constraints.maxWidth * 0.5,
                              ),
                              child: Text(
                                widget.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isNarrow
                                      ? ResponsiveSize.fontSize(12)
                                      : (constraints.maxWidth <
                                              ResponsiveSize.width(40)
                                          ? ResponsiveSize.fontSize(14)
                                          : ResponsiveSize.fontSize(15)),
                                  color:
                                      _isExpanded ? Colors.white : widget.color,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            SizedBox(
                              width: iconSize,
                              height: iconSize,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _isExpanded
                                      ? Colors.white.withOpacity(0.2)
                                      : widget.color.withOpacity(0.1),
                                  borderRadius: ResponsiveSize.borderRadius(4),
                                ),
                                padding: EdgeInsets.all(isNarrow
                                    ? ResponsiveSize.size(2)
                                    : ResponsiveSize.size(3)),
                                child: RotationTransition(
                                  turns: _iconTurns,
                                  child: Icon(
                                    Icons.keyboard_arrow_down,
                                    color: _isExpanded
                                        ? Colors.white
                                        : widget.color,
                                    size: iconInnerSize,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  );
                },
              ),
            ),
            ClipRect(
              child: Align(
                alignment: Alignment.centerLeft,
                heightFactor: _heightFactor.value,
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool closed = !_isExpanded && _controller.isDismissed;

    return AnimatedBuilder(
      animation: _controller.view,
      builder: _buildChildren,
      child: closed
          ? null
          : Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(_borderRadius.value),
                  bottomRight: Radius.circular(_borderRadius.value),
                ),
                border: Border.all(
                  color: widget.color.withOpacity(0.2),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(ResponsiveSize.size(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.content,
                      style: TextStyle(
                        fontSize: ResponsiveSize.fontSize(15),
                        height: 1.5,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    SizedBox(height: ResponsiveSize.vertical(1)),
                    Container(
                      alignment: Alignment.centerRight,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: ResponsiveSize.width(50),
                        ),
                        child: TextButton.icon(
                          onPressed: _handleTap,
                          icon: Icon(Icons.keyboard_arrow_up,
                              size: ResponsiveSize.size(16)),
                          label: Text(
                            'بستن',
                            style: TextStyle(
                              fontSize: ResponsiveSize.fontSize(12),
                              color: widget.color,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: ResponsiveSize.horizontal(3),
                              vertical: ResponsiveSize.vertical(0.5),
                            ),
                            backgroundColor: widget.color.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: ResponsiveSize.borderRadius(8),
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
