import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:raview/designdata/assets/vector/assetsSnack.dart';

class AwesomeSnackbarContent extends StatelessWidget {

  final String title;

  final String message;

  /// `optional` color of the SnackBar/MaterialBanner body
  final Color? color;


  final ContentType contentType;
  /// if you want to use this in materialBanner
  final bool inMaterialBanner;

  /// if you want to customize the font style of the title
  final TextStyle? titleTextStyle;

  /// if you want to customize the font style of the message
  final TextStyle? messageTextStyle;

  const AwesomeSnackbarContent({
    Key? key,
    required this.color,
    this.titleTextStyle,
    this.messageTextStyle,
    required this.contentType,
    required this.title,
    required this.message,
    this.inMaterialBanner = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    final size = MediaQuery.of(context).size;

    // screen dimensions
    final isMobile = size.width <= 768;
    final isTablet = size.width > 768 && size.width <= 992;

    /// for reflecting different color shades in the SnackBar
    final hsl = HSLColor.fromColor(color!);
    final hslDark = hsl.withLightness((hsl.lightness - 0.1).clamp(0.0, 1.0));

    var horizontalPadding = 0.0;
    var leftSpace = size.width * 0.12;
    final rightSpace = size.width * 0.12;

    if (isMobile) {
      horizontalPadding = size.width * 0.01;
    } else if (isTablet) {
      leftSpace = size.width * 0.05;
      horizontalPadding = size.width * 0.2;
    } else {
      leftSpace = size.width * 0.05;
      horizontalPadding = size.width * 0.3;
    }

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
      ),
      height: isMobile ? 100 : 130,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          /// background container
          Container(
            width: size.width,
            decoration: BoxDecoration(
              color: color ,
              borderRadius: BorderRadius.circular(20),
            ),
          ),

          /// Splash SVG asset
          Positioned(
            bottom: 0,
            left: !isRTL ? 0 : null,
            right: isRTL ? 0 : null,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.rotationY(isRTL ? math.pi : math.pi * 2),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                ),
                child: SvgPicture.asset(
                  AssetsPath.bubbles,
                  height: 50,
                  width: 50,
                  colorFilter:
                      _getColorFilter(hslDark.toColor(), ui.BlendMode.srcIn),
                ),
              ),
            ),
          ),

          // Bubble Icon
          Positioned(
            top: -size.height * 0.015,
            left: !isRTL
                ? leftSpace -
                    8 -
                    (isMobile ? size.width * 0.075 : size.width * 0.035)
                : null,
            right: isRTL
                ? rightSpace -
                    8 -
                    (isMobile ? size.width * 0.075 : size.width * 0.035)
                : null,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SvgPicture.asset(
                  AssetsPath.back,
                  height: 45,
                  colorFilter:
                      _getColorFilter(hslDark.toColor(), ui.BlendMode.srcIn),
                ),
                Positioned(
                  top: size.height * 0.015,
                  child: SvgPicture.asset(
                    assetSVG(contentType),
                    height: 18,
                  ),
                ),
              ],
            ),
          ),

          /// content
          Positioned.fill(
            left: isRTL ? size.width * 0.03 : leftSpace,
            right: isRTL ? rightSpace : size.width * 0.03,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    /// `title` parameter
                    Expanded(
                      flex: 3,
                      child: Text(
                        title,
                        style: titleTextStyle ??
                            TextStyle(
                              fontSize: !isMobile ? 22 : 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        if (inMaterialBanner) {
                          ScaffoldMessenger.of(context)
                              .hideCurrentMaterialBanner();
                          return;
                        }
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      },
                      icon: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: size.height * 0.022,
                      ),
                    ),
                  ],
                ),

                /// `message` body text parameter
                Expanded(
                  child: Text(
                    message,
                    style: messageTextStyle ??
                        TextStyle(
                          fontSize: isMobile ? 14 : 16,
                          color: Colors.white,
                        ),
                    maxLines: isMobile ? 2 : 3,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 5),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Reflecting proper icon based on the contentType
  String assetSVG(ContentType contentType) {
    switch (contentType) {
      case ContentType.failure:

        /// failure will show `CROSS`
        return AssetsPath.failure;
      case ContentType.success:

        /// success will show `CHECK`
        return AssetsPath.success;
      case ContentType.warning:

        /// warning will show `EXCLAMATION`
        return AssetsPath.warning;
      case ContentType.help:

        /// help will show `QUESTION MARK`
        return AssetsPath.help;
      default:
        return AssetsPath.failure;
    }
  }

  static ColorFilter? _getColorFilter(
    ui.Color? color,
    ui.BlendMode colorBlendMode,
  ) =>
      color == null ? null : ui.ColorFilter.mode(color, colorBlendMode);
}

class ContentType {
   final String message;

  /// color is optional, if provided null then `DefaultColors` will be used
  final Color? color;

  const ContentType(this.message, [this.color]);

  static const ContentType help = ContentType('help', null);
  static const ContentType failure =
      ContentType('failure', null);
  static const ContentType success =
      ContentType('success', null);
  static const ContentType warning =
      ContentType('warning', null);
}
