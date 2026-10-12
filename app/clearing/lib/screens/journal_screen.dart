import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'journal_detail_screen.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final _api = ApiService();
  final _scroll = ScrollController();
  final List<JournalEntry> _entries = [];
  int _page = 0;
  int _total = 0;
  bool _hasMore = true;
  bool _loading = false;
  bool _firstLoad = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _loadNext();
  }

  void _onScroll() {
    if (_scroll.hasClients && _scroll.position.extentAfter < 500) _loadNext();
  }

  Future<void> _loadNext() async {
    if (_loading || !_hasMore) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _api.fetchJournal(_page);
      if (!mounted) return;
      setState(() {
        _entries.addAll(result.entries);
        _page = result.page + 1;
        _total = result.total;
        _hasMore = result.hasMore;
        _firstLoad = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error =
            'Your journal couldn’t load. Check your connection and try again.';
        _firstLoad = false;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    if (_loading) return;
    setState(() {
      _entries.clear();
      _page = 0;
      _total = 0;
      _hasMore = true;
      _firstLoad = true;
      _error = null;
    });
    await _loadNext();
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.beige,
    appBar: AppBar(
      title: const Text('Journal'),
      backgroundColor: AppColors.beige,
      surfaceTintColor: Colors.transparent,
    ),
    body: _firstLoad
        ? Semantics(
            label: 'Loading journal entries',
            liveRegion: true,
            child: Center(child: CircularProgressIndicator()),
          )
        : _error != null && _entries.isEmpty
        ? _JournalMessage(
            icon: Icons.cloud_off_outlined,
            message: _error!,
            action: 'Try again',
            onAction: _refresh,
          )
        : _entries.isEmpty
        ? const _JournalMessage(
            icon: Icons.nature_outlined,
            message: 'Your story starts outside. Take a walk and verify your first photo to begin your journal.',
          )
        : RefreshIndicator(
            onRefresh: _refresh,
            color: AppColors.olive,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: ListView.builder(
                  controller: _scroll,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  itemCount: _entries.length + 2,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          '$_total ${_total == 1 ? 'moment' : 'moments'} saved outdoors',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      );
                    }
                    if (index == _entries.length + 1) {
                      if (_error != null) {
                        return Center(
                          child: TextButton.icon(
                            onPressed: _loadNext,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry loading more'),
                          ),
                        );
                      }
                      if (!_hasMore) return const SizedBox(height: 12);
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final entry = _entries[index - 1];
                    return _JournalTile(
                      key: ValueKey(entry.id),
                      entry: entry,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => JournalDetailScreen(entry: entry),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
  );
}

class _JournalTile extends StatelessWidget {
  const _JournalTile({super.key, required this.entry, required this.onTap});

  final JournalEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locale = MaterialLocalizations.of(context);
    final date = locale.formatMediumDate(entry.takenAt);
    final time = locale.formatTimeOfDay(TimeOfDay.fromDateTime(entry.takenAt));
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'journal-photo-${entry.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      entry.thumbnailUrl,
                      headers: const {'ngrok-skip-browser-warning': 'true'},
                      width: 84,
                      height: 84,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) =>
                          loadingProgress == null
                          ? child
                          : const _PhotoPlaceholder(),
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint(
                          'Journal thumbnail failed for ${entry.id}: $error',
                        );
                        return const _PhotoUnavailable();
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$date · $time',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: AppColors.olive,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        entry.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (entry.tags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: entry.tags
                              .take(3)
                              .map((tag) => _JournalTag(tag))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 4, top: 30),
                  child: Icon(Icons.chevron_right, color: AppColors.olive),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _JournalTag extends StatelessWidget {
  const _JournalTag(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 110),
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.olive.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelSmall
          ?.copyWith(color: AppColors.forest, fontWeight: FontWeight.w600),
    ),
  );
}

class _JournalMessage extends StatelessWidget {
  const _JournalMessage({
    required this.icon,
    required this.message,
    this.action,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 58, color: AppColors.olive),
          const SizedBox(height: 20),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (action != null) ...[
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh),
              label: Text(action!),
            ),
          ],
        ],
      ),
    ),
  );
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.olive.withValues(alpha: 0.12),
    alignment: Alignment.center,
    child: const SizedBox(
      width: 22,
      height: 22,
      child: CircularProgressIndicator(strokeWidth: 2),
    ),
  );
}

class _PhotoUnavailable extends StatelessWidget {
  const _PhotoUnavailable();

  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.olive.withValues(alpha: 0.12),
    alignment: Alignment.center,
    child: const Icon(
      Icons.image_not_supported_outlined,
      color: AppColors.olive,
    ),
  );
}
