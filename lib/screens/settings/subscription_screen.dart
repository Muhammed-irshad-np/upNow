import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:upnow/providers/subscription_provider.dart';
import 'package:upnow/utils/app_theme.dart';
import 'package:upnow/utils/haptic_feedback_helper.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  int _selectedPlanIndex = 1; // Default to Yearly (Best Value)
  // Debug logs state
  final List<String> _logs = [];

  void _log(String message) {
    debugPrint(message);
    setState(() {
      _logs.add(message);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text(
          'Upgrade to Pro',
          style: TextStyle(
            color: AppTheme.primaryTextColor,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppTheme.secondaryTextColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<SubscriptionProvider>(
        builder: (context, subscriptionProvider, child) {
          if (subscriptionProvider.isLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
              ),
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                SizedBox(height: 32.h),
                _buildBenefitsList(),
                SizedBox(height: 40.h),
                _buildPlanSelection(subscriptionProvider),
                SizedBox(height: 40.h),
                _buildSubscribeButton(subscriptionProvider),
                SizedBox(height: 16.h),
                _buildRestoreButton(subscriptionProvider),
                SizedBox(height: 24.h),
                _buildTermsLinks(),
                SizedBox(height: 40.h),
                // DEBUG CONSOLE
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('DEBUG LOGS (Screenshot this):',
                          style: TextStyle(
                              color: Colors.red, fontWeight: FontWeight.bold)),
                      Divider(color: Colors.red),
                      if (_logs.isEmpty)
                        Text('Waiting for data...',
                            style: TextStyle(color: Colors.white70)),
                      ..._logs.map((l) => Text(l,
                          style: TextStyle(color: Colors.white, fontSize: 10))),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          height: 80.h,
          width: 80.h,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.star_rounded,
            color: AppTheme.primaryColor,
            size: 48.sp,
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          'Unlock Full Potential',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.primaryTextColor,
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'Get access to all premium features and enhance your daily routine.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.secondaryTextColor,
            fontSize: 16.sp,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitsList() {
    return Column(
      children: [
        _buildBenefitItem('Unlimited Alarms', Icons.alarm_on),
        _buildBenefitItem('Advanced Sleep Tracking', Icons.nightlight_round),
        _buildBenefitItem('Custom Habit Stats', Icons.insights),
        _buildBenefitItem('Priority Support', Icons.support_agent),
        _buildBenefitItem('Ad-Free Experience', Icons.block),
      ],
    );
  }

  Widget _buildBenefitItem(String text, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: AppTheme.primaryColor,
            size: 20.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppTheme.primaryTextColor,
                fontSize: 16.sp,
              ),
            ),
          ),
          Icon(
            icon,
            color: AppTheme.secondaryTextColor.withOpacity(0.5),
            size: 20.sp,
          ),
        ],
      ),
    );
  }

  Widget _buildPlanSelection(SubscriptionProvider provider) {
    if (provider.products.isEmpty) {
      final isIndia =
          View.of(context).platformDispatcher.locale.countryCode == 'IN';
      return Column(
        children: [
          _buildPlanOption(
            index: 0,
            title: 'Monthly',
            price: isIndia ? '₹49' : '\$2',
            period: '/month',
          ),
          SizedBox(height: 12.h),
          _buildPlanOption(
            index: 1,
            title: 'Yearly',
            price: isIndia ? '₹499' : '\$9.99',
            period: '/year',
            subtitle: 'Best Value (2 months free)',
          ),
        ],
      );
    }

    final product = provider.products.first;
    if (product is GooglePlayProductDetails) {
      final offers = product.productDetails.subscriptionOfferDetails ?? [];

      // Avoid adding duplicate logs on re-renders
      if (_logs.isEmpty) {
        _log('Product ID: ${product.id}');
        _log('Found ${offers.length} offers');
      }

      for (var offer in offers) {
        // Simple check to avoid spamming the log if build is called multiple times
        // In a real debug tool we'd be cleaner, but this is a quick fix for the user
        final logMsg = 'Offer: ${offer.basePlanId}';
        if (!_logs.contains(logMsg)) {
          _log(logMsg);
          for (var phase in offer.pricingPhases) {
            _log(' > Phase: ${phase.billingPeriod} ${phase.formattedPrice}');
          }
        }
      }

      final monthlyOffers = offers
          .where((o) =>
              o.basePlanId.contains('month') || // Fallback check
              o.pricingPhases.any(
                  (p) => p.billingPeriod == 'P1M' || p.billingPeriod == 'P30D'))
          .toList();
      final yearlyOffers = offers
          .where((o) =>
              o.basePlanId.contains('year') || // Fallback check
              o.pricingPhases.any((p) =>
                  p.billingPeriod == 'P1Y' || p.billingPeriod == 'P365D'))
          .toList();

      // identifying any offers that didn't fit into the above categories
      final usedOfferTokens = {
        ...monthlyOffers.map((o) => o.offerIdToken),
        ...yearlyOffers.map((o) => o.offerIdToken)
      };
      final otherOffers = offers
          .where((o) => !usedOfferTokens.contains(o.offerIdToken))
          .toList();

      debugPrint('Filtered Monthly Offers: ${monthlyOffers.length}');
      debugPrint('Filtered Yearly Offers: ${yearlyOffers.length}');
      debugPrint('Other/Uncategorized Offers: ${otherOffers.length}');

      return Column(
        children: [
          if (monthlyOffers.isNotEmpty)
            _buildPlanOption(
              index: 0,
              title: 'Monthly',
              price: _getDisplayPrice(monthlyOffers.first),
              period: '/month',
            ),
          if (monthlyOffers.isNotEmpty && yearlyOffers.isNotEmpty)
            SizedBox(height: 12.h),
          if (yearlyOffers.isNotEmpty)
            _buildPlanOption(
              index: 1,
              title: 'Yearly',
              price: _getDisplayPrice(yearlyOffers.first),
              period: '/year',
              subtitle: 'Best Value',
            ),

          // Render any uncategorized plans so they are at least visible
          if (otherOffers.isNotEmpty) ...[
            SizedBox(height: 12.h),
            ...otherOffers.asMap().entries.map((entry) {
              final index = entry.key + 2; // Offset indices
              final offer = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: _buildPlanOption(
                  index: index,
                  title: offer.basePlanId, // Fallback title
                  price: _getDisplayPrice(offer),
                  period: '',
                  subtitle: 'Special Plan',
                ),
              );
            }),
          ],

          if (yearlyOffers.isEmpty && otherOffers.isEmpty)
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                  'WARN: Yearly plan not detected. Check Debug Logs below.',
                  style: TextStyle(color: Colors.amber, fontSize: 12),
                  textAlign: TextAlign.center),
            ),
        ],
      );
    } else {
      return Column(
        children: [
          _buildPlanOption(
            index: 0,
            title: product.title,
            price: product.price,
            period: '',
          ),
        ],
      );
    }
  }

  String _getDisplayPrice(SubscriptionOfferDetailsWrapper offer) {
    if (offer.pricingPhases.isEmpty) return 'N/A';
    final paidPhase = offer.pricingPhases.firstWhere(
      (p) => p.priceAmountMicros > 0,
      orElse: () => offer.pricingPhases.first,
    );
    return paidPhase.formattedPrice;
  }

  Widget _buildPlanOption({
    required int index,
    required String title,
    required String price,
    required String period,
    String? subtitle,
  }) {
    final isSelected = _selectedPlanIndex == index;

    return GestureDetector(
      onTap: () {
        HapticFeedbackHelper.trigger();
        setState(() {
          _selectedPlanIndex = index;
        });
      },
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.1)
              : AppTheme.darkSurface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : Colors.white.withValues(alpha: 0.05),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Radio<int>(
              value: index,
              groupValue: _selectedPlanIndex,
              onChanged: (value) {
                if (value != null) {
                  HapticFeedbackHelper.trigger();
                  setState(() {
                    _selectedPlanIndex = value;
                  });
                }
              },
              activeColor: AppTheme.primaryColor,
              fillColor: WidgetStateProperty.resolveWith(
                (states) => isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.secondaryTextColor,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppTheme.primaryTextColor,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 4.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: TextStyle(
                    color: AppTheme.primaryTextColor,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  period,
                  style: TextStyle(
                    color: AppTheme.secondaryTextColor,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscribeButton(SubscriptionProvider provider) {
    return ElevatedButton(
      onPressed: () {
        HapticFeedbackHelper.trigger();
        _handlePurchase(provider);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryColor,
        padding: EdgeInsets.symmetric(vertical: 16.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        elevation: 0,
      ),
      child: Text(
        'Continue',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRestoreButton(SubscriptionProvider provider) {
    return Center(
      child: TextButton(
        onPressed: () {
          HapticFeedbackHelper.trigger();
          provider.restorePurchases();
        },
        child: Text(
          'Restore Purchases',
          style: TextStyle(
            color: AppTheme.secondaryTextColor,
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildTermsLinks() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLinkText('Privacy Policy'),
        Container(
          height: 12.h,
          width: 1,
          color: AppTheme.secondaryTextColor.withValues(alpha: 0.5),
          margin: EdgeInsets.symmetric(horizontal: 16.w),
        ),
        _buildLinkText('Terms of Use'),
      ],
    );
  }

  Widget _buildLinkText(String text) {
    return GestureDetector(
      onTap: () {
        // TODO: Launch URL
      },
      child: Text(
        text,
        style: TextStyle(
          color: AppTheme.secondaryTextColor,
          fontSize: 12.sp,
        ),
      ),
    );
  }

  void _handlePurchase(SubscriptionProvider provider) {
    if (provider.products.isEmpty) return;

    final product = provider.products.first;
    String? selectedOfferToken;

    if (product is GooglePlayProductDetails) {
      final offers = product.productDetails.subscriptionOfferDetails ?? [];

      final monthlyOffers = offers
          .where((o) => o.pricingPhases.any((p) => p.billingPeriod == 'P1M'))
          .toList();
      final yearlyOffers = offers
          .where((o) => o.pricingPhases.any((p) => p.billingPeriod == 'P1Y'))
          .toList();

      if (_selectedPlanIndex == 0 && monthlyOffers.isNotEmpty) {
        selectedOfferToken = monthlyOffers.first.offerIdToken;
      } else if (_selectedPlanIndex == 1 && yearlyOffers.isNotEmpty) {
        selectedOfferToken = yearlyOffers.first.offerIdToken;
      }
    }

    provider.buySubscription(product, selectedOfferToken);
  }
}
