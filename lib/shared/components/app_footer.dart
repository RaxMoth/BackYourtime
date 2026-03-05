import 'package:flutter/material.dart';
import 'package:flutterbase/core/constants/app_constants.dart';
import 'package:flutterbase/core/theme/app_colors.dart';

/// Generic Footer Component
/// Can be used for navigation, actions, or additional information
class AppFooter extends StatelessWidget {
  final List<FooterItem> items;
  final int selectedIndex;
  final Function(int)? onItemTapped;
  final Color? backgroundColor;
  final Color? activeColor;
  final Color? inactiveColor;

  const AppFooter({
    Key? key,
    required this.items,
    this.selectedIndex = 0,
    this.onItemTapped,
    this.backgroundColor,
    this.activeColor,
    this.inactiveColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppConstants.footerHeight,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          items.length,
          (index) => Expanded(
            child: _FooterItemWidget(
              item: items[index],
              isSelected: index == selectedIndex,
              activeColor: activeColor ?? AppColors.primary,
              inactiveColor: inactiveColor ?? AppColors.grey,
              onTap: () => onItemTapped?.call(index),
            ),
          ),
        ),
      ),
    );
  }
}

/// Footer Item Model
class FooterItem {
  final IconData icon;
  final String label;
  final Widget? customIcon;

  FooterItem({
    required this.icon,
    required this.label,
    this.customIcon,
  });
}

/// Individual Footer Item Widget
class _FooterItemWidget extends StatelessWidget {
  final FooterItem item;
  final bool isSelected;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _FooterItemWidget({
    Key? key,
    required this.item,
    required this.isSelected,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          item.customIcon ??
              Icon(
                item.icon,
                color: isSelected ? activeColor : inactiveColor,
                size: 24,
              ),
          const SizedBox(height: 4),
          Text(
            item.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isSelected ? activeColor : inactiveColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Simple Footer with Text
class SimpleFooter extends StatelessWidget {
  final String? text;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final Alignment alignment;

  const SimpleFooter({
    Key? key,
    this.text,
    this.actions,
    this.backgroundColor,
    this.alignment = Alignment.center,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppConstants.footerHeight,
      color: backgroundColor ?? AppColors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (text != null)
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Text(
                text!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          if (actions != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
              child: Row(
                children: actions!,
              ),
            ),
        ],
      ),
    );
  }
}
