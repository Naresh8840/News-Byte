import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/color_resource.dart';
import '../../../../../core/utils/string_resource.dart';
import '../../view_model/news_list_cubit.dart';

class NewsSearchBar extends StatelessWidget {
  final TextEditingController controller;

  const NewsSearchBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      onChanged: (value) {
        context.read<NewsListCubit>().onSearchChanged(value);
      },
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: StringResource.searchHint,
        prefixIcon: const Icon(Icons.search, size: 20),
        filled: true,
        fillColor:
            isDark ? ColorResource.color_2C2C2C : ColorResource.color_EEEEEE,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, child) {
            if (value.text.isEmpty) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () {
                controller.clear();
                context.read<NewsListCubit>().onSearchChanged('');
              },
            );
          },
        ),
      ),
    );
  }
}
