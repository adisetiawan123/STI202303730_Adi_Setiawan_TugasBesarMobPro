// Midtrans configuration (development only)
// IMPORTANT:
// - Do NOT commit `SERVER_KEY` to a public repository. Server key must be kept on your backend.
// - Prefer storing `CLIENT_KEY` in secure storage or fetch from your backend/remote config in production.
// - This file is provided as a convenience for local development only.

class MidtransConfig {
  // Merchant / Client / Server keys (inserted here for development/testing)
  // Replace values below with your keys, but do NOT commit the final keys to VCS.
  static const String merchantId = 'G487604681';
  static const String clientKey = 'Mid-client-5HWjnJPMorhNtiXG';
  // Server key MUST NOT be included in the client for production. Keep it on your server.
  static const String serverKey = 'YOUR_SERVER_KEY';

  // Midtrans endpoints
  static const String apiBaseUrlProduction = 'https://api.midtrans.com/v2';
  static const String apiBaseUrlSandbox = 'https://api.sandbox.midtrans.com/v2';

  // Toggle to sandbox for testing
  static const bool useSandbox = true;

  static String get apiBaseUrl =>
      useSandbox ? apiBaseUrlSandbox : apiBaseUrlProduction;

  // Optional: backend endpoint that creates Midtrans transaction and returns
  // a `token` or `redirect_url`. Set this to your backend in production.
  // Example: 'https://your-backend.example.com/midtrans/create-transaction'
  // Default local dev backend URL (Android emulator uses 10.0.2.2 to reach host)
  // Change this to your deployed backend in production.
  static const String backendCreateTransactionUrl =
      'http://10.0.2.2:3000/midtrans/create-transaction';
}
