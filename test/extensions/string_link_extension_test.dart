import 'package:flutter_test/flutter_test.dart';
import 'package:html_editor_enhanced/utils/extensions/string_link_extension.dart';

void main() {
  group('StringLinkExtension → normalizeLinkInput (email cases)', () {
    test('standard email → mailto', () {
      expect(
        "user@example.com".normalizeLinkInput(),
        "mailto:user@example.com",
      );
    });

    test('email with subdomain → mailto', () {
      expect(
        "dev@mail.example.com".normalizeLinkInput(),
        "mailto:dev@mail.example.com",
      );
    });

    test('email uppercase → mailto', () {
      expect(
        "User@Example.Com".normalizeLinkInput(),
        "mailto:User@Example.Com",
      );
    });

    test('email with plus → mailto', () {
      expect("user+tag@domain.com".normalizeLinkInput(),
          "mailto:user+tag@domain.com");
    });

    test('localhost email → mailto', () {
      expect("root@localhost".normalizeLinkInput(), "mailto:root@localhost");
    });

    test('mailto already included → unchanged', () {
      expect(
        "mailto:user@example.com".normalizeLinkInput(),
        "mailto:user@example.com",
      );
    });

    test('invalid email without dot → not email', () {
      expect("user@mailserver".normalizeLinkInput(), "https://user@mailserver");
    });

    test('invalid email missing username → not email', () {
      expect("@example.com".normalizeLinkInput(), "https://@example.com");
    });

    test('invalid email missing domain → not email', () {
      expect("user@".normalizeLinkInput(), "https://user@");
    });
  });

  group('StringLinkExtension → normalizeLinkInput (URL cases)', () {
    test('http URL → unchanged', () {
      expect("http://example.com".normalizeLinkInput(), "http://example.com");
    });

    test('https URL → unchanged', () {
      expect("https://example.com".normalizeLinkInput(), "https://example.com");
    });

    test('ftp URL → unchanged', () {
      expect("ftp://server.com".normalizeLinkInput(), "ftp://server.com");
    });

    test('tel: URL → unchanged', () {
      expect("tel:+84123456789".normalizeLinkInput(), "tel:+84123456789");
    });

    test('www.* → add https', () {
      expect("www.google.com".normalizeLinkInput(), "https://www.google.com");
    });

    test('domain without protocol → add https', () {
      expect("example.app".normalizeLinkInput(), "https://example.app");
    });

    test('subdomain domain → add https', () {
      expect("mail.server.net".normalizeLinkInput(), "https://mail.server.net");
    });

    test('keyword without dot → https fallback', () {
      expect("google".normalizeLinkInput(), "https://google");
    });

    test('domain with spaces → trimmed + https', () {
      expect("   example.app   ".normalizeLinkInput(), "https://example.app");
    });
  });

  group('StringLinkExtension → normalizeLinkInput (scheme detection)', () {
    test('mailto:user → unchanged', () {
      expect(
        "mailto:user@domain.com".normalizeLinkInput(),
        "mailto:user@domain.com",
      );
    });

    test('custom scheme without slashes → unchanged', () {
      expect("twake:editor".normalizeLinkInput(), "twake:editor");
    });

    test('custom numeric scheme → unchanged', () {
      expect("note:123".normalizeLinkInput(), "note:123");
    });

    test('value with colon but not protocol → unchanged', () {
      expect("abc:def".normalizeLinkInput(), "abc:def");
    });
  });

  group('StringLinkExtension → normalizeLinkInput (edge cases)', () {
    test('empty string → empty', () {
      expect("".normalizeLinkInput(), "");
    });

    test('whitespace only → empty', () {
      expect("    ".normalizeLinkInput(), "");
    });

    test('invalid email but has @ → treat as URL', () {
      expect("abc@xyz".normalizeLinkInput(), "https://abc@xyz");
    });
  });

  group('StringLinkExtension → safeNormalizeLinkInput', () {
    test('safeNormalizeLinkInput should return normalized value on success',
        () {
      expect("example.com".safeNormalizeLinkInput(), "https://example.com");
    });
  });
}
