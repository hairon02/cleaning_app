import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key, required this.onTakePhoto});

  final VoidCallback onTakePhoto;

  @override
  State<ChallengesScreen> createState() => ChallengesScreenState();
}

class ChallengesScreenState extends State<ChallengesScreen> {
  final _api = ApiService();
  late Future<ChallengesResult> _challenges;
  _ChallengeFilter _filter = _ChallengeFilter.active;

  @override
  void initState() {
    super.initState();
    _challenges = _api.fetchChallenges();
  }

  Future<void> refresh() async {
    final request = _api.fetchChallenges();
    setState(() => _challenges = request);
    try {
      await request;
    } catch (_) {
      // The FutureBuilder below presents the error and retry action.
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Column(
          children: [
            const _ChallengesHeader(),
            Expanded(
              child: FutureBuilder<ChallengesResult>(
                future: _challenges,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    final noChallenges = snapshot.error is NoChallengesException;
                    return _MessageView(
                      icon: noChallenges ? Icons.flag_outlined : Icons.cloud_off,
                      title: noChallenges
                          ? 'No challenges available today'
                          : 'Could not load challenges',
                      detail: noChallenges
                          ? 'Check back later.'
                          : 'Check your connection and try again.',
                      onRetry: refresh,
                    );
                  }
                  final result = snapshot.data!;
                  final allChallenges = [result.daily, result.weekly];
                  final visibleChallenges = allChallenges
                      .where(
                        (challenge) => _filter == _ChallengeFilter.completed
                            ? challenge.completedByUser
                            : !challenge.completedByUser,
                      )
                      .toList();

                  return RefreshIndicator(
                    onRefresh: refresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      children: [
                        const Text(
                          'Explore and earn points with each challenge.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 18),
                        Center(
                          child: SegmentedButton<_ChallengeFilter>(
                            segments: const [
                              ButtonSegment(
                                value: _ChallengeFilter.active,
                                label: Text('Active'),
                                icon: Icon(Icons.flag_outlined),
                              ),
                              ButtonSegment(
                                value: _ChallengeFilter.completed,
                                label: Text('Completed'),
                                icon: Icon(Icons.check_circle_outline),
                              ),
                            ],
                            selected: {_filter},
                            showSelectedIcon: false,
                            onSelectionChanged: (selection) => setState(
                              () => _filter = selection.first,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        if (visibleChallenges.isEmpty)
                          _EmptyChallengeFilter(
                            completed: _filter == _ChallengeFilter.completed,
                          )
                        else
                          ...visibleChallenges.map(
                            (challenge) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _ChallengeCard(
                                challenge: challenge,
                                onTap: () => _openChallenge(context, challenge),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );

  Future<void> _openChallenge(
    BuildContext context,
    ActiveChallenge challenge,
  ) => Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => ChallengeDetailScreen(
            challenge: challenge,
            onTakePhoto: () {
              Navigator.of(context).pop();
              widget.onTakePhoto();
            },
          ),
        ),
      );
}

enum _ChallengeFilter { active, completed }

class _ChallengesHeader extends StatelessWidget {
  const _ChallengesHeader();

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _InvertedTrapezoidPainter(),
        child: SizedBox(
          width: double.infinity,
          height: 82,
          child: Center(
            child: Text(
              'CHALLENGES',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
            ),
          ),
        ),
      );
}

class _InvertedTrapezoidPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(24, 0)
      ..lineTo(size.width - 24, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.terracotta
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EmptyChallengeFilter extends StatelessWidget {
  const _EmptyChallengeFilter({required this.completed});
  final bool completed;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 16),
        child: Column(
          children: [
            Icon(
              completed ? Icons.emoji_events_outlined : Icons.task_alt,
              size: 44,
              color: AppColors.olive,
            ),
            const SizedBox(height: 12),
            Text(
              completed
                  ? 'No completed challenges yet'
                  : 'All challenges completed',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({required this.challenge, required this.onTap});
  final ActiveChallenge challenge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final daily = challenge.period == 'daily';
    final completed = challenge.completedByUser;
    return Card(
      color: Colors.white.withValues(alpha: 0.72),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppColors.olive.withValues(alpha: 0.22)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(daily ? Icons.today : Icons.date_range,
                      color: AppColors.olive),
                  const SizedBox(width: 8),
                  Text(daily ? 'DAILY CHALLENGE' : 'WEEKLY CHALLENGE',
                      style: const TextStyle(
                          color: AppColors.olive,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1)),
                  const Spacer(),
                  Text('${challenge.points} points',
                      style: const TextStyle(
                          color: AppColors.ochre,
                          fontWeight: FontWeight.w800,
                          fontSize: 16)),
                ],
              ),
              const SizedBox(height: 14),
              Text(challenge.title,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(challenge.description),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.beige,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('How to complete it: ${challenge.visualCriterion}'),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(
                    completed
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: completed ? AppColors.olive : AppColors.terracotta,
                  ),
                  const SizedBox(width: 8),
                  Text(completed ? 'Completed' : 'Pending'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChallengeDetailScreen extends StatelessWidget {
  const ChallengeDetailScreen({
    super.key,
    required this.challenge,
    required this.onTakePhoto,
  });

  final ActiveChallenge challenge;
  final VoidCallback onTakePhoto;

  @override
  Widget build(BuildContext context) {
    final daily = challenge.period == 'daily';
    final completed = challenge.completedByUser;
    return Scaffold(
      appBar: AppBar(
        title: Text(daily ? 'Daily challenge' : 'Weekly challenge'),
        leading: IconButton(
          tooltip: 'Close',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                children: [
                  Container(
                    height: 190,
                    decoration: BoxDecoration(
                      color: AppColors.forest,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      daily ? Icons.today : Icons.date_range,
                      size: 76,
                      color: AppColors.terracotta,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          challenge.title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Chip(
                        label: Text('${challenge.points} points'),
                        backgroundColor: AppColors.terracotta.withValues(alpha: 0.2),
                        side: BorderSide.none,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(challenge.description),
                  const SizedBox(height: 28),
                  Text('Completion criteria',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(challenge.visualCriterion),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Icon(
                        completed ? Icons.check_circle : Icons.flag_outlined,
                        color: completed ? AppColors.olive : AppColors.terracotta,
                      ),
                      const SizedBox(width: 10),
                      Text(completed ? 'Challenge completed' : 'Still in progress'),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: completed ? null : onTakePhoto,
                  icon: const Icon(Icons.camera_alt),
                  label: Text(completed ? 'Challenge completed' : 'Take Photo'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(68),
                    padding: const EdgeInsets.symmetric(vertical: 22),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onRetry,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: AppColors.olive),
              const SizedBox(height: 14),
              Text(title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(detail, textAlign: TextAlign.center),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
}
