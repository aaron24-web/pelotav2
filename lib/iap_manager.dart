import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'components/shop.dart';

// Placeholder product IDs. Replace with your actual IDs from the stores.
const String productIdConsumable = 'pack_1000_monedas';
const String productIdNonConsumable = 'desbloqueo_jefe';
const String productIdSubscription = 'pase_temporada';

class IAPManager {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  
  final List<ProductDetails> _products = [];
  bool _isAvailable = false;
  ShopManager? _shopManager;

  // Singleton pattern
  IAPManager._privateConstructor();
  static final IAPManager _instance = IAPManager._privateConstructor();
  static IAPManager get instance => _instance;

  void setShopManager(ShopManager manager) {
    _shopManager = manager;
  }

  Future<void> init() async {
    _isAvailable = await _inAppPurchase.isAvailable();
    if (!_isAvailable) {
      // Handle store not available
      if (kDebugMode) {
        print("In-app purchases not available. Using mock data.");
        _loadMockProducts();
      }
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
      if (kDebugMode) {
        print("Some products not found in store. Using mock data for UI.");
        _loadMockProducts();
        return;
      }
    }
    _products.clear();
    _products.addAll(response.productDetails);
  }

  void _loadMockProducts() {
    _products.clear();
    _products.addAll([
      ProductDetails(
        id: productIdConsumable,
        title: 'Paquete de 1000 Monedas',
        description: 'Compra 1000 monedas para usar en la tienda.',
        price: '\$0.99',
        rawPrice: 0.99,
        currencyCode: 'USD',
      ),
      ProductDetails(
        id: productIdNonConsumable,
        title: 'Desbloquear Nivel Jefe',
        description: 'Acceso permanente al nivel del Jefe Final.',
        price: '\$4.99',
        rawPrice: 4.99,
        currencyCode: 'USD',
      ),
      ProductDetails(
        id: productIdSubscription,
        title: 'Pase de Temporada',
        description: 'Obtén un multiplicador de puntaje x2.',
        price: '\$2.99/mes',
        rawPrice: 2.99,
        currencyCode: 'USD',
      ),
    ]);
  }

  List<ProductDetails> get products => _products;

  Future<void> buyProduct(ProductDetails productDetails) async {
    if (!_isAvailable) {
      if (kDebugMode) {
        print("Cannot buy product, store is not available. Simulating purchase.");
        // Simulate purchase for debugging without a real store.
        await _handleCompletedPurchase(PurchaseDetails(
          productID: productDetails.id,
          status: PurchaseStatus.purchased,
          verificationData: PurchaseVerificationData(localVerificationData: '', serverVerificationData: '', source: ''),
          transactionDate: DateTime.now().millisecondsSinceEpoch.toString(),
        ));
      }
      return;
    }

    final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
    if (productDetails.id == productIdConsumable) {
      _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
    }
    else {
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
    if (_shopManager == null) return;

    switch (purchaseDetails.productID) {
      case productIdConsumable:
        await _shopManager!.updateCoins(1000);
        if (kDebugMode) {
          print('User purchased 1000 coins.');
        }
        break;
      case productIdNonConsumable:
        _shopManager!.bossLevelUnlocked = true;
        // In a real app, you would save this to persistent storage (e.g., Supabase)
        if (kDebugMode) {
          print('User unlocked the Big Boss level.');
        }
        break;
      case productIdSubscription:
        _shopManager!.seasonPassActive = true;
        // In a real app, you would save this to persistent storage with an expiry date
        if (kDebugMode) {
          print('User subscribed to the Season Pass.');
        }
        break;
    }
  }

  void dispose() {
    _subscription.cancel();
  }
}
