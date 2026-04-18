import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/google_config.dart';

class PlaceSuggestion {
  final String placeId;
  final String mainText;
  final String secondaryText;

  const PlaceSuggestion({
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
  });
}

class PlaceDetails {
  final String formattedAddress;
  final double latitude;
  final double longitude;
  final String? city;

  const PlaceDetails({
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
    this.city,
  });
}

class PlacesDatasource {
  final Dio _client = Dio();

  /// Google Places `languageCode` only accepts two-letter language tags plus a
  /// small set of regional variants. Albanian "sq" is supported; we map the
  /// handful of locales we ship to safe values.
  static String _mapLanguage(String code) {
    switch (code) {
      case 'sq':
        return 'sq';
      case 'en':
        return 'en';
      case 'fr':
      default:
        return 'fr';
    }
  }

  Future<List<PlaceSuggestion>> autocomplete(
    String input, {
    String language = 'fr',
  }) async {
    final lang = _mapLanguage(language);
    if (input.trim().length < 3) return [];
    debugPrint('[places] calling autocomplete for "$input"');
    try {
      final r = await _client.post(
        'https://places.googleapis.com/v1/places:autocomplete',
        data: {
          'input': input,
          'languageCode': lang,
          'includedRegionCodes': ['xk'],
          'locationRestriction': {
            'rectangle': {
              'low': {'latitude': 41.85, 'longitude': 20.01},
              'high': {'latitude': 43.27, 'longitude': 21.81},
            },
          },
        },
        options: Options(headers: {
          'X-Goog-Api-Key': GoogleConfig.placesApiKey,
          'Content-Type': 'application/json',
        }),
      );
      final suggestions = (r.data['suggestions'] as List? ?? []);
      debugPrint('[places] OK: ${suggestions.length} results for "$input"');
      return suggestions.map((s) {
        final p = s['placePrediction'] as Map<String, dynamic>;
        final struct = p['structuredFormat'] as Map<String, dynamic>?;
        return PlaceSuggestion(
          placeId: p['placeId'] as String,
          mainText: struct?['mainText']?['text'] as String? ??
              p['text']?['text'] as String? ??
              '',
          secondaryText:
              struct?['secondaryText']?['text'] as String? ?? '',
        );
      }).toList();
    } on DioException catch (e) {
      debugPrint('[places] FAILED ${e.response?.statusCode}: ${e.response?.data ?? e.message}');
      return [];
    } catch (e) {
      debugPrint('[places] ERROR: $e');
      return [];
    }
  }

  Future<PlaceDetails?> details(
    String placeId, {
    String language = 'fr',
  }) async {
    final lang = _mapLanguage(language);
    try {
      final r = await _client.get(
        'https://places.googleapis.com/v1/places/$placeId',
        queryParameters: {
          'fields': 'formattedAddress,location,addressComponents',
          'languageCode': lang,
        },
        options: Options(headers: {
          'X-Goog-Api-Key': GoogleConfig.placesApiKey,
        }),
      );
      final loc = r.data['location'] as Map<String, dynamic>;
      final comps = (r.data['addressComponents'] as List?) ?? [];
      String? city;
      String? postalCode;
      for (final c in comps) {
        final types = (c['types'] as List?)?.cast<String>() ?? const [];
        if (city == null &&
            (types.contains('locality') ||
                types.contains('postal_town') ||
                types.contains('administrative_area_level_2'))) {
          city = c['longText'] as String? ?? c['shortText'] as String?;
        }
        if (postalCode == null && types.contains('postal_code')) {
          postalCode = c['longText'] as String? ?? c['shortText'] as String?;
        }
      }
      final rawAddress = r.data['formattedAddress'] as String? ?? '';
      return PlaceDetails(
        formattedAddress: _stripPostalCode(rawAddress, postalCode),
        latitude: (loc['latitude'] as num).toDouble(),
        longitude: (loc['longitude'] as num).toDouble(),
        city: city,
      );
    } catch (_) {
      return null;
    }
  }

  static String _stripPostalCode(String address, String? postalCode) {
    var out = address;
    if (postalCode != null && postalCode.isNotEmpty) {
      out = out.replaceAll(postalCode, '');
    }
    // Collapse leftover ", ," / ",  ," / trailing commas / multi-spaces.
    out = out
        .replaceAll(RegExp(r',\s*,'), ',')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .replaceAll(RegExp(r'^\s*,\s*'), '')
        .replaceAll(RegExp(r'\s*,\s*$'), '')
        .trim();
    return out;
  }
}
