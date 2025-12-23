import 'package:flutter/material.dart';
import 'package:hebrewbooks/shared/category_metadata.dart';
import 'package:hebrewbooks/shared/widgets/custom_text.dart';

/// A card widget for displaying a category with curved bracket decoration.
class CategoryCard extends StatelessWidget {
  const CategoryCard({
    required this.metadata,
    required this.itemCount,
    required this.onTap,
    required this.isRTL,
    super.key,
  });

  final CategoryMetadata metadata;
  final int itemCount;
  final VoidCallback onTap;
  final bool isRTL;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CustomPaint(
            painter: CurvedBracketPainter(
              color: metadata.color,
              isRTL: isRTL,
            ),
            child: Padding(
              padding: EdgeInsets.only(
                left: isRTL ? 16 : 20,
                right: isRTL ? 20 : 16,
                top: 16,
                bottom: 16,
              ),
              child: Column(
                crossAxisAlignment: isRTL
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomText(
                    isRTL ? metadata.hebrewName : metadata.englishName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                  ),
                  const SizedBox(height: 6),
                  CustomText(
                    isRTL
                        ? metadata.hebrewDescription
                        : metadata.englishDescription,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                          height: 1.3,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isRTL) ...[
                        const Icon(
                          Icons.arrow_forward,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                      ],
                      CustomText(
                        isRTL
                            ? 'פריטים $itemCount'
                            : '$itemCount items',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[500],
                            ),
                      ),
                      if (isRTL) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_back,
                          size: 14,
                          color: Colors.grey,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter for the curved bracket decoration.
class CurvedBracketPainter extends CustomPainter {
  CurvedBracketPainter({
    required this.color,
    required this.isRTL,
  });

  final Color color;
  final bool isRTL;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    const bracketWidth = 4.0;
    const curveDepth = 16.0;

    if (isRTL) {
      // Draw bracket on the right side
      path.moveTo(size.width, 0);
      path.lineTo(size.width - bracketWidth, 0);
      path.quadraticBezierTo(
        size.width - bracketWidth - curveDepth,
        size.height / 2,
        size.width - bracketWidth,
        size.height,
      );
      path.lineTo(size.width, size.height);
      path.quadraticBezierTo(
        size.width - curveDepth,
        size.height / 2,
        size.width,
        0,
      );
    } else {
      // Draw bracket on the left side
      path.moveTo(0, 0);
      path.lineTo(bracketWidth, 0);
      path.quadraticBezierTo(
        bracketWidth + curveDepth,
        size.height / 2,
        bracketWidth,
        size.height,
      );
      path.lineTo(0, size.height);
      path.quadraticBezierTo(
        curveDepth,
        size.height / 2,
        0,
        0,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CurvedBracketPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isRTL != isRTL;
  }
}
