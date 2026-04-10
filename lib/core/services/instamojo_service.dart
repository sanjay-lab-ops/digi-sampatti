import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

// ─── Instamojo Payment Service ──────────────────────────────────────────────
// Fallback payment gateway — activates same day, no business category issues.
// Flow: create payment request → get URL → open in browser → webhook confirms.
//
// Docs: https://docs.instamojo.com/docs/creating-a-payment-request
// Test base: https://test.instamojo.com/api/1.1/
// Live base: https://www.instamojo.com/api/1.1/
// ───────────────────────────────────────────────────────────────────────────

class InstamojoService {
  static final InstamojoService _instance = InstamojoService._internal();
  factory InstamojoService() => _instance;
  InstamojoService._internal();

  static const bool _testMode = false; // LIVE keys — www.instamojo.com
  static const String _apiKey    = 'eb8569cf677c296bddfe91df0ef50452';
  static const String _authToken = 'ebd995857617ee96519bb5f961412e67';
  static const String _privateSalt = 'a29ef5e7f0ce4b41802c8e1b13123673'; // for webhook verification

  String get _baseUrl => _testMode
      ? 'https://test.instamojo.com/api/1.1'
      : 'https://www.instamojo.com/api/1.1';

  Map<String, String> get _headers => {
    'X-Api-Key': _apiKey,
    'X-Auth-Token': _authToken,
    'Content-Type': 'application/x-www-form-urlencoded',
  };

  // ─── Create a payment request and open in browser ─────────────────────────
  // Returns the payment request ID (save this to verify later)
  Future<InstamojoPaymentRequest?> createAndOpenPayment({
    required int amountInRupees,
    required String buyerName,
    required String buyerPhone,
    required String buyerEmail,
    required String purpose,     // e.g. "DigiSampatti Report - Survey 67"
    String? redirectUrl,         // your webhook / thank-you URL
  }) async {
    try {
      final body = {
        'purpose': purpose,
        'amount': amountInRupees.toString(),
        'buyer_name': buyerName.isNotEmpty ? buyerName : 'Customer',
        'phone': buyerPhone,
        'email': buyerEmail.isNotEmpty ? buyerEmail : 'noreply@digisampatti.in',
        'send_email': 'false',
        'send_sms': 'false',
        'allow_repeated_payments': 'false',
        if (redirectUrl != null) 'redirect_url': redirectUrl,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/payment-requests/'),
        headers: _headers,
        body: body,
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final req = data['payment_request'] as Map<String, dynamic>;

        final paymentUrl = req['longurl']?.toString();
        final requestId  = req['id']?.toString();

        if (paymentUrl != null) {
          await _openUrl(paymentUrl);
        }

        return InstamojoPaymentRequest(
          id: requestId ?? '',
          url: paymentUrl ?? '',
          amount: amountInRupees,
          purpose: purpose,
          status: req['status']?.toString() ?? 'Pending',
        );
      }
    } catch (_) {}
    return null;
  }

  // ─── Check payment status ─────────────────────────────────────────────────
  // Call this after the user returns from browser to confirm payment
  Future<InstamojoPaymentStatus> checkPaymentStatus(String requestId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/payment-requests/$requestId/'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final req  = data['payment_request'] as Map<String, dynamic>;
        final payments = req['payments'] as List? ?? [];

        if (payments.isNotEmpty) {
          final latest = payments.first as Map<String, dynamic>;
          final status = latest['status']?.toString() ?? '';
          return InstamojoPaymentStatus(
            paid: status == 'Credit',
            paymentId: latest['payment_id']?.toString(),
            amount: double.tryParse(latest['amount']?.toString() ?? ''),
            status: status,
          );
        }
        return InstamojoPaymentStatus(
          paid: false,
          status: req['status']?.toString() ?? 'Pending',
        );
      }
    } catch (_) {}
    return const InstamojoPaymentStatus(paid: false, status: 'Error');
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ─── Models ──────────────────────────────────────────────────────────────────

class InstamojoPaymentRequest {
  final String id;
  final String url;
  final int amount;
  final String purpose;
  final String status;

  const InstamojoPaymentRequest({
    required this.id,
    required this.url,
    required this.amount,
    required this.purpose,
    required this.status,
  });
}

class InstamojoPaymentStatus {
  final bool paid;
  final String? paymentId;
  final double? amount;
  final String status;

  const InstamojoPaymentStatus({
    required this.paid,
    this.paymentId,
    this.amount,
    required this.status,
  });
}
