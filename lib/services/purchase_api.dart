// lib/services/purchase_api.dart

import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'dart:io';

class PurchaseApi {
  // RevenueCat sitesinden alacağın API Keyler buraya:
  static const _apiKeyAndroid = 'goog_...BURAYA_REVENUECAT_ANDROID_KEY...';
  static const _apiKeyIOS = 'appl_...BURAYA_REVENUECAT_IOS_KEY...';

  static Future<void> init() async {
    await Purchases.setLogLevel(LogLevel.debug);

    PurchasesConfiguration configuration;
    if (Platform.isAndroid) {
      configuration = PurchasesConfiguration(_apiKeyAndroid);
    } else {
      configuration = PurchasesConfiguration(_apiKeyIOS);
    }
    
    await Purchases.configure(configuration);
  }

  // Mevcut Paketleri (Fiyatları) Getir
  static Future<List<Offering>> fetchOffers() async {
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      return current == null ? [] : [current];
    } on PlatformException catch (_) {
      return [];
    }
  }

  // Satın Alma İşlemi
  static Future<bool> purchasePackage(Package package) async {
    try {
      CustomerInfo customerInfo = await Purchases.purchasePackage(package);
      // "premium" senin RevenueCat'te oluşturduğun Entitlement ID'si olmalı
      return customerInfo.entitlements.all["premium"]?.isActive ?? false;
    } catch (e) {
      return false;
    }
  }
  
  // Satın Almaları Geri Yükle (Restore)
  static Future<bool> restorePurchases() async {
    try {
      CustomerInfo customerInfo = await Purchases.restorePurchases();
      return customerInfo.entitlements.all["premium"]?.isActive ?? false;
    } catch (e) {
      return false;
    }
  }
}