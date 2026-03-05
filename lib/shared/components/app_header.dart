import 'package:flutter/material.dart';
import 'package:flutterbase/core/constants/app_constants.dart';
import 'package:flutterbase/core/theme/app_colors.dart';

/// Generic Header Component
/// Can be customized with title, leading, trailing actions, etc.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? leading;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final VoidCallback? onLeadingPressed;
  final double elevation;
  final bool centerTitle;
  final PreferredSizeWidget? bottom;

  const AppHeader({
    Key? key,
    this.title,
    this.leading,
    this.actions,
    this.backgroundColor,
    this.foregroundColor,
    this.onLeadingPressed,
    this.elevation = 0,
    this.centerTitle = true,
    this.bottom,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title != null
          ? Text(
              title!,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: foregroundColor ?? AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
            )
          : null,
      leading: leading ??
          (Navigator.of(context).canPop()
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: onLeadingPressed ?? () => Navigator.pop(context),
                  color: foregroundColor ?? AppColors.white,
                )
              : null),
      actions: actions,
      backgroundColor: backgroundColor ?? AppColors.primary,
      foregroundColor: foregroundColor ?? AppColors.white,
      elevation: elevation,
      centerTitle: centerTitle,
      bottom: bottom,
      toolbarHeight: AppConstants.headerHeight,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        AppConstants.headerHeight + (bottom?.preferredSize.height ?? 0),
      );
}

/// Header with search field
class SearchHeader extends StatefulWidget implements PreferredSizeWidget {
  final String? hintText;
  final Function(String)? onSearch;
  final VoidCallback? onClose;
  final String? initialValue;
  final Color? backgroundColor;

  const SearchHeader({
    Key? key,
    this.hintText = 'Search...',
    this.onSearch,
    this.onClose,
    this.initialValue,
    this.backgroundColor,
  }) : super(key: key);

  @override
  State<SearchHeader> createState() => _SearchHeaderState();

  @override
  Size get preferredSize => const Size.fromHeight(AppConstants.headerHeight);
}

class _SearchHeaderState extends State<SearchHeader> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: widget.backgroundColor ?? AppColors.primary,
      title: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: widget.hintText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: AppColors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    widget.onSearch?.call('');
                    setState(() {});
                  },
                )
              : null,
        ),
        onChanged: (value) {
          widget.onSearch?.call(value);
          setState(() {});
        },
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: widget.onClose,
      ),
    );
  }
}
