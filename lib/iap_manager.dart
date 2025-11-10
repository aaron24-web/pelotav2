import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';

// Placeholder product IDs. Replace with your actual IDs from the stores.
const String productIdConsumable = 'pack_1000_monedas';
const String productIdNonConsumable = 'desbloqueo_jefe';
const String productIdSubscription = 'pase_temporada';

class IAPManager {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  
  final List<ProductDetails> _products = [];
  bool _isAvailable = false;

  // Singleton pattern
  IAPManager._privateConstructor();
  static final IAPManager _instance = IAPManager._privateConstructor();
  static IAPManager get instance => _instance;

  Future<void> init() async {
    _isAvailable = await _inAppPurchase.isAvailable();
    if (!_isAvailable) {
      // Handle store not available
      return;
    }

    await _loadProducts();

    _subscription = _inAppPurchase.purchaseStream.listen(
      (List<PurchaseDetails> purchaseDetailsList) {
        _listenToPurchaseUpdated(purchaseDetailsList);
      },
      onDone: () {
        _subscription.cancel();
      },
      onError: (error) {
        // Handle error here.
      },
    );
  }

  Future<void> _loadProducts() async {
    const Set<String> productIds = {
      productIdConsumable,
      productIdNonConsumable,
      productIdSubscription,
    };
    final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(productIds);
    if (response.notFoundIDs.isNotEmpty) {
      // Handle any products that were not found.
    }
    _products.clear();
    _products.addAll(response.productDetails);
  }

  List<ProductDetails> get products => _products;

  void buyProduct(ProductDetails productDetails) {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
    if (productDetails.id == productIdConsumable) {
      _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
    } else {
      _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    }
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Show pending UI.
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          // Handle error.
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                   purchaseDetails.status == PurchaseStatus.restored) {
          _handleCompletedPurchase(purchaseDetails);
        }
        if (purchaseDetails.pendingCompletePurchase) {
          _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    }
  }

  Future<void> _handleCompletedPurchase(PurchaseDetails purchaseDetails) async {
    // This is where you would typically verify the purchase with your backend.
    // For this exercise, we will simulate verification and deliver the content directly.

    switch (purchaseDetails.productID) {
      case productIdConsumable:
        // Grant 1000 coins. This logic will be connected to the ShopManager later.
        print('User purchased 1000 coins.');
        break;
      case productIdNonConsumable:
        // Unlock the big boss level. This state should be saved persistently.
        print('User unlocked the Big Boss level.');
        break;
      case productIdSubscription:
        // Activate the season pass. This state should be saved persistently with its expiry date.
        print('User subscribed to the Season Pass.');
        break;
    }
  }

  void dispose() {
    _subscription.cancel();
  }
}
