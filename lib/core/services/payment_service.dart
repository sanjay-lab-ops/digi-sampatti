import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:digi_sampatti/core/services/instamojo_service.dart';

// ─── Payment Service ──────────────────────────────────────────────────────────
// Priority:  1. Razorpay (when live key is active)
//            2. Cashfree (when activated — wire separately)
//            3. Instamojo (fallback — works immediately, same-day KYC)
//
// To switch gateway: change _activeGateway below.
// ─────────────────────────────────────────────────────────────────────────────

enum PaymentGateway { razorpay, instamojo }

class PaymentService {
  // ── Change this to .instamojo while Razorpay "Business not supported" is unresolved
  static const PaymentGateway _activeGateway = PaymentGateway.instamojo;

  // Razorpay — switch to live key (rzp_live_...) once KYC clears
  static const String _razorpayKeyId = 'rzp_test_STzj4B5S21m18M';
  static const int reportPrice = 149;

  late Razorpay _razorpay;

  void Function(String paymentId)? onSuccess;
  void Function(String error)? onFailure;

  void initialize() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS,
        (PaymentSuccessResponse r) => onSuccess?.call(r.paymentId ?? ''));
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR,
        (PaymentFailureResponse r) => onFailure?.call(r.message ?? 'Payment failed'));
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (_) {});
  }

  // ─── Open payment for a report ─────────────────────────────────────────────
  Future<String?> openReportPayment({
    required String reportId,
    required String userPhone,
    String userName = 'Customer',
    String userEmail = '',
    int? customAmount,
  }) async {
    final amount = customAmount ?? reportPrice;

    if (_activeGateway == PaymentGateway.razorpay) {
      _openRazorpay(
        amount: amount,
        phone: userPhone,
        description: 'DigiSampatti Report #$reportId',
        notes: {'report_id': reportId},
      );
      return null; // result comes via onSuccess/onFailure callbacks
    } else {
      // Instamojo — opens browser, returns request ID for status polling
      final req = await InstamojoService().createAndOpenPayment(
        amountInRupees: amount,
        buyerName: userName,
        buyerPhone: userPhone,
        buyerEmail: userEmail,
        purpose: 'DigiSampatti Property Report #$reportId',
      );
      return req?.id; // save this to call checkPaymentStatus() after user returns
    }
  }

  // ─── Poll Instamojo status after user returns from browser ─────────────────
  Future<bool> verifyInstamojoPayment(String requestId) async {
    final status = await InstamojoService().checkPaymentStatus(requestId);
    if (status.paid) {
      onSuccess?.call(status.paymentId ?? requestId);
      return true;
    }
    return false;
  }

  void _openRazorpay({
    required int amount,
    required String phone,
    required String description,
    Map<String, dynamic>? notes,
  }) {
    _razorpay.open({
      'key': _razorpayKeyId,
      'amount': amount * 100,
      'name': 'DigiSampatti',
      'description': description,
      'prefill': {'contact': phone},
      'theme': {'color': '#1B5E20'},
      'retry': {'enabled': false},
      if (notes != null) 'notes': notes,
    });
  }

  void dispose() {
    _razorpay.clear();
  }
}
