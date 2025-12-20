import 'package:flutter/material.dart';
import 'package:travel_wisata_lokal/services/real_payment_service.dart';

class PaymentDebugPage extends StatefulWidget {
  const PaymentDebugPage({super.key});

  @override
  State<PaymentDebugPage> createState() => _PaymentDebugPageState();
}

class _PaymentDebugPageState extends State<PaymentDebugPage> {
  final RealPaymentService _paymentService = RealPaymentService();
  List<Map<String, dynamic>> _testResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _runDeepLinkTests();
  }

  Future<void> _runDeepLinkTests() async {
    setState(() => _isLoading = true);

    List<Map<String, dynamic>> results = [];

    for (var method in PaymentMethod.values) {
      if (method != PaymentMethod.bankTransfer) {
        // Skip bank transfer
        final result = await _paymentService.testDeepLink(method);
        results.add(result);
      }
    }

    setState(() {
      _testResults = results;
      _isLoading = false;
    });
  }

  Future<void> _testSingleMethod(PaymentMethod method) async {
    final result = await _paymentService.testDeepLink(method);

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Test ${method.displayName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Deep Link: ${result['deepLink']}'),
              const SizedBox(height: 8),
              Text('Can Launch: ${result['canLaunch']}'),
              Text('App Installed: ${result['isInstalled']}'),
              if (result.containsKey('error'))
                Text(
                  'Error: ${result['error']}',
                  style: const TextStyle(color: Colors.red),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            if (result['canLaunch'] == true)
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _paymentService.openPaymentApp(
                    method: method,
                    phoneNumber: '08123456789',
                    amount: '10000',
                    description: 'Test Payment',
                  );
                },
                child: const Text('Test Launch'),
              ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _runDeepLinkTests,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _testResults.length,
              itemBuilder: (context, index) {
                final result = _testResults[index];
                final method = PaymentMethod.values.firstWhere(
                  (m) => m.displayName == result['method'],
                );

                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: Text(
                      method.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(result['method']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Can Launch: ${result['canLaunch']}',
                          style: TextStyle(
                            color: result['canLaunch']
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        Text(
                          'App Installed: ${result['isInstalled']}',
                          style: TextStyle(
                            color: result['isInstalled']
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                        if (result.containsKey('error'))
                          Text(
                            'Error: ${result['error']}',
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.play_arrow),
                      onPressed: () => _testSingleMethod(method),
                    ),
                    onTap: () => _showTroubleshootingInfo(method),
                  ),
                );
              },
            ),
    );
  }

  void _showTroubleshootingInfo(PaymentMethod method) {
    final info = _paymentService.getTroubleshootingInfo(method);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Troubleshooting ${method.displayName}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('App Name', info['appName']!),
              _buildInfoRow('Package ID', info['packageId']!),
              _buildInfoRow('Deep Link Format', info['deepLinkFormat']!),
              _buildInfoRow('Fallback', info['fallback']!),
              _buildInfoRow('Common Issues', info['commonIssues']!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          Text(value, style: const TextStyle(fontSize: 14)),
          const Divider(),
        ],
      ),
    );
  }
}
