
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/App_theme.dart';
import 'credit_manager.dart';
import 'credit_purchase_screen.dart' show CreditsPurchaseScreen;

class CreditsCard extends StatelessWidget {
  final VoidCallback? onGetPressed;

  const CreditsCard({
    Key? key,
    this.onGetPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final creditManager = context.watch<CreditManager>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final gradientColors = [
      colorScheme.primaryContainer,
      colorScheme.secondaryContainer,
    ];
    final accentColor = colorScheme.primary;
    final onAccent = colorScheme.onPrimaryContainer;
    final mutedText = colorScheme.onSurface.withOpacity(0.75);
    final shadowColor = theme.shadowColor.withOpacity(0.2);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CreditsPurchaseScreen(),
        ),
      ),
      child: Container(
        padding: EdgeInsets.all(AppTheme.responsiveSize(context, phone: 20, tablet: 26)),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.responsiveSize(context, phone: 16, tablet: 20)),
          border: Border.all(
            color: accentColor.withOpacity(0.45),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppTheme.responsiveSize(context, phone: 8, tablet: 10)),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppTheme.responsiveSize(context, phone: 8, tablet: 10)),
                  ),
                  child: Icon(
                    Icons.stars,
                    color: accentColor,
                    size: AppTheme.responsiveSize(context, phone: 20, tablet: 26),
                  ),
                ),
                SizedBox(width: AppTheme.responsiveSize(context, phone: 12, tablet: 16)),
                Text(
                  'Available Credits',
                  style: TextStyle(
                    color: onAccent,
                    fontSize: AppTheme.responsiveFont(context, phone: 16, tablet: 20),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppTheme.responsiveSize(context, phone: 16, tablet: 22)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (creditManager.isLoading)
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                        )
                      else
                        Text(
                          '${creditManager.credits}',
                          style: TextStyle(
                            color: accentColor,
                            fontSize: AppTheme.responsiveFont(context, phone: 44, tablet: 56),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      SizedBox(height: AppTheme.responsiveSize(context, phone: 4, tablet: 8)),
                      Text(
                        'Use credits for AI styling features',
                        style: TextStyle(
                          color: mutedText,
                          fontSize: AppTheme.responsiveFont(context, phone: 12, tablet: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CreditsPurchaseScreen(),
                      ),
                    );
                  },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: accentColor,
                        width: AppTheme.responsiveSize(context, phone: 1.5, tablet: 2),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: AppTheme.responsiveSize(context, phone: 14, tablet: 20),
                        vertical: AppTheme.responsiveSize(context, phone: 10, tablet: 14),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.responsiveSize(context, phone: 8, tablet: 12)),
                      ),
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  child: Text(
                    'Get More',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: AppTheme.responsiveFont(context, phone: 14, tablet: 18),
                        fontWeight: FontWeight.w600,
                      ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
