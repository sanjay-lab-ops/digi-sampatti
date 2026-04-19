import 'package:flutter/material.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';

/// Searchable bottom-sheet picker.
/// Shows a list of [items] with a search field. Returns the selected value.
Future<T?> showSearchablePicker<T>({
  required BuildContext context,
  required String title,
  required List<T> items,
  required String Function(T) label,
  T? selected,
  String hint = 'Search...',
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SearchablePickerSheet<T>(
      title: title,
      items: items,
      label: label,
      selected: selected,
      hint: hint,
    ),
  );
}

class _SearchablePickerSheet<T> extends StatefulWidget {
  final String title, hint;
  final List<T> items;
  final String Function(T) label;
  final T? selected;
  const _SearchablePickerSheet({
    required this.title, required this.items, required this.label,
    this.selected, required this.hint,
  });

  @override
  State<_SearchablePickerSheet<T>> createState() => _SearchablePickerSheetState<T>();
}

class _SearchablePickerSheetState<T> extends State<_SearchablePickerSheet<T>> {
  final _ctrl = TextEditingController();
  String _query = '';

  List<T> get _filtered {
    if (_query.isEmpty) return widget.items;
    final q = _query.toLowerCase();
    return widget.items.where((item) => widget.label(item).toLowerCase().contains(q)).toList();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (_, scroll) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(height: 10),
              TextField(
                controller: _ctrl,
                autofocus: true,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  prefixIcon: const Icon(Icons.search, size: 18),
                  suffixIcon: _query.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear, size: 16),
                        onPressed: () { _ctrl.clear(); setState(() => _query = ''); })
                    : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
            ]),
          ),
          if (filtered.isEmpty)
            Expanded(child: Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.search_off, size: 36, color: AppColors.textLight),
                const SizedBox(height: 8),
                Text('No results for "$_query"',
                  style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
              ]),
            ))
          else
            Expanded(child: ListView.separated(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (_, i) {
                final item = filtered[i];
                final lbl = widget.label(item);
                final isSelected = widget.selected != null && widget.label(widget.selected as T) == lbl;
                return ListTile(
                  title: Text(lbl, style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.primary : AppColors.textDark,
                  )),
                  trailing: isSelected
                    ? const Icon(Icons.check_circle, color: AppColors.primary, size: 18)
                    : null,
                  onTap: () => Navigator.pop(context, item),
                );
              },
            )),
        ]),
      ),
    );
  }
}
