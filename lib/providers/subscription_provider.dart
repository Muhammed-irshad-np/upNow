import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Product ID for the subscription
const String _kSubscriptionId = 'premium_features';
const Set<String> _kProductIds = {_kSubscriptionId};

class SubscriptionProvider extends ChangeNotifier {
  final InAppPurchase _iap = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  List<ProductDetails> _products = [];
  List<String> _notFoundIDs = [];
  bool _isAvailable = false;
  bool _isLoading = false;
  bool _isPro = false;

  bool get isAvailable => _isAvailable;
  bool get isLoading => _isLoading;
  bool get isPro => _isPro;
  List<ProductDetails> get products => _products;
  List<String> get notFoundIDs => _notFoundIDs;

  SubscriptionProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();

    // Load pro status from local storage
    final prefs = await SharedPreferences.getInstance();
    _isPro = prefs.getBool('is_pro') ?? false;

    // Listen to purchase updates
    final purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen(
      (purchaseDetailsList) {
        _listenToPurchaseUpdated(purchaseDetailsList);
      },
      onDone: () {
        _subscription.cancel();
      },
      onError: (error) {
        // handle error here.
        debugPrint('IAP Error: $error');
      },
    );

    await _initStoreInfo();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _initStoreInfo() async {
    final bool isAvailable = await _iap.isAvailable();
    if (!isAvailable) {
      _isAvailable = false;
      _products = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    final ProductDetailsResponse response =
        await _iap.queryProductDetails(_kProductIds);
    _notFoundIDs = response.notFoundIDs;

    if (response.error != null) {
      _isAvailable = isAvailable;
      _products = response.productDetails;
      debugPrint('IAP Query Error: ${response.error}');
      return;
    }

    if (response.productDetails.isEmpty) {
      _isAvailable = isAvailable;
      _products = response.productDetails;
      debugPrint('IAP: No products found. Not found: $_notFoundIDs');
      return;
    }

    _isAvailable = isAvailable;
    _products = response.productDetails;
    notifyListeners();
  }

  Future<void> buyProduct(ProductDetails product) async {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    // For subscriptions, we might need to change this if it's not a consumable
    // Consumables are one-time use (like coins).
    // Non-consumables are permanent (like lifetime).
    // Subscriptions are recurring.
    // The library handles the distinction via the store configuration,
    // but on iOS specific params might be needed.
    // For now assuming standard flow.

    // Using autoConsume: false for subscriptions/lifetime
    try {
      if (_kProductIds.contains(product.id)) {
        await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      }
    } catch (e) {
      debugPrint('IAP Buy Error: $e');
    }
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Show pending UI?
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          // Handle error
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          bool valid = await _verifyPurchase(purchaseDetails);
          if (valid) {
            _deliverProduct(purchaseDetails);
          } else {
            _handleInvalidPurchase(purchaseDetails);
          }
        }

        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }
      }
    });
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // IMPORTANT!! Always verify a purchase before delivering the product.
    // For the purpose of this template, we assume it's valid.
    // Real apps should verify the receipt on a backend server.
    return Future<bool>.value(true);
  }

  void _deliverProduct(PurchaseDetails purchaseDetails) async {
    // IMPORTANT!! Always verify a purchase before delivering the product.
    _isPro = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_pro', true);
    notifyListeners();
  }

  void _handleInvalidPurchase(PurchaseDetails purchaseDetails) {
    // handle invalid purchase here if verification failed
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
