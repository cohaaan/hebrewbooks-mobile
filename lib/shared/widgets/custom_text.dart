import 'package:flutter/material.dart';

/// A custom text widget that automatically sets the text direction
/// based on the text's language and aligns the text to the right.
class CustomText extends Text {
  /// Creates a text widget with automatic text direction detection.
  CustomText(
    super.data, {
    super.key,
    super.style,
    super.strutStyle,
    TextAlign? textAlign,
    super.locale,
    super.softWrap,
    super.overflow,
    super.textScaleFactor,
    super.maxLines,
    super.semanticsLabel,
    super.textWidthBasis,
    super.textHeightBehavior,
  }) : super(
          textAlign: textAlign ?? TextAlign.right,
          textDirection:
              _isEnglish(data) ? TextDirection.ltr : TextDirection.rtl,
        );

  /// Creates a custom text widget with left alignment.
  CustomText.left(
    super.data, {
    super.key,
    super.style,
    super.strutStyle,
    super.locale,
    super.softWrap,
    super.overflow,
    super.textScaleFactor,
    super.maxLines,
    super.semanticsLabel,
    super.textWidthBasis,
    super.textHeightBehavior,
  }) : super(
          textAlign: TextAlign.left,
          textDirection:
              _isEnglish(data) ? TextDirection.ltr : TextDirection.rtl,
        );

  static bool _isEnglish(String text) {
    return text.codeUnits.any(
      (c) => (c >= 65 && c <= 90) || (c >= 97 && c <= 122),
    );
  }
}
