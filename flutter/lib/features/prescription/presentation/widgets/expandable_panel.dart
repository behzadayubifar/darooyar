import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_size.dart';

class ExpandablePanel extends StatefulWidget {
  final String title;
  final String content;
  final Color color;
  final IconData icon;
  final bool initiallyExpanded;
  final double? width;

  const ExpandablePanel({
    Key? key,
    required this.title,
    required this.content,
    required this.color,
    required this.icon,
    this.initiallyExpanded = false,
    this.width,
  }) : super(key: key);

  @override
  State<ExpandablePanel> createState() => _ExpandablePanelState();
}

class _ExpandablePanelState extends State<ExpandablePanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _iconTurns;
  late Animation<double> _heightFactor;
  bool _isExpanded = false;
  final GlobalKey _panelKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _heightFactor = _controller.drive(CurveTween(curve: Curves.easeIn));
    _iconTurns = _controller.drive(Tween<double>(begin: 0.0, end: 0.5)
        .chain(CurveTween(curve: Curves.easeIn)));

    final savedState =
        PageStorage.of(context).readState(context, identifier: widget.title);
    _isExpanded = savedState ?? widget.initiallyExpanded;

    if (_isExpanded) _controller.value = 1.0;
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
      PageStorage.of(context)
          .writeState(context, _isExpanded, identifier: widget.title);
    });
  }

  Widget _buildChildren(BuildContext context, Widget? child) {
    return Container(
      width: widget.width,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.symmetric(
            vertical: ResponsiveSize.vertical(1),
            horizontal: ResponsiveSize.horizontal(0.5)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(_isExpanded ? 0.2 : 0.1),
              blurRadius:
                  _isExpanded ? ResponsiveSize.size(8) : ResponsiveSize.size(4),
              offset: Offset(
                  0,
                  _isExpanded
                      ? ResponsiveSize.size(3)
                      : ResponsiveSize.size(2)),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16.0),
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
                        color: _isExpanded
                            ? widget.color
                            : widget.color.withOpacity(0.1),
                        borderRadius: _isExpanded
                            ? BorderRadius.only(
                                topLeft: Radius.circular(16.0),
                                topRight: Radius.circular(16.0),
                              )
                            : BorderRadius.circular(16.0),
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

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                    borderRadius:
                                        ResponsiveSize.borderRadius(4),
                                  ),
                                  child: Icon(
                                    widget.icon,
                                    color: _isExpanded
                                        ? Colors.white
                                        : widget.color,
                                    size: iconInnerSize,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: spacing),
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
                                      color: _isExpanded
                                          ? Colors.white
                                          : widget.color,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
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
                                    borderRadius:
                                        ResponsiveSize.borderRadius(4),
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
                  bottomLeft: Radius.circular(16.0),
                  bottomRight: Radius.circular(16.0),
                ),
                border: Border.all(
                  color: widget.color.withOpacity(0.2),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    ResponsiveSize.size(16),
                    ResponsiveSize.size(16),
                    ResponsiveSize.size(16),
                    ResponsiveSize.size(8)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      widget.content,
                      style: TextStyle(
                        fontSize: ResponsiveSize.fontSize(15),
                        height: 1.5,
                        color: AppTheme.textPrimaryColor,
                      ),
                      textAlign: TextAlign.justify,
                      selectionControls: MaterialTextSelectionControls(),
                      contextMenuBuilder: (context, editableTextState) {
                        return AdaptiveTextSelectionToolbar.editableText(
                          editableTextState: editableTextState,
                        );
                      },
                      textScaleFactor: 1.0,
                      maxLines: null,
                      textDirection: TextDirection.rtl,
                      showCursor: true,
                      enableInteractiveSelection: true,
                    ),
                    Container(
                      alignment: Alignment.centerRight,
                      margin: EdgeInsets.only(top: ResponsiveSize.vertical(4)),
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
