import 'package:flutter_test/flutter_test.dart';
import 'package:hairspot_mobile/features/sharing/domain/share_url_builder.dart';

void main() {
  group('buildSalonShareUrl', () {
    test('returns the bare salon URL when no employee id is passed', () {
      final url = buildSalonShareUrl('42');
      expect(url, 'https://www.termini-im.com/company/42');
    });

    test('omits the employee param when an empty string is passed', () {
      final url = buildSalonShareUrl('42', employeeId: '');
      expect(url, 'https://www.termini-im.com/company/42');
    });

    test('appends ?employee= when an id is provided', () {
      final url = buildSalonShareUrl('42', employeeId: '7f1');
      expect(url, 'https://www.termini-im.com/company/42?employee=7f1');
    });

    test('percent-encodes tricky characters in both companyId and employeeId',
        () {
      final url =
          buildSalonShareUrl('co mpany', employeeId: 'emp&id');
      expect(url, contains('company/co%20mpany'));
      expect(url, contains('employee=emp%26id'));
    });

    test('uses the canonical base URL constant', () {
      final url = buildSalonShareUrl('42');
      expect(url, startsWith(kShareBaseUrl));
    });
  });
}
