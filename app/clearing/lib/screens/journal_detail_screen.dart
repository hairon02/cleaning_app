import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';

class JournalDetailScreen extends StatelessWidget {
  const JournalDetailScreen({super.key, required this.entry});

  final JournalEntry entry;

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final date = localizations.formatMediumDate(entry.takenAt);
    final time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(entry.takenAt),
    );
    return Scaffold(
      backgroundColor: AppColors.beige,
      appBar: AppBar(
        title: const Text('Journal entry'),
        backgroundColor: AppColors.beige,
        surfaceTintColor: Colors.transparent,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.48,
              width: double.infinity,
              child: Hero(
                tag: 'journal-photo-${entry.id}',
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Image.network(
                    entry.photoUrl,
                    headers: const {'ngrok-skip-browser-warning': 'true'},
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) =>
                        loadingProgress == null
                        ? child
                        : const Center(child: CircularProgressIndicator()),
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint(
                        'Journal photo failed for ${entry.id}: $error',
                      );
                      return const Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          size: 48,
                          color: AppColors.olive,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            sliver: SliverList.list(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: AppColors.olive,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        '$date · $time',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.olive,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  entry.description,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(height: 1.45),
                ),
                if (entry.tags.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'What you found',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: entry.tags
                        .map(
                          (tag) => Chip(
                            label: Text(tag),
                            backgroundColor: AppColors.olive.withValues(
                              alpha: 0.12,
                            ),
                            side: BorderSide.none,
                            labelStyle: const TextStyle(
                              color: AppColors.forest,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
