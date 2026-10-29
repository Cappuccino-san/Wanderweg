import 'package:flutter/material.dart';
import '../../models/stop.dart';
import '../theme/app_theme.dart';

class StopCardDialog extends StatelessWidget {
  final Stop stop;

  const StopCardDialog({super.key, required this.stop});

  static void show(BuildContext context, Stop stop) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StopCardDialog(stop: stop),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: AppTheme.borderOutline,
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (stop.isAnchor)
                        Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.germanGold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'CONFIRMED ANCHOR',
                            style: TextStyle(
                              color: AppTheme.germanGold,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      Text(
                        stop.nameEn,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.inkBlack,
                          height: 1.2,
                        ),
                      ),
                      Text(
                        stop.nameDe,
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: AppTheme.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: AppTheme.inkBlack),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          Divider(height: 24, thickness: 1, color: AppTheme.borderOutline),

          // Scrollable 5 Questions Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              children: [
                // Fast meta strip
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _metaChip(Icons.timer_outlined, '${stop.dwellTimeMinutes}m dwell'),
                    _metaChip(Icons.euro_outlined, stop.costLabel),
                    if (stop.stepFreeAccess)
                      _metaChip(Icons.accessible_forward, 'Step-free')
                    else
                      _metaChip(Icons.stairs, 'Steps / Cobbles'),
                    _metaChip(Icons.verified_outlined, 'Verified ${stop.lastVerifiedDate}'),
                  ],
                ),
                const SizedBox(height: 18),

                // Question 1: What am I looking at?
                _questionSection(
                  'What am I looking at?',
                  stop.whatAmILookingAt,
                  Icons.visibility_outlined,
                ),

                // Question 2: Why does it matter?
                _questionSection(
                  'Why does it matter?',
                  stop.whyItMatters,
                  Icons.history_edu_outlined,
                ),

                // Question 3: What should I notice?
                _questionSection(
                  'What should I notice?',
                  stop.whatToNotice,
                  Icons.search_outlined,
                ),

                // Question 4: How long should I stay?
                _questionSection(
                  'How long should I stay?',
                  'Suggested dwell time is ${stop.dwellTimeMinutes} minutes. ${stop.openingHours}',
                  Icons.schedule_outlined,
                ),

                // Question 5: What is the local tip?
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.forestGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.forestGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.tips_and_updates,
                              size: 18, color: AppTheme.forestGreen),
                          SizedBox(width: 8),
                          Text(
                            'Local Tip',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppTheme.forestGreen,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        stop.localTip,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.inkBlack,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Accessibility note
                if (stop.stepFreeNotes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Text(
                      'Accessibility: ${stop.stepFreeNotes}',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.mutedText,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.warmCanvas,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.borderOutline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.inkBlack),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.inkBlack,
            ),
          ),
        ],
      ),
    );
  }

  Widget _questionSection(String title, String answer, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.inkBlack),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.inkBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            answer,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.inkBlack,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
