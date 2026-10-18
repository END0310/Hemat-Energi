import 'package:flutter_test/flutter_test.dart';
import 'package:hemat_energi/domain/services/auth_service.dart';

void main() {
  group('AuthService Unit Tests', () {
    test('generateSalt returns non-empty base64 string', () {
      final salt1 = AuthService.generateSalt();
      final salt2 = AuthService.generateSalt();

      expect(salt1.isNotEmpty, true);
      expect(salt2.isNotEmpty, true);
      expect(salt1, isNot(equals(salt2))); // Dua salt acak tidak boleh sama
    });

    test('hashPassword produces consistent hash for same password and salt', () {
      const password = 'mySecretPassword123';
      final salt = AuthService.generateSalt();

      final hash1 = AuthService.hashPassword(password, salt, iterations: 100);
      final hash2 = AuthService.hashPassword(password, salt, iterations: 100);

      expect(hash1, equals(hash2));
    });

    test('hashPassword produces different hash for different password or salt', () {
      const passwordA = 'passwordA123';
      const passwordB = 'passwordB123';
      final saltA = AuthService.generateSalt();
      final saltB = AuthService.generateSalt();

      final hashA1 = AuthService.hashPassword(passwordA, saltA, iterations: 100);
      final hashA2 = AuthService.hashPassword(passwordB, saltA, iterations: 100);
      final hashB1 = AuthService.hashPassword(passwordA, saltB, iterations: 100);

      expect(hashA1, isNot(equals(hashA2)));
      expect(hashA1, isNot(equals(hashB1)));
    });

    test('constantTimeEquals correctly compares equal and unequal strings', () {
      expect(AuthService.constantTimeEquals('secret_hash_123', 'secret_hash_123'), isTrue);
      expect(AuthService.constantTimeEquals('secret_hash_123', 'secret_hash_456'), isFalse);
      expect(AuthService.constantTimeEquals('short', 'longer_string'), isFalse);
      expect(AuthService.constantTimeEquals('', ''), isTrue);
    });
  });
}
