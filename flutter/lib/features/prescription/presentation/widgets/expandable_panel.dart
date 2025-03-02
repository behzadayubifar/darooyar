import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

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
    _borderRadius = _controller.drive(Tween<double>(begin: 12.0, end: 12.0)
        .chain(CurveTween(curve: Curves.easeInOut)));

    _headerColor = _controller.drive(ColorTween(
      begin: widget.color.withOpacity(0.1),
      end: widget.color.withOpacity(0.2),
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_borderRadius.value),
        boxShadow: [
          BoxShadow(
            color: widget.color.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(_borderRadius.value),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            InkWell(
              onTap: _handleTap,
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
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            widget.icon,
                            color: _isExpanded ? Colors.white : widget.color,
                            size: 24,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              widget.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color:
                                    _isExpanded ? Colors.white : widget.color,
                              ),
                            ),
                          ),
                          RotationTransition(
                            turns: _iconTurns,
                            child: Icon(
                              Icons.keyboard_arrow_down,
                              color: _isExpanded ? Colors.white : widget.color,
                            ),
                          ),
                        ],
                      ),
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
                padding: const EdgeInsets.all(16),
                child: Text(
                  widget.content,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ),
            ),
    );
  }
}
