import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class OnboardingPage {
  const OnboardingPage({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.icon,
    this.stat,
    this.source,
  });

  final String eyebrow;
  final String title;
  final String body;
  final IconData icon;
  final String? stat;
  final String? source;
}

const onboardingPages = [
  OnboardingPage(
    eyebrow: 'A LITTLE MORE OUT THERE',
    title: 'Welcome to Clearing',
    body:
        'A small invitation to step outside, notice what is around you, and make the familiar feel new again.',
    icon: Icons.explore_outlined,
  ),
  OnboardingPage(
    eyebrow: 'WHY CONNECTION MATTERS',
    title: 'Time outside can start with one small step',
    body:
        'Social isolation is associated with higher health risks. In a review of 90 cohort studies involving more than 2.2 million people, it was associated with a 32% higher risk of death from any cause.',
    icon: Icons.groups_2_outlined,
    stat: '32% higher associated risk',
    source: 'Nature Human Behaviour · 2023 · 90 cohort studies',
  ),
  OnboardingPage(
    eyebrow: 'A GENTLE WAY TO BEGIN',
    title: 'Make your neighborhood an adventure',
    body:
        'Clearing turns a walk into a series of small discoveries. Take photos of the outdoors, uncover places on your map, and keep a journal of what you noticed.',
    icon: Icons.park_outlined,
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page == onboardingPages.length - 1) {
      widget.onFinished();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: widget.onFinished,
                  child: const Text('Skip'),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: onboardingPages.length,
                  onPageChanged: (page) => setState(() => _page = page),
                  itemBuilder: (context, index) => _OnboardingPageView(
                    page: onboardingPages[index],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Row(
                  children: [
                    Row(
                      children: List.generate(
                        onboardingPages.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: const EdgeInsets.only(right: 7),
                          width: index == _page ? 22 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: index == _page
                                ? AppColors.terracotta
                                : AppColors.olive.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: _next,
                      icon: Icon(
                        _page == onboardingPages.length - 1
                            ? Icons.arrow_forward
                            : Icons.chevron_right,
                      ),
                      label: Text(
                        _page == onboardingPages.length - 1
                            ? 'Get started'
                            : 'Next',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _OnboardingPageView extends StatelessWidget {
  const _OnboardingPageView({required this.page});
  final OnboardingPage page;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                color: AppColors.forest,
                borderRadius: BorderRadius.circular(34),
              ),
              child: Icon(page.icon, size: 54, color: AppColors.terracotta),
            ),
            const SizedBox(height: 34),
            Text(
              page.eyebrow,
              style: const TextStyle(
                color: AppColors.ochre,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              page.title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.12,
                  ),
            ),
            const SizedBox(height: 18),
            Text(page.body, style: Theme.of(context).textTheme.bodyLarge),
            if (page.stat case final stat?) ...[
              const SizedBox(height: 24),
              Text(
                stat,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.ochre,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 5),
              Text(
                page.source!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.olive,
                    ),
              ),
              const SizedBox(height: 5),
              Text(
                'Association observed in population studies; this is not an individual prediction.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      );
}
