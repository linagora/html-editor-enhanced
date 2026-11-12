class NonceUtils {
  const NonceUtils._();

  /// Base64 and base64url characters only, never empty.
  static final RegExp _validNoncePattern = RegExp(r'^[A-Za-z0-9+/=_-]+$');
  static final RegExp _scriptOpenTag = RegExp(r'<script(?=[\s>])', caseSensitive: false);

  static bool isValidNonce(String? nonce) =>
      nonce != null && _validNoncePattern.hasMatch(nonce);

  /// The attribute a script tag needs to be allowed by the host page's policy.
  static String nonceAttribute(String? nonce) =>
      isValidNonce(nonce) ? ' nonce="$nonce"' : '';

  /// Stamps `<script` only when whitespace or `>` follows, before any JS body is inlined.
  static String addNonceToScriptTags(String html, String? nonce) {
    final attribute = nonceAttribute(nonce);
    if (attribute.isEmpty) return html;
    return html.replaceAll(_scriptOpenTag, '<script$attribute');
  }
}
