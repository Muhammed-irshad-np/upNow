import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:upnow/providers/subscription_provider.dart';
import 'package:upnow/utils/app_theme.dart';
import 'package:upnow/utils/haptic_feedback_helper.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  // Hardcoded for UI display until real products are fetched and mapped
  // Ideally, we match these by ID from the provider's product list.
  int _selectedPlanIndex = 1; // Default to Yearly (Best Value)

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
        leading: IOExceptionButton(),
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
    // If we have real products, map them. Otherwise show static placeholders.
    // Ideally we match by ID.
    // Monthly: upnow_monthly_49
    // Yearly: upnow_yearly_499
    // Lifetime: upnow_lifetime_1999

    return Column(
      children: [
        _buildPlanOption(
          index: 0,
          title: 'Monthly',
          price: '\$4.99', // Placeholder
          period: '/month',
          provider: provider,
          productId: 'upnow_monthly_49',
        ),
        SizedBox(height: 12.h),
        _buildPlanOption(
          index: 1,
          title: 'Yearly',
          price: '\$49.99', // Placeholder
          period: '/year',
          subtitle: 'Best Value (2 months free)',
          isBestValue: true,
          provider: provider,
          productId: 'upnow_yearly_499',
        ),
        SizedBox(height: 12.h),
        _buildPlanOption(
          index: 2,
          title: 'Lifetime',
          price: '\$199.99', // Placeholder
          period: 'once',
          provider: provider,
          productId: 'upnow_lifetime_1999',
        ),
      ],
    );
  }

  Widget _buildPlanOption({
    required int index,
    required String title,
    required String price,
    required String period,
    required SubscriptionProvider provider,
    required String productId,
    String? subtitle,
    bool isBestValue = false,
  }) {
    final isSelected = _selectedPlanIndex == index;

    // Try to find real product price
    String displayPrice = price;
    if (provider.products.isNotEmpty) {
      try {
        final product = provider.products.firstWhere((p) => p.id == productId);
        displayPrice = product.price;
      } catch (_) {}
    }

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
              ? AppTheme.primaryColor.withOpacity(0.1)
              : AppTheme.darkSurface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : Colors.white.withOpacity(0.05),
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
              fillColor: MaterialStateProperty.resolveWith(
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
                  displayPrice,
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
          color: AppTheme.secondaryTextColor.withOpacity(0.5),
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
    final ids = ['upnow_monthly_49', 'upnow_yearly_499', 'upnow_lifetime_1999'];

    if (_selectedPlanIndex >= 0 && _selectedPlanIndex < ids.length) {
      final selectedId = ids[_selectedPlanIndex];
      // Try to find the product in the provider's list
      try {
        final product = provider.products.firstWhere((p) => p.id == selectedId);
        provider.buyProduct(product);
      } catch (_) {
        // If product not found (e.g. testing without store), show logic
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Store not connected. Mocking purchase...')),
        );
      }
    }
  }
}

class IOExceptionButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.close, color: AppTheme.secondaryTextColor),
      onPressed: () => Navigator.pop(context),
    );
  }
}
