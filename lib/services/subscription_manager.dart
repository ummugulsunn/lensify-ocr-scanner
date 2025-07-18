import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

/// Subscription tipleri
enum SubscriptionPlan {
  free,
  pro,
  premium,
}

/// Subscription manager - In-app purchase işlemlerini yönetir
class SubscriptionManager {
  static final SubscriptionManager _instance = SubscriptionManager._internal();
  factory SubscriptionManager() => _instance;
  SubscriptionManager._internal();

  static SubscriptionManager get instance => _instance;

  // In-App Purchase instance
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  
  // Stream subscription
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  
  // Current subscription state
  SubscriptionPlan _currentPlan = SubscriptionPlan.free;
  bool _isInitialized = false;
  bool _isAvailable = false;
  
  // Product IDs (Google Play Console'da tanımlanacak)
  static const String _proMonthlyProductId = 'pro_monthly_subscription';
  static const String _proYearlyProductId = 'pro_yearly_subscription';
  static const String _premiumMonthlyProductId = 'premium_monthly_subscription';
  static const String _premiumYearlyProductId = 'premium_yearly_subscription';
  
  // All subscription product IDs
  static const Set<String> _productIds = {
    _proMonthlyProductId,
    _proYearlyProductId,
    _premiumMonthlyProductId,
    _premiumYearlyProductId,
  };
  
  // Available products
  List<ProductDetails> _products = [];
  
  // Listeners
  final List<VoidCallback> _subscriptionChangeListeners = [];

  /// Initialize subscription manager
  Future<void> initialize() async {
    try {
      developer.log('Initializing SubscriptionManager...', name: 'SubscriptionManager');
      
      // Check if in-app purchase is available
      _isAvailable = await _inAppPurchase.isAvailable();
      developer.log('In-app purchase available: $_isAvailable', name: 'SubscriptionManager');
      
      if (!_isAvailable) {
        developer.log('In-app purchase not available on this device', name: 'SubscriptionManager');
        _isInitialized = true;
        return;
      }
      
      // Listen to purchase updates
      _subscription = _inAppPurchase.purchaseStream.listen(
        _handlePurchaseUpdate,
        onDone: () => developer.log('Purchase stream closed', name: 'SubscriptionManager'),
        onError: (error) => developer.log('Purchase stream error: $error', name: 'SubscriptionManager'),
      );
      
      // Load products
      await _loadProducts();
      
      // Restore purchases
      await _restorePurchases();
      
      _isInitialized = true;
      developer.log('SubscriptionManager initialized successfully', name: 'SubscriptionManager');
    } catch (e) {
      developer.log('Error initializing SubscriptionManager: $e', name: 'SubscriptionManager');
      _isInitialized = true; // Set to true to prevent hanging
    }
  }

  /// Load available products from store
  Future<void> _loadProducts() async {
    try {
      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(_productIds);
      
      if (response.error != null) {
        developer.log('Error loading products: ${response.error}', name: 'SubscriptionManager');
        return;
      }
      
      _products = response.productDetails;
      developer.log('Loaded ${_products.length} products', name: 'SubscriptionManager');
      
      for (final product in _products) {
        developer.log('Product: ${product.id} - ${product.title} - ${product.price}', name: 'SubscriptionManager');
      }
    } catch (e) {
      developer.log('Exception loading products: $e', name: 'SubscriptionManager');
    }
  }

  /// Restore previous purchases
  Future<void> _restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
      developer.log('Purchases restored', name: 'SubscriptionManager');
    } catch (e) {
      developer.log('Error restoring purchases: $e', name: 'SubscriptionManager');
    }
  }

  /// Handle purchase updates
  void _handlePurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      developer.log('Purchase update: ${purchaseDetails.productID} - ${purchaseDetails.status}', name: 'SubscriptionManager');
      
      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          _handlePendingPurchase(purchaseDetails);
          break;
        case PurchaseStatus.purchased:
          await _handleSuccessfulPurchase(purchaseDetails);
          break;
        case PurchaseStatus.error:
          _handleFailedPurchase(purchaseDetails);
          break;
        case PurchaseStatus.restored:
          await _handleRestoredPurchase(purchaseDetails);
          break;
        case PurchaseStatus.canceled:
          _handleCanceledPurchase(purchaseDetails);
          break;
      }
      
      // Complete the purchase
      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  /// Handle pending purchase
  void _handlePendingPurchase(PurchaseDetails purchaseDetails) {
    developer.log('Purchase pending: ${purchaseDetails.productID}', name: 'SubscriptionManager');
    // Show loading indicator if needed
  }

  /// Handle successful purchase
  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchaseDetails) async {
    developer.log('Purchase successful: ${purchaseDetails.productID}', name: 'SubscriptionManager');
    
    // Update subscription status
    final plan = _getSubscriptionPlanFromProductId(purchaseDetails.productID);
    await _updateSubscriptionStatus(plan);
    
    // Save purchase info
    await _savePurchaseInfo(purchaseDetails);
    
    // Notify listeners
    _notifySubscriptionChange();
  }

  /// Handle failed purchase
  void _handleFailedPurchase(PurchaseDetails purchaseDetails) {
    developer.log('Purchase failed: ${purchaseDetails.productID} - ${purchaseDetails.error}', name: 'SubscriptionManager');
    // Show error message if needed
  }

  /// Handle restored purchase
  Future<void> _handleRestoredPurchase(PurchaseDetails purchaseDetails) async {
    developer.log('Purchase restored: ${purchaseDetails.productID}', name: 'SubscriptionManager');
    
    // Update subscription status
    final plan = _getSubscriptionPlanFromProductId(purchaseDetails.productID);
    await _updateSubscriptionStatus(plan);
    
    // Notify listeners
    _notifySubscriptionChange();
  }

  /// Handle canceled purchase
  void _handleCanceledPurchase(PurchaseDetails purchaseDetails) {
    developer.log('Purchase canceled: ${purchaseDetails.productID}', name: 'SubscriptionManager');
    // Handle cancellation if needed
  }

  /// Get subscription plan from product ID
  SubscriptionPlan _getSubscriptionPlanFromProductId(String productId) {
    switch (productId) {
      case _proMonthlyProductId:
      case _proYearlyProductId:
        return SubscriptionPlan.pro;
      case _premiumMonthlyProductId:
      case _premiumYearlyProductId:
        return SubscriptionPlan.premium;
      default:
        return SubscriptionPlan.free;
    }
  }

  /// Update subscription status
  Future<void> _updateSubscriptionStatus(SubscriptionPlan plan) async {
    _currentPlan = plan;
    
    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('subscription_plan', plan.name);
    await prefs.setInt('subscription_timestamp', DateTime.now().millisecondsSinceEpoch);
    
    developer.log('Subscription updated to: ${plan.name}', name: 'SubscriptionManager');
  }

  /// Save purchase information
  Future<void> _savePurchaseInfo(PurchaseDetails purchaseDetails) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_purchase_id', purchaseDetails.purchaseID ?? '');
    await prefs.setString('last_purchase_product', purchaseDetails.productID);
    await prefs.setInt('last_purchase_timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  /// Purchase a subscription
  Future<bool> purchaseSubscription(String productId) async {
    if (!_isAvailable || !_isInitialized) {
      developer.log('Purchase not available', name: 'SubscriptionManager');
      return false;
    }
    
    final product = _products.firstWhere(
      (p) => p.id == productId,
      orElse: () => throw Exception('Product not found: $productId'),
    );
    
    try {
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
      
      if (Platform.isIOS) {
        await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      } else {
        await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      }
      
      return true;
    } catch (e) {
      developer.log('Error purchasing subscription: $e', name: 'SubscriptionManager');
      return false;
    }
  }

  /// Get available products
  List<ProductDetails> getAvailableProducts() {
    return _products;
  }

  /// Get Pro monthly product
  ProductDetails? getProMonthlyProduct() {
    return _products.firstWhere(
      (p) => p.id == _proMonthlyProductId,
      orElse: () => throw Exception('Pro monthly product not found'),
    );
  }

  /// Get Pro yearly product
  ProductDetails? getProYearlyProduct() {
    return _products.firstWhere(
      (p) => p.id == _proYearlyProductId,
      orElse: () => throw Exception('Pro yearly product not found'),
    );
  }

  /// Get current subscription plan
  SubscriptionPlan getCurrentPlan() {
    return _currentPlan;
  }

  /// Check if user has Pro subscription
  bool get isProUser => _currentPlan == SubscriptionPlan.pro || _currentPlan == SubscriptionPlan.premium;

  /// Check if user has Premium subscription
  bool get isPremiumUser => _currentPlan == SubscriptionPlan.premium;

  /// Check if subscription manager is initialized
  bool get isInitialized => _isInitialized;

  /// Check if in-app purchase is available
  bool get isAvailable => _isAvailable;

  /// Add subscription change listener
  void addSubscriptionChangeListener(VoidCallback listener) {
    _subscriptionChangeListeners.add(listener);
  }

  /// Remove subscription change listener
  void removeSubscriptionChangeListener(VoidCallback listener) {
    _subscriptionChangeListeners.remove(listener);
  }

  /// Notify subscription change listeners
  void _notifySubscriptionChange() {
    for (final listener in _subscriptionChangeListeners) {
      try {
        listener();
      } catch (e) {
        developer.log('Error in subscription change listener: $e', name: 'SubscriptionManager');
      }
    }
  }

  /// Load subscription status from storage
  Future<void> loadSubscriptionStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final planName = prefs.getString('subscription_plan');
      
      if (planName != null) {
        _currentPlan = SubscriptionPlan.values.firstWhere(
          (plan) => plan.name == planName,
          orElse: () => SubscriptionPlan.free,
        );
      }
      
      developer.log('Loaded subscription status: ${_currentPlan.name}', name: 'SubscriptionManager');
    } catch (e) {
      developer.log('Error loading subscription status: $e', name: 'SubscriptionManager');
      _currentPlan = SubscriptionPlan.free;
    }
  }

  /// Dispose subscription manager
  void dispose() {
    _subscription.cancel();
    _subscriptionChangeListeners.clear();
    developer.log('SubscriptionManager disposed', name: 'SubscriptionManager');
  }
} 