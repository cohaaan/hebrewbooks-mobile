import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hebrewbooks/providers/connection_provider.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

/// Helper class that wraps network requests with connection checking
class NetworkAwareFetch {
  /// Performs a GET request with connection detection
  static Future<http.Response> get(
    Uri uri,
    BuildContext context, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final connectionProvider =
        Provider.of<ConnectionProvider>(context, listen: false);

    try {
      final response = await http.get(uri, headers: headers).timeout(timeout);
      // Request succeeded - we have connection
      await connectionProvider.checkConnection();
      return response;
    } on SocketException {
      // No connection
      await connectionProvider.checkConnection();
      throw Exception('Connection error: No internet connection');
    } on TimeoutException {
      // Request timed out
      await connectionProvider.checkConnection();
      throw Exception('Request timed out: Server is not responding');
    } on Exception {
      // Other error, might be connection-related
      await connectionProvider.checkConnection();
      rethrow;
    }
  }

  /// Performs a network read with connection detection
  static Future<String> read(
    Uri uri,
    BuildContext context, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final response =
        await get(uri, context, headers: headers, timeout: timeout);
    return response.body;
  }
}
