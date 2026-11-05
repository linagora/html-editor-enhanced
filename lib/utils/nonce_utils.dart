class NonceUtils {
  const NonceUtils._();

  /// Base64 and base64url characters only, never empty.
  static final RegExp _validNoncePattern = RegExp(r'^[A-Za-z0-9+/=_-]+$');

  static bool isValidNonce(String? nonce) =>
      nonce != null && _validNoncePattern.hasMatch(nonce);

  /// The attribute a script tag needs to be allowed by the host page's policy.
  static String nonceAttribute(String? nonce) =>
      isValidNonce(nonce) ? ' nonce="$nonce"' : '';

  /// Stamps every <script opening tag of [html]; must run before any JS body
  /// is inlined, as those bodies hold literal "<script" strings.
  static String addNonceToScriptTags(String html, String? nonce) {
    final attribute = nonceAttribute(nonce);
    if (attribute.isEmpty) return html;
    return html.replaceAll('<script', '<script$attribute');
  }
}
