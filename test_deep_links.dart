// Simple deep link test without async operations
import 'package:flutter/foundation.dart';
import 'package:travel_wisata_lokal/services/real_payment_service.dart';

void main() {
  debugPrint('🧪 Testing Deep Link Generation - Travel Wisata Lokal');
  debugPrint('=' * 60);

  final paymentService = RealPaymentService();

  // Test data
  const testPhone = '08123456789';
  const testAmount = '50000';
  const testDescription = 'Test Payment Travel Wisata';

  for (var method in PaymentMethod.values) {
    if (method == PaymentMethod.bankTransfer) continue;

    debugPrint('\n🔍 ${method.icon} ${method.displayName}');
    debugPrint('-' * 40);

    // Generate deep link
    final deepLink = method.getDeepLink(
      phoneNumber: testPhone,
      amount: testAmount,
      description: testDescription,
    );

    debugPrint('📱 Deep Link: $deepLink');

    // Show troubleshooting info
    final troubleshooting = paymentService.getTroubleshootingInfo(method);
    debugPrint('📦 Package ID: ${troubleshooting['packageId']}');
    debugPrint('💡 Issues: ${troubleshooting['commonIssues']}');
    debugPrint('🔄 Fallback: ${troubleshooting['fallback']}');
  }

  debugPrint('\n${'=' * 60}');
  debugPrint('✅ Deep Link Generation Test Complete!');
  debugPrint('\n📋 Manual Testing Steps:');
  debugPrint('1. Copy deep link dari output di atas');
  debugPrint('2. Paste ke browser atau app URL handler');
  debugPrint('3. Verify app terbuka dengan data yang benar');
  debugPrint('4. Test di device real dengan app e-wallet terinstall');
  debugPrint('\n🔧 Jika masih error "item tidak ditemukan":');
  debugPrint('- Update app e-wallet ke versi terbaru');
  debugPrint('- Coba format deep link alternatif');
  debugPrint('- Gunakan web-based payment (GoPay)');
  debugPrint('- Fallback ke manual transfer');
}
