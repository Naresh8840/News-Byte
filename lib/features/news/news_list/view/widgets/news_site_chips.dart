import 'package:flutter/material.dart';

import '../../../../../core/utils/color_resource.dart';
import '../../../../../core/utils/string_resource.dart';
import '../../../../../core/widgets/custom_text.dart';

class NewsSiteChips extends StatelessWidget {
  final List<String> sites;
  final String? selected;
  final ValueChanged<String?> onSelected;

  const NewsSiteChips({
    super.key,
    required this.sites,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (sites.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: sites.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _ChipItem(
              label: StringResource.all,
              isSelected: selected == null,
              onTap: () => onSelected(null),
            );
          }
          final site = sites[index - 1];
          return _ChipItem(
            label: site,
            isSelected: selected == site,
            onTap: () => onSelected(site),
          );
        },
      ),
    );
  }
}

class _ChipItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChipItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ChoiceChip(
      showCheckmark: false,
      label: CustomText(
        label,
        style: TextStyle(
          color: isSelected
              ? Colors.white
              : isDark
                  ? Colors.white70
                  : Colors.black87,
          fontSize: 13,
        ),
      ),
      selected: isSelected,
      backgroundColor:
          isDark ? ColorResource.color_2C2C2C : ColorResource.color_E8E8E8,
      selectedColor:
          isDark ? ColorResource.color_3949AB : ColorResource.color_1A237E,
      side: isDark ? BorderSide.none : BorderSide.none,
      onSelected: (_) => onTap(),
    );
  }
}
