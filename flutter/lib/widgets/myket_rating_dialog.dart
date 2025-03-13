import 'package:flutter/material.dart';
import 'package:darooyar/utils/myket_utils.dart';

/// A dialog that prompts the user to rate the app on Myket
class MyketRatingDialog extends StatelessWidget {
  /// The title of the dialog
  final String title;

  /// The message to display in the dialog
  final String message;

  /// The text for the positive button
  final String positiveButtonText;

  /// The text for the negative button
  final String negativeButtonText;

  /// Creates a new [MyketRatingDialog]
  const MyketRatingDialog({
    Key? key,
    this.title = 'نظر شما برای ما مهم است',
    this.message =
        'اگر از برنامه راضی هستید، لطفا با دادن امتیاز و نظر در مایکت از ما حمایت کنید.',
    this.positiveButtonText = 'امتیاز دهید',
    this.negativeButtonText = 'بعدا',
  }) : super(key: key);

  /// Shows the rating dialog
  static Future<bool?> show(
    BuildContext context, {
    String title = 'نظر شما برای ما مهم است',
    String message =
        'اگر از برنامه راضی هستید، لطفا با دادن امتیاز و نظر در مایکت از ما حمایت کنید.',
    String positiveButtonText = 'امتیاز دهید',
    String negativeButtonText = 'بعدا',
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => MyketRatingDialog(
        title: title,
        message: message,
        positiveButtonText: positiveButtonText,
        negativeButtonText: negativeButtonText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: Text(negativeButtonText),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(true);
            MyketUtils.openRatingPage();
          },
          child: Text(positiveButtonText),
        ),
      ],
    );
  }
}
