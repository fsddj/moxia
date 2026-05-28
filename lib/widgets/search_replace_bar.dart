import 'package:flutter/material.dart';
import '../services/search_service.dart';

class SearchReplaceBar extends StatefulWidget {
  final String? currentChapterContent;
  final int matchCount;
  final int currentMatchIndex;
  final SearchScope scope;
  final bool showReplace;
  final void Function(String query) onSearch;
  final void Function(SearchScope scope) onScopeChanged;
  final void Function() onNextMatch;
  final void Function() onPrevMatch;
  final void Function(String replacement) onReplace;
  final void Function(String replacement) onReplaceAll;
  final void Function() onToggleReplace;
  final void Function() onClose;

  const SearchReplaceBar({
    super.key,
    this.currentChapterContent,
    required this.matchCount,
    required this.currentMatchIndex,
    required this.scope,
    required this.showReplace,
    required this.onSearch,
    required this.onScopeChanged,
    required this.onNextMatch,
    required this.onPrevMatch,
    required this.onReplace,
    required this.onReplaceAll,
    required this.onToggleReplace,
    required this.onClose,
  });

  @override
  State<SearchReplaceBar> createState() => _SearchReplaceBarState();
}

class _SearchReplaceBarState extends State<SearchReplaceBar> {
  final _searchController = TextEditingController();
  final _replaceController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _replaceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    hintText: '搜索...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.search, size: 18),
                    suffixText: widget.matchCount > 0
                        ? '${widget.currentMatchIndex + 1}/${widget.matchCount}'
                        : null,
                  ),
                  onChanged: widget.onSearch,
                ),
              ),
              const SizedBox(width: 4),
              _MiniIconButton(
                  icon: Icons.arrow_upward, onTap: widget.onPrevMatch, enabled: widget.matchCount > 0),
              _MiniIconButton(
                  icon: Icons.arrow_downward, onTap: widget.onNextMatch, enabled: widget.matchCount > 0),
              _MiniIconButton(
                icon: widget.showReplace ? Icons.unfold_less : Icons.unfold_more,
                onTap: widget.onToggleReplace,
              ),
              _MiniIconButton(icon: Icons.close, onTap: widget.onClose),
            ],
          ),
          if (widget.showReplace) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replaceController,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      hintText: '替换为...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                TextButton(
                  onPressed: () => widget.onReplace(_replaceController.text),
                  child: const Text('替换'),
                ),
                TextButton(
                  onPressed: () => widget.onReplaceAll(_replaceController.text),
                  child: const Text('全部'),
                ),
              ],
            ),
          ],
          const SizedBox(height: 4),
          Row(
            children: SearchScope.values.map((s) {
              final labels = {
                SearchScope.currentChapter: '本章',
                SearchScope.currentVolume: '本卷',
                SearchScope.entireBook: '全书',
              };
              final selected = s == widget.scope;
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: ChoiceChip(
                  label: Text(labels[s]!, style: const TextStyle(fontSize: 11)),
                  selected: selected,
                  onSelected: (_) => widget.onScopeChanged(s),
                  visualDensity: VisualDensity.compact,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _MiniIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  const _MiniIconButton({required this.icon, required this.onTap, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 18),
      onPressed: enabled ? onTap : null,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      padding: EdgeInsets.zero,
      splashRadius: 16,
    );
  }
}
