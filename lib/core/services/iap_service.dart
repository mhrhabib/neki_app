import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../features/auth/domain/repositories/premium_repository.dart';
import '../../features/auth/data/repositories/support_repository_impl.dart';

/// Thin wrapper around `in_app_purchase` focused on community donations.
///
/// Donation products are consumables so users can give repeatedly.
/// A small set of legacy subscription IDs is kept for backward compatibility
/// with the old paywall surface — donation mode is the default.
class IAPService {
  IAPService(this._supportRepository, this._premiumRepository);

  final SupportRepository _supportRepository;
  final PremiumRepository _premiumRepository;
  final InAppPurchase _iap = InAppPurchase.instance;

  // ========= Donation Products =========
  static const String support1Id = 'neki_support_1';
  static const String support5Id = 'neki_support_5';
  static const String support10Id = 'neki_support_10';
  static const String support20Id = 'neki_support_20';

  // ========= Legacy subscription IDs (kept for back-compat with paywall screens) =========
  static const String monthlyId = 'neki_premium_monthly';
  static const String yearlyId = 'neki_premium_yearly';

  static const Set<String> _donationIds = {
    support1Id,
    support5Id,
    support10Id,
    support20Id,
  };

  static const Set<String> _legacySubscriptionIds = {monthlyId, yearlyId};

  /// Local mapping of donation product IDs → canonical amount. Used when
  /// the store price is unavailable (e.g. offline) so the ledger entry is
  /// still correct.
  static const Map<String, double> _donationAmounts = {
    support1Id: 1,
    support5Id: 5,
    support10Id: 10,
    support20Id: 20,
  };

  final List<ProductDetails> _products = [];
  final Set<String> _processedTransactions = <String>{};
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _initialized = false;
  Completer<void>? _initializeCompleter;

  List<ProductDetails> get products => List.unmodifiable(_products);

  List<ProductDetails> get donationProducts {
    final donations = _products.where((p) => _donationIds.contains(p.id)).toList();
    // Stable order for UI: $1, $5, $10, $20
    donations.sort(
      (a, b) => (_donationAmounts[a.id] ?? 0).compareTo(_donationAmounts[b.id] ?? 0),
    );
    return donations;
  }

  Future<void> initialize() async {
    if (_initialized) return;
    if (_initializeCompleter != null) return _initializeCompleter!.future;
    final completer = _initializeCompleter = Completer<void>();

    try {
      final available = await _iap.isAvailable();
      if (!available) {
        debugPrint('⚠️ [IAP] Store not available on this device.');
        _initialized = true;
        completer.complete();
        return;
      }

      _subscription = _iap.purchaseStream.listen(
        _onPurchaseUpdated,
        onDone: () => _subscription?.cancel(),
        onError: (error) {
          debugPrint('❌ [IAP] purchaseStream error: $error');
        },
      );

      await fetchProducts();
      _initialized = true;
      completer.complete();
    } catch (e, st) {
      debugPrint('❌ [IAP] Initialize failed: $e\n$st');
      completer.completeError(e, st);
      _initializeCompleter = null;
      rethrow;
    }
  }

  Future<void> fetchProducts() async {
    final ids = {..._donationIds, ..._legacySubscriptionIds};
    final response = await _iap.queryProductDetails(ids);
    if (response.error != null) {
      debugPrint('❌ [IAP] queryProductDetails error: ${response.error}');
    }
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('⚠️ [IAP] Product IDs not found: ${response.notFoundIDs}');
    }
    _products
      ..clear()
      ..addAll(response.productDetails);
  }

  /// Kicks off a donation purchase. Returns `true` when the purchase flow
  /// was launched successfully (completion happens asynchronously via
  /// [_onPurchaseUpdated]).
  Future<bool> buySupport(ProductDetails product) async {
    try {
      final param = PurchaseParam(productDetails: product);
      return await _iap.buyConsumable(purchaseParam: param);
    } catch (e) {
      debugPrint('❌ [IAP] buySupport failed: $e');
      return false;
    }
  }

  /// Convenience: look up a donation by product ID and start the purchase.
  Future<bool> buySupportById(String productId) async {
    final product = _findProduct(productId);
    if (product == null) {
      debugPrint('⚠️ [IAP] Product $productId not available.');
      return false;
    }
    return buySupport(product);
  }

  /// Legacy: non-consumable purchase used by the old premium paywall.
  /// Keeps older screens compiling while we pivot to donation mode.
  Future<bool> buyProduct(ProductDetails product) async {
    try {
      final param = PurchaseParam(productDetails: product);
      if (_donationIds.contains(product.id)) {
        return await _iap.buyConsumable(purchaseParam: param);
      }
      return await _iap.buyNonConsumable(purchaseParam: param);
    } catch (e) {
      debugPrint('❌ [IAP] buyProduct failed: $e');
      return false;
    }
  }

  Future<void> restorePurchases() async {
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('❌ [IAP] restorePurchases failed: $e');
    }
  }

  ProductDetails? _findProduct(String id) {
    for (final p in _products) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<void> _onPurchaseUpdated(List<PurchaseDetails> list) async {
    for (final purchase in list) {
      await _handlePurchase(purchase);
    }
  }

  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    switch (purchase.status) {
      case PurchaseStatus.pending:
        return;
      case PurchaseStatus.error:
      case PurchaseStatus.canceled:
        debugPrint(
          '❌ [IAP] Purchase ${purchase.productID} ended: '
          '${purchase.status.name} ${purchase.error?.message ?? ''}',
        );
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        return;
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        final ok = await _verifyPurchase(purchase);
        if (ok) {
          await _grantPurchase(purchase);
        }
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        return;
    }
  }

  Future<void> _grantPurchase(PurchaseDetails purchase) async {
    final txId = _transactionKey(purchase);
    if (!_processedTransactions.add(txId)) {
      // Dedupe: same transaction can be delivered multiple times
      // (e.g. restore flows on iOS).
      return;
    }

    if (_donationIds.contains(purchase.productID)) {
      final amount = _resolveAmount(purchase.productID);
      await _supportRepository.recordDonation(
        productId: purchase.productID,
        amount: amount,
        transactionId: txId,
      );
      return;
    }

    if (_legacySubscriptionIds.contains(purchase.productID)) {
      await _premiumRepository.setPremium(true);
      return;
    }
  }

  double _resolveAmount(String productId) {
    final product = _findProduct(productId);
    if (product != null && product.rawPrice > 0) {
      return product.rawPrice.toDouble();
    }
    return _donationAmounts[productId] ?? 0;
  }

  String _transactionKey(PurchaseDetails purchase) {
    final id = purchase.purchaseID;
    if (id != null && id.isNotEmpty) return id;
    // Fallback: product + timestamp so two untracked purchases still dedupe
    // within the same second.
    return '${purchase.productID}_${purchase.transactionDate ?? DateTime.now().toIso8601String()}';
  }

  /// Lightweight client-side receipt presence check. Server-side validation
  /// should live in a callable Cloud Function before this ledger is trusted
  /// for anything user-facing (e.g. a supporter badge).
  Future<bool> _verifyPurchase(PurchaseDetails purchase) async {
    final verification = purchase.verificationData;
    return verification.serverVerificationData.isNotEmpty;
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
