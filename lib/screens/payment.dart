import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:get/get.dart';

class RazorpayPaymentPage extends StatefulWidget {
  @override
  _RazorpayPaymentPageState createState() => _RazorpayPaymentPageState();
}

class _RazorpayPaymentPageState extends State<RazorpayPaymentPage> {
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("✅ Payment successful: ${response.paymentId}")),
    );

    // ✅ Return success to previous screen
    Get.back(result: true);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("❌ Payment failed: ${response.message}")),
    );

    // ❌ Return failure
    Get.back(result: false);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("💳 Wallet selected: ${response.walletName}")),
    );
  }

  void openCheckout() {
    var options = {
      'key': 'rzp_test_VjHWPLTIicf83I', // Replace with your Razorpay key
      'amount': 100, // ₹1 = 100 paise
      'name': 'AutoJobMail',
      'description': 'Unlock email limit for today',
      'prefill': {
        'contact': '9209355315',
        'email': 'khulapeshital8@gmail.com',
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: $e');
      Get.back(result: false); // Safely return on exception
    }
  }

  @override
  void dispose() {
    _razorpay.clear(); // Important!
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Pay ₹1 to Unlock Limit")),
      body: Center(
        child: ElevatedButton(
          onPressed: openCheckout,
          child: Text("Pay ₹1"),
        ),
      ),
    );
  }
}
