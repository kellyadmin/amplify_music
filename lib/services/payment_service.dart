import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/platform_utils_mobile.dart' if (dart.library.html) '../utils/platform_utils_web.dart';

const String supabaseFunctionUrl = 'https://conhbihmsgdujpwhperh.supabase.co/functions/v1/create-payment-request';
const String debugSupabaseFunctionUrl = 'https://conhbihmsgdujpwhperh.supabase.co/functions/v1/create-payment-debug';
const bool useDebugPaymentFunction = false;

Future<Map<String, dynamic>> initiatePesapalPayment({
  required String orderId,
  required double amount,
  required String currency,
  required String email,
  required String phone,
  String? functionUrl,
}) async {
  final String chosenFunctionUrl = functionUrl ?? (useDebugPaymentFunction ? debugSupabaseFunctionUrl : supabaseFunctionUrl);

  if (kIsWeb) {
    try {
      PlatformUtils.openPopup('about:blank');
    } catch (e) {
      debugPrint('[Payment] popup open (initial) failed: $e');
    }
  }

  try {
    final Map<String, dynamic> payload = {
      'orderId': orderId,
      'amount': amount,
      'currency': currency,
      'email': email,
      'phone': phone,
    };

    final String token = Supabase.instance.client.auth.currentSession?.accessToken ?? '';

    String _masked(String t) {
      if (t.isEmpty) return '<empty>';
      return t.length > 12 ? '${t.substring(0, 6)}...${t.substring(t.length - 6)}' : t;
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    final uri = Uri.parse(chosenFunctionUrl);
    debugPrint('[Payment] POST $uri');
    debugPrint('[Payment] payload: ${jsonEncode(payload)}');
    debugPrint('[Payment] Authorization header included: ${token.isNotEmpty} masked=${_masked(token)}');

    final http.Response response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(payload),
    );

    debugPrint('[Payment] response status=${response.statusCode} body=${response.body}');

    if (response.statusCode == 401) {
      return {
        'success': false,
        'message': 'Unauthorized (401). Ensure you are signed in and token is valid.',
        'status': response.statusCode,
        'body': response.body,
      };
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic>? responseBody =
      response.body.isNotEmpty ? jsonDecode(response.body) as Map<String, dynamic>? : null;

      final String? redirectUrl = responseBody == null
          ? null
          : (responseBody['redirect_url'] as String? ?? responseBody['redirectUrl'] as String?);

      if (redirectUrl != null && redirectUrl.isNotEmpty) {
        try {
          PlatformUtils.openPopup(redirectUrl);
          return {'success': true, 'message': 'Opened payment in a new tab.'};
        } catch (e) {
          debugPrint('[Payment] Could not open payment URL: $e');

          final Uri? parsed = Uri.tryParse(redirectUrl);
          if (parsed != null && await canLaunchUrl(parsed)) {
            await launchUrl(parsed, mode: LaunchMode.externalApplication);
            return {'success': true, 'message': 'Redirecting to payment...'};
          } else {
            return {'success': false, 'message': 'Could not launch payment URL.'};
          }
        }
      } else {
        debugPrint('[Payment] redirect_url missing in function response: $responseBody');
        return {'success': false, 'message': 'Payment server error (no redirect URL).', 'response': responseBody};
      }
    } else {
      debugPrint('[Payment] unexpected status ${response.statusCode} body=${response.body}');
      return {'success': false, 'message': 'Payment server failed (${response.statusCode}).', 'body': response.body};
    }
  } catch (e, st) {
    debugPrint('[Payment] error: $e\n$st');
    return {'success': false, 'message': 'Network error. Please try again.', 'error': e.toString()};
  }
}
