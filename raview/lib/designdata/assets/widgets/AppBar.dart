import 'package:flutter/material.dart';
import 'package:raview/designdata/auto/isdarkmode.dart';


class AppbarCommon extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final Widget? action;
  final Color ? backgroundColor;
  final bool hideBack;
  const AppbarCommon({this.title, this.hideBack = false, this.action, this.backgroundColor,super.key, });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor ?? Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: title ?? const Text(""),
      actions: [
        action ?? Container()
      ],
      leading: hideBack ? null : IconButton(
        icon: Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: context.isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.arrow_back_ios_new,
            size: 15,
            color: context.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
