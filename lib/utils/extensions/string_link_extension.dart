extension StringLinkExtension on String {
  String normalizeLinkInput({bool useFallback = true}) {
    final value = trim();
    if (value.isEmpty) return value;

    final isLocalhostEmail =
        RegExp(r'^[A-Za-z0-9._%+-]+@localhost$', caseSensitive: false)
            .hasMatch(value);

    if (isLocalhostEmail) {
      return "mailto:$value";
    }

    final isStandardEmail = RegExp(
      r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
      caseSensitive: false,
    ).hasMatch(value);

    if (isStandardEmail) {
      return "mailto:$value";
    }

    final hasScheme = RegExp(
      r'^[a-zA-Z][a-zA-Z0-9+.-]*:',
    ).hasMatch(value);

    if (hasScheme) {
      return value;
    }

    if (value.startsWith("www.")) {
      return "https://$value";
    }

    if (value.contains('.')) {
      return "https://$value";
    }

    if (useFallback) {
      return "https://$value";
    } else {
      return '';
    }
  }

  String safeNormalizeLinkInput({bool useFallback = true}) {
    try {
      return normalizeLinkInput(useFallback: useFallback);
    } catch (_) {
      return useFallback ? this : '';
    }
  }
}
