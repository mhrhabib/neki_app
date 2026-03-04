import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../features/auth/domain/repositories/premium_repository.dart';

class IAPService {
  final InAppPurchase _iap = InAppPurchase.instance;
  final PremiumRepository _premiumRepository;

  static const String monthlyId = 'neki_premium_monthly';
  static const String yearlyId = 'neki_premium_yearly';

  final Set<String> _kIds = {monthlyId, yearlyId};

  List<ProductDetails> _products = [];
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  IAPService(this._premiumRepository);

  Future<void> initialize() async {
    final bool available = await _iap.isAvailable();
    if (!available) return;

    final Stream<List<PurchaseDetails>> purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen(
      (purchaseDetailsList) {
        _listenToPurchaseUpdated(purchaseDetailsList);
      },
      onDone: () {
        _subscription?.cancel();
      },
      onError: (error) {
        // Handle error
      },
    );

    await fetchProducts();
  }

  Future<void> fetchProducts() async {
    final ProductDetailsResponse response = await _iap.queryProductDetails(
      _kIds,
    );
    if (response.notFoundIDs.isNotEmpty) {
      // Handle not found IDs
    }
    _products = response.productDetails;
  }

  List<ProductDetails> get products => _products;

  Future<void> buyProduct(ProductDetails productDetails) async {
    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: productDetails,
    );
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  Future<void> _listenToPurchaseUpdated(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Show pending UI
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          // Handle error
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          final bool valid = await _verifyPurchase(purchaseDetails);
          if (valid) {
            await _premiumRepository.setPremium(true);
          }
        }

        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }
      }
    }
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // IMPORTANT: In a real app, verify the receipt on your backend.
    // For now, we trust the store's response.
    return true;
  }

  void dispose() {
    _subscription?.cancel();
  }
}
