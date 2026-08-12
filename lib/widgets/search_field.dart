import 'package:flutter/material.dart';

import '../data/search_controller.dart';
import '../data/search_history_service.dart';
import '../theme/app_dimens.dart';

/// Search input shared by Home/Explore/etc.
///
/// Keeps the existing live-filter behavior: every keystroke updates
/// [searchQueryNotifier] (and the optional [onChanged]) immediately. Recent
/// searches are recorded only on submit ([onSubmitted] / return key) — history
/// is never touched per keystroke.
///
/// While focused and empty, an overlay dropdown of recent searches appears
/// under the field (Google-style, floating above page content). The overlay
/// uses a [CompositedTransformFollower] so it stays glued to the field even
/// while the page scrolls.
class SearchField extends StatefulWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const SearchField({
    super.key,
    this.hintText = 'Search...',
    this.onChanged,
    this.onSubmitted,
  });

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _link = LayerLink();
  final GlobalKey _fieldKey = GlobalKey();

  OverlayEntry? _overlayEntry;
  double _maxDropdownHeight = 320;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    SearchHistoryService.instance.listenable.addListener(_onHistoryChanged);
  }

  @override
  void dispose() {
    SearchHistoryService.instance.listenable.removeListener(_onHistoryChanged);
    _focusNode.removeListener(_onFocusChanged);
    _hideDropdown();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _maybeShowDropdown();
    } else {
      _hideDropdown();
    }
  }

  /// Dropdown must not stay open once history becomes empty (e.g. the "Clear
  /// all" button or removing the last entry).
  void _onHistoryChanged() {
    if (SearchHistoryService.instance.listenable.value.isEmpty) {
      Future.microtask(() {
        if (mounted) _hideDropdown();
      });
    }
  }

  bool get _textEmpty => _controller.text.trim().isEmpty;

  void _maybeShowDropdown() {
    if (!_focusNode.hasFocus) return;
    if (!_textEmpty) return;
    if (SearchHistoryService.instance.listenable.value.isEmpty) return;
    _showDropdown();
  }

  void _showDropdown() {
    final fieldContext = _fieldKey.currentContext;
    final overlay = Overlay.maybeOf(context);
    if (fieldContext == null || overlay == null || _overlayEntry != null) {
      return;
    }
    final box = fieldContext.findRenderObject() as RenderBox;
    final fieldTop = box.localToGlobal(Offset.zero).dy;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final availableBelow = screenHeight - fieldTop - box.size.height - 16;
    _maxDropdownHeight = availableBelow.clamp(96.0, 320.0).toDouble();

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return CompositedTransformFollower(
          link: _link,
          showWhenUnlinked: false,
          offset: Offset(0, box.size.height + 8),
          child: Material(
            elevation: 4,
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              width: box.size.width,
              child: ValueListenableBuilder<List<String>>(
                valueListenable: SearchHistoryService.instance.listenable,
                builder: (context, history, _) {
                  return ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: _maxDropdownHeight),
                    child: ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      children: [
                        for (final query in history) _historyRow(query),
                        if (history.isNotEmpty)
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.gutter,
                            ),
                            // leading: const Icon(
                            //   Icons.delete_sweep_outlined,
                            //   size: 18,
                            // ),
                            // title: const Text('Clear all'),
                            // onTap: () {
                            //   _hideDropdown();
                            //   SearchHistoryService.instance.clearHistory();
                            // },
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(_overlayEntry!);
  }

  void _hideDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _historyRow(String query) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
      leading: const Icon(Icons.history, size: 18),
      title: Text(query, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: IconButton(
        icon: const Icon(Icons.close, size: 16),
        tooltip: 'Remove from history',
        onPressed: () => SearchHistoryService.instance.removeOne(query),
      ),
      onTap: () => _selectHistory(query),
    );
  }

  void _handleChanged(String value) {
    searchQueryNotifier.value = value;
    widget.onChanged?.call(value);
    if (_textEmpty) {
      // Cleared the field while still focused: re-show recent searches.
      _maybeShowDropdown();
    } else {
      _hideDropdown();
    }
  }

  void _handleSubmitted(String value) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty) {
      SearchHistoryService.instance.addSearch(trimmed);
    }
    widget.onSubmitted?.call(value);
  }

  void _selectHistory(String query) {
    _hideDropdown();
    _controller.text = query;
    _controller.selection = TextSelection.collapsed(offset: query.length);
    // Same behavior as typing it in and submitting: record it as used (moves
    // to front), then trigger the live filter / callbacks.
    SearchHistoryService.instance.addSearch(query);
    searchQueryNotifier.value = query;
    widget.onChanged?.call(query);
    widget.onSubmitted?.call(query);
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: TextField(
        key: _fieldKey,
        controller: _controller,
        focusNode: _focusNode,
        textInputAction: TextInputAction.search,
        onChanged: _handleChanged,
        onSubmitted: _handleSubmitted,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            fontSize: 13,
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          filled: true,
          fillColor: Colors.black.withValues(alpha: 0.05),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.full),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
