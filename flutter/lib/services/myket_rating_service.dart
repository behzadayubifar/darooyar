import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:darooyar/widgets/myket_rating_dialog.dart';

/// A service that manages when to show the rating dialog
class MyketRatingService {
  /// The key for storing the launch count in shared preferences
  static const String _launchCountKey = 'myket_rating_launch_count';

  /// The key for storing whether the user has rated the app
  static const String _hasRatedKey = 'myket_rating_has_rated';

  /// The key for storing the last prompt date
  static const String _lastPromptDateKey = 'myket_rating_last_prompt_date';

  /// The minimum number of launches before showing the rating dialog
  final int minLaunchCount;

  /// The minimum number of days between rating prompts
  final int daysBeforeReminding;

  /// Creates a new [MyketRatingService]
  MyketRatingService({
    this.minLaunchCount = 5,
    this.daysBeforeReminding = 10,
  });

  /// Increments the launch count and checks if the rating dialog should be shown
  Future<bool> shouldShowRatingDialog() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if the user has already rated the app
    final hasRated = prefs.getBool(_hasRatedKey) ?? false;
    if (hasRated) {
      return false;
    }

    // Increment the launch count
    final launchCount = (prefs.getInt(_launchCountKey) ?? 0) + 1;
    await prefs.setInt(_launchCountKey, launchCount);

    // Check if we've shown the dialog recently
    final lastPromptDateString = prefs.getString(_lastPromptDateKey);
    if (lastPromptDateString != null) {
      final lastPromptDate = DateTime.parse(lastPromptDateString);
      final daysSinceLastPrompt =
          DateTime.now().difference(lastPromptDate).inDays;

      // If it's been less than daysBeforeReminding days since the last prompt, don't show
      if (daysSinceLastPrompt < daysBeforeReminding) {
        return false;
      }

      // If it's been more than daysBeforeReminding days, show the dialog again
      return true;
    }

    // Show the dialog if the app has been launched enough times
    return launchCount >= minLaunchCount;
  }

  /// Shows the rating dialog if conditions are met
  Future<void> checkAndShowRatingDialog(BuildContext context) async {
    if (await shouldShowRatingDialog()) {
      // Store the current date as the last prompt date
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _lastPromptDateKey, DateTime.now().toIso8601String());

      // Show the dialog
      final result = await MyketRatingDialog.show(context);

      // If the user clicked the positive button, mark as rated
      if (result == true) {
        await prefs.setBool(_hasRatedKey, true);
      }
    }
  }

  /// Marks the app as rated
  Future<void> markAsRated() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasRatedKey, true);
  }

  /// Resets the rating service state
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_launchCountKey);
    await prefs.remove(_hasRatedKey);
    await prefs.remove(_lastPromptDateKey);
  }

  /// Checks if the user has already rated the app
  Future<bool> hasUserRated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasRatedKey) ?? false;
  }
}
