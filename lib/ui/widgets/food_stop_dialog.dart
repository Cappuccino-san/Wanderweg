import 'package:flutter/material.dart';
import '../../models/food_stop.dart';
import '../theme/app_theme.dart';

class FoodStopDialog extends StatelessWidget {
  final FoodStop food;

  const FoodStopDialog({super.key, required this.food});

  static void show(BuildContext context, FoodStop food) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FoodStopDialog(food: food),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: AppTheme.borderOutline,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.berlinBrick.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          food.typeLabel.toUpperCase(),
                          style: TextStyle(
                            color: AppTheme.berlinBrick,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        food.name,
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.inkBlack,
                        ),
                      ),
                      Text(
                        '${food.cuisine} • ${food.priceBand}',
                        style: TextStyle(
                          fontSize: 14,
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
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                // Signature Order Callout
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.germanGold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.germanGold.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.restaurant,
                              size: 18, color: AppTheme.inkBlack),
                          SizedBox(width: 8),
                          Text(
                            'What to order if you order one thing',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: AppTheme.inkBlack,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        food.signatureOrder,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.inkBlack,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Practical Walking Flags
                Text(
                  'Practical Walker Flags',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.inkBlack,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (food.cashOnly)
                      _flagBadge(Icons.payments, 'Cash Only', isAlert: true)
                    else if (food.cardsAccepted)
                      _flagBadge(Icons.credit_card, 'Cards Accepted'),
                    if (food.closedSundays)
                      _flagBadge(Icons.event_busy, 'Closed Sundays', isAlert: true),
                    if (food.goodInRain)
                      _flagBadge(Icons.umbrella, 'Good in rain'),
                    if (food.goodWithTiredFeet)
                      _flagBadge(Icons.chair, 'Good seating for tired feet'),
                    if (food.kitchenClosesEarly)
                      _flagBadge(Icons.access_time_filled, 'Kitchen closes early', isAlert: true),
                    ...food.dietaryFlags.map((d) => _flagBadge(Icons.eco, d)),
                  ],
                ),
                const SizedBox(height: 18),

                // Hours
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: AppTheme.mutedText),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Hours: ${food.openingHours}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.inkBlack,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Anti-booking banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.warmCanvas,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderOutline),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.shield_outlined,
                          size: 20, color: AppTheme.forestGreen),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Zero booking • Zero commission • Recommended purely for walk quality',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.mutedText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _flagBadge(IconData icon, String text, {bool isAlert = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isAlert
            ? AppTheme.berlinBrick.withValues(alpha: 0.1)
            : AppTheme.warmCanvas,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isAlert
              ? AppTheme.berlinBrick.withValues(alpha: 0.4)
              : AppTheme.borderOutline,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 14,
              color: isAlert ? AppTheme.berlinBrick : AppTheme.inkBlack),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isAlert ? AppTheme.berlinBrick : AppTheme.inkBlack,
            ),
          ),
        ],
      ),
    );
  }
}
