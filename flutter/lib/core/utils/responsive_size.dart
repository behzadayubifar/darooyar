import 'package:flutter/material.dart';

/// A utility class that provides methods to calculate responsive sizes
/// based on the screen dimensions.
class ResponsiveSize {
  /// Private constructor to prevent instantiation
  ResponsiveSize._();

  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;
  static late double blockSizeHorizontal;
  static late double blockSizeVertical;
  static late double safeAreaHorizontal;
  static late double safeAreaVertical;
  static late double safeBlockHorizontal;
  static late double safeBlockVertical;
  static late double textScaleFactor;

  /// Initialize the responsive size utility with the given BuildContext
  static void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
    blockSizeHorizontal = screenWidth / 100;
    blockSizeVertical = screenHeight / 100;

    safeAreaHorizontal =
        _mediaQueryData.padding.left + _mediaQueryData.padding.right;
    safeAreaVertical =
        _mediaQueryData.padding.top + _mediaQueryData.padding.bottom;
    safeBlockHorizontal = (screenWidth - safeAreaHorizontal) / 100;
    safeBlockVertical = (screenHeight - safeAreaVertical) / 100;

    textScaleFactor = _mediaQueryData.textScaleFactor;
  }

  /// Returns a width percentage of the screen width
  static double width(double percentage) {
    return screenWidth * (percentage / 100);
  }

  /// Returns a height percentage of the screen height
  static double height(double percentage) {
    return screenHeight * (percentage / 100);
  }

  /// Returns a font size that scales with the screen size
  static double fontSize(double size) {
    // Base the font scaling on the smaller dimension to ensure readability
    double scaleFactor = (screenWidth < screenHeight)
        ? screenWidth / 375 // iPhone 8 width as baseline
        : screenHeight / 812; // iPhone 8 height as baseline

    // Ensure the scale factor is within reasonable bounds
    scaleFactor = scaleFactor.clamp(0.8, 1.2);

    return size * scaleFactor;
  }

  /// Returns a size that scales with the screen width
  static double horizontal(double size) {
    return blockSizeHorizontal * size;
  }

  /// Returns a size that scales with the screen height
  static double vertical(double size) {
    return blockSizeVertical * size;
  }

  /// Returns a padding that scales with the screen size
  static EdgeInsets padding(
      {double left = 0, double top = 0, double right = 0, double bottom = 0}) {
    return EdgeInsets.only(
      left: horizontal(left),
      top: vertical(top),
      right: horizontal(right),
      bottom: vertical(bottom),
    );
  }

  /// Returns a symmetric padding that scales with the screen size
  static EdgeInsets paddingSymmetric(
      {double horizontal = 0, double vertical = 0}) {
    return EdgeInsets.symmetric(
      horizontal: ResponsiveSize.horizontal(horizontal),
      vertical: ResponsiveSize.vertical(vertical),
    );
  }

  /// Returns a size that is responsive to the screen size
  static double size(double size) {
    // Use the smaller dimension to ensure elements are not too large on any device
    double scaleFactor = (screenWidth < screenHeight)
        ? screenWidth / 375 // iPhone 8 width as baseline
        : screenHeight / 812; // iPhone 8 height as baseline

    // Ensure the scale factor is within reasonable bounds
    scaleFactor = scaleFactor.clamp(0.8, 1.2);

    return size * scaleFactor;
  }

  /// Returns a BorderRadius that scales with the screen size
  static BorderRadius borderRadius(double radius) {
    return BorderRadius.circular(size(radius));
  }
}
