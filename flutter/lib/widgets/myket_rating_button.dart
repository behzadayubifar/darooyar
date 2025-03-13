import 'package:flutter/material.dart';
import 'package:darooyar/utils/myket_utils.dart';

/// A button widget that opens the Myket rating page when pressed
class MyketRatingButton extends StatelessWidget {
  /// The text to display on the button
  final String text;

  /// The icon to display on the button
  final IconData icon;

  /// The color of the button
  final Color? color;

  /// The text style for the button text
  final TextStyle? textStyle;

  /// Creates a new [MyketRatingButton]
  const MyketRatingButton({
    Key? key,
    this.text = 'نظر دهید و امتیاز دهید',
    this.icon = Icons.star,
    this.color,
    this.textStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        MyketUtils.openRatingPage();
      },
      icon: Icon(icon),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        textStyle: textStyle,
      ),
    );
  }
}

/// A simple icon button that opens the Myket rating page when pressed
class MyketRatingIconButton extends StatelessWidget {
  /// The icon to display on the button
  final IconData icon;

  /// The color of the icon
  final Color? color;

  /// The size of the icon
  final double size;

  /// Creates a new [MyketRatingIconButton]
  const MyketRatingIconButton({
    Key? key,
    this.icon = Icons.star,
    this.color,
    this.size = 24.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        MyketUtils.openRatingPage();
      },
      icon: Icon(
        icon,
        color: color,
        size: size,
      ),
      tooltip: 'نظر دهید و امتیاز دهید',
    );
  }
}
