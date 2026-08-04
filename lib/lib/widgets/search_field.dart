import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';

class SearchField extends StatelessWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;

  const SearchField({super.key, this.hintText = 'Search...', this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: Theme.of(
            context,
          ).colorScheme.onSurfaceVariant.withOpacity(0.7),
          fontSize: 13,
        ),
        prefixIcon: Icon(
          Icons.search,
          size: 20,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        filled: true,
        fillColor: Colors.black.withOpacity(0.05),
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
