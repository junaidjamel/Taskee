import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ResourceLinkService {
  const ResourceLinkService._();

  static Uri? normalize(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;

    final parsed = Uri.tryParse(value);
    if (parsed == null) return null;

    if (parsed.hasScheme) {
      if (parsed.scheme == 'http' || parsed.scheme == 'https') return parsed;
      return null;
    }

    final candidate = value.startsWith('//') ? 'https:$value' : 'https://$value';
    final normalized = Uri.tryParse(candidate);
    if (normalized == null || normalized.host.isEmpty) return null;
    return normalized;
  }

  static Future<bool> open(BuildContext context, String? raw) async {
    final uri = normalize(raw);
    if (uri == null) {
      _showError(context, 'That link is not valid.');
      return false;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      _showError(context, 'Could not open this link.');
    }
    return opened;
  }

  static String display(String raw) {
    final uri = normalize(raw);
    if (uri == null) return raw;
    return uri.toString();
  }

  static void _showError(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
