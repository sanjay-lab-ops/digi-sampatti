import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentService {
  static const _keyId = 'rzp_test_SUCAitD1ynKR3F';
  static const int reportPrice = 99; // ₹99 per report

  late Razorpay _razorpay;

  void Function(PaymentSuccessResponse)? onSuccess;
  void Function(PaymentFailureResponse)? onFailure;
  void Function(ExternalWalletResponse)? onWallet;

  void initialize() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleFailure);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleWallet);
  }

  void openPayment({
    required String reportId,
    required String userPhone,
    String description = 'DigiSampatti Property Report',
  }) {
    final options = {
      'key': _keyId,
      'amount': reportPrice * 100, // paise
      'name': 'DigiSampatti',
      'description': description,
      'prefill': {
        'contact': userPhone,
      },
      'theme': {'color': '#1B5E20'},
      'retry': {'enabled': false},
      'notes': {'report_id': reportId},
    };
    _razorpay.open(options);
  }

  void _handleSuccess(PaymentSuccessResponse response) {
    onSuccess?.call(response);
  }

  void _handleFailure(PaymentFailureResponse response) {
    onFailure?.call(response);
  }

  void _handleWallet(ExternalWalletResponse response) {
    onWallet?.call(response);
  }

  void dispose() {
    _razorpay.clear();
  }
}
