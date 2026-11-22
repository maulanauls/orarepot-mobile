import 'package:flutter_test/flutter_test.dart';
import 'package:orarepot/src/data/models/biller_models.dart';

void main() {
  test('BillerUser maps enter/login response fields', () {
    final auth = StoreAuth.fromJson({
      'token': 'jwt-token',
      'user': {
        'user_phonenumber': '6287776764915',
        'users_email': 'achmad.maulana@tikngroup.com',
        'users_fullname': 'ACHMAD MAULANA',
        'users_idf': '5064eaa2-716f-449b-bafc-873f621fa940',
      },
    });

    expect(auth.token, 'jwt-token');
    expect(auth.user.usersName, 'ACHMAD MAULANA');
    expect(auth.user.usersEmail, 'achmad.maulana@tikngroup.com');
    expect(auth.user.userPhonenumber, '6287776764915');
    expect(auth.user.usersIdf, '5064eaa2-716f-449b-bafc-873f621fa940');
  });

  test('OtpChallenge maps enter otp_required payload', () {
    final challenge = OtpChallenge.fromJson({
      'otp_required': true,
      'challenge': 'chal-abc',
      'expires_in': 300,
      'resend_in': 45,
    });

    expect(challenge.challenge, 'chal-abc');
    expect(challenge.expiresIn, 300);
    expect(challenge.resendIn, 45);
  });
}
