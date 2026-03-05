import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'http://localhost:5000/api';
  String? _token;

  void setToken(String token) {
    _token = token;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // ─── Auth ───
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: _headers,
      body: jsonEncode(<String, dynamic>{
        'email': email,
        'password': password,
        'full_name': fullName,
        if (phone != null) 'phone': phone,
      }),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String userId,
    required String otp,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/verify-otp'),
      headers: _headers,
      body: jsonEncode({'user_id': userId, 'otp_code': otp}),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // ─── Memberships ───
  Future<List<dynamic>> getMemberships() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/memberships'),
      headers: _headers,
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['memberships'] as List<dynamic>? ?? [];
  }

  // ─── Benefits ───
  Future<List<dynamic>> getBenefits({bool verifiedOnly = false}) async {
    final uri = Uri.parse('$_baseUrl/benefits')
        .replace(queryParameters: {
      if (verifiedOnly) 'verified_only': 'true',
    });
    final response = await http.get(uri, headers: _headers);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['benefits'] as List<dynamic>? ?? [];
  }

  Future<List<dynamic>> getNearbyBenefits({double radiusKm = 5.0}) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/benefits/nearby?radius_km=$radiusKm'),
      headers: _headers,
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['benefits'] as List<dynamic>? ?? [];
  }

  Future<Map<String, dynamic>> verifyBenefit(String benefitId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/benefits/$benefitId/verify'),
      headers: _headers,
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // ─── Location ───
  Future<Map<String, dynamic>> updateLocation({
    required double latitude,
    required double longitude,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/location/update'),
      headers: _headers,
      body: jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
      }),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<dynamic>> getNearbyMerchants({double distanceKm = 5.0}) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/merchants/nearby?distance_km=$distanceKm'),
      headers: _headers,
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['merchants'] as List<dynamic>? ?? [];
  }

  // ─── Alerts ───
  Future<List<dynamic>> getPendingAlerts() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/alerts/pending'),
      headers: _headers,
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['alerts'] as List<dynamic>? ?? [];
  }

  Future<Map<String, dynamic>> claimBenefit(String alertId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/alerts/$alertId/claim'),
      headers: _headers,
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> dismissAlert(String alertId) async {
    await http.post(
      Uri.parse('$_baseUrl/alerts/$alertId/dismiss'),
      headers: _headers,
    );
  }

  // ─── Analytics ───
  Future<Map<String, dynamic>> getAnalyticsSummary() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/analytics/summary'),
      headers: _headers,
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
