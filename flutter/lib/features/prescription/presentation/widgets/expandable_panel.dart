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
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_borderRadius.value),
        boxShadow: [
          BoxShadow(
            color: widget.color.withOpacity(_isExpanded ? 0.2 : 0.1),
            blurRadius: _isExpanded ? 8 : 4,
            offset: Offset(0, _isExpanded ? 3 : 2),
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
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _isExpanded
                                  ? Colors.white.withOpacity(0.2)
                                  : widget.color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              widget.icon,
                              color: _isExpanded ? Colors.white : widget.color,
                              size: 20,
                            ),
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
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: _isExpanded
                                  ? Colors.white.withOpacity(0.2)
                                  : widget.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: RotationTransition(
                              turns: _iconTurns,
                              child: Icon(
                                Icons.keyboard_arrow_down,
                                color:
                                    _isExpanded ? Colors.white : widget.color,
                                size: 20,
                              ),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.content,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _handleTap,
                        icon: const Icon(Icons.keyboard_arrow_up, size: 18),
                        label: Text(
                          'بستن',
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.color,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          backgroundColor: widget.color.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
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
