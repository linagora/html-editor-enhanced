/// Link schemes that are never written into an `<a href>`.
///
/// This is a denylist of known risky schemes: script execution
/// (`javascript`, `vbscript`, `livescript`, `mocha`), inline or local content
/// (`data`, `blob`, `file`, `filesystem`) and Android app launching
/// (`intent`). It is not an HTML sanitizer and does not make arbitrary email
/// HTML safe to render.
const Set<String> dangerousLinkSchemes = {
  'javascript',
  'vbscript',
  'livescript',
  'mocha',
  'data',
  'blob',
  'file',
  'filesystem',
  'intent',
};

extension StringLinkExtension on String {
  /// Whether a browser would resolve this string, used as an `href`, to one
  /// of the dangerous link schemes.
  ///
  /// Follows the WHATWG URL parser, which strips leading C0 controls and
  /// spaces and removes ASCII tab and newline characters anywhere in the
  /// input, so `java\tscript:` is caught as well.
  bool get hasDangerousLinkScheme {
    final value = replaceAll(RegExp(r'[\t\n\r]+'), '')
        .replaceFirst(RegExp(r'^[\x00-\x20]+'), '');
    final scheme = RegExp(
      r'^([a-zA-Z][a-zA-Z0-9+.-]*):',
    ).firstMatch(value)?.group(1);
    return scheme != null &&
        dangerousLinkSchemes.contains(scheme.toLowerCase());
  }

  String normalizeLinkInput({bool useFallback = true}) {
    final value = trim();
    if (value.isEmpty) return value;

    // Reject schemes that can execute code or smuggle active content when
    // the resulting <a href> is rendered, including ones a browser only sees
    // after stripping tabs, newlines and leading control characters.
    // Returning an empty string neutralizes the link instead of originating
    // a hostile href.
    if (hasDangerousLinkScheme) return '';

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

    final scheme = RegExp(
      r'^([a-zA-Z][a-zA-Z0-9+.-]*):',
    ).firstMatch(value)?.group(1);

    if (scheme != null) return value;

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
