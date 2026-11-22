import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../common_widgets/ora_banner.dart';
import '../../common_widgets/ora_logo.dart';
import '../../data/api_client.dart';
import '../../data/app_scope.dart';
import '../../data/auth_repository.dart';
import '../../data/google_auth.dart';
import '../../data/models/biller_models.dart';
import '../../theme/ora_palette.dart';

enum AuthMode { signIn, register }

enum AuthLang { id, en }

class _Copy {
  const _Copy({
    required this.signInTitle,
    required this.registerTitle,
    required this.signInSubtitle,
    required this.registerSubtitle,
    required this.fullName,
    required this.identifier,
    required this.identifierPh,
    required this.password,
    required this.confirm,
    required this.remember,
    required this.forgot,
    required this.submitSignIn,
    required this.submitRegister,
    required this.orContinue,
    required this.noAccount,
    required this.hasAccount,
    required this.signUp,
    required this.signIn,
    required this.passwordShort,
    required this.passwordHint,
    required this.passwordMismatch,
    required this.googleFailed,
    required this.googleCancelled,
    required this.accountNotFound,
    required this.otpTitle,
    required this.otpSubtitle,
    required this.otpLabel,
    required this.otpSubmit,
    required this.otpResend,
    required this.otpResendIn,
    required this.otpBack,
    required this.otpInvalid,
  });

  final String signInTitle;
  final String registerTitle;
  final String signInSubtitle;
  final String registerSubtitle;
  final String fullName;
  final String identifier;
  final String identifierPh;
  final String password;
  final String confirm;
  final String remember;
  final String forgot;
  final String submitSignIn;
  final String submitRegister;
  final String orContinue;
  final String noAccount;
  final String hasAccount;
  final String signUp;
  final String signIn;
  final String passwordShort;
  final String passwordHint;
  final String passwordMismatch;
  final String googleFailed;
  final String googleCancelled;
  final String accountNotFound;
  final String otpTitle;
  final String otpSubtitle;
  final String otpLabel;
  final String otpSubmit;
  final String otpResend;
  final String otpResendIn;
  final String otpBack;
  final String otpInvalid;
}

const _copyId = _Copy(
  signInTitle: 'Masuk',
  registerTitle: 'Daftar',
  signInSubtitle: 'Masuk untuk beli pulsa, token, dan voucher dengan harga murah.',
  registerSubtitle:
      'Daftar dengan nomor WhatsApp. Kami kirim OTP untuk verifikasi pertama.',
  fullName: 'Nama lengkap',
  identifier: 'Email atau WhatsApp',
  identifierPh: 'email@bisnis.com / 08xx',
  password: 'Kata sandi',
  confirm: 'Ulangi kata sandi',
  remember: 'Ingat akun saya',
  forgot: 'Lupa kata sandi?',
  submitSignIn: 'Masuk',
  submitRegister: 'Daftar',
  orContinue: 'Atau lanjutkan dengan',
  noAccount: 'Belum punya akun?',
  hasAccount: 'Sudah punya akun?',
  signUp: 'Daftar',
  signIn: 'Masuk',
  passwordShort: 'Kata sandi minimal 8 karakter.',
  passwordHint: 'Kata sandi minimal 8 karakter.',
  passwordMismatch: 'Kata sandi tidak sama.',
  googleFailed: 'Masuk dengan Google gagal. Coba lagi.',
  googleCancelled: 'Masuk Google dibatalkan.',
  accountNotFound:
      'Akun tidak ditemukan. Silakan daftar terlebih dahulu.',
  otpTitle: 'Verifikasi WhatsApp',
  otpSubtitle:
      'Masukkan 6 angka kode yang kami kirim ke WhatsApp {phone}. Kode berlaku 5 menit.',
  otpLabel: 'Kode verifikasi',
  otpSubmit: 'Verifikasi',
  otpResend: 'Kirim ulang',
  otpResendIn: 'Kirim ulang ({sec})',
  otpBack: 'Ubah data',
  otpInvalid: 'Masukkan 6 angka kode dari WhatsApp.',
);

const _copyEn = _Copy(
  signInTitle: 'Sign in',
  registerTitle: 'Create account',
  signInSubtitle: 'Sign in to buy pulsa, tokens, and vouchers at a low price.',
  registerSubtitle:
      'Sign up with WhatsApp. We send an OTP for the first verification.',
  fullName: 'Full name',
  identifier: 'Email or WhatsApp',
  identifierPh: 'email@business.com / 08xx',
  password: 'Password',
  confirm: 'Confirm password',
  remember: 'Remember me',
  forgot: 'Forgot password?',
  submitSignIn: 'Sign in',
  submitRegister: 'Create account',
  orContinue: 'Or continue with',
  noAccount: 'No account yet?',
  hasAccount: 'Already have an account?',
  signUp: 'Sign up',
  signIn: 'Sign in',
  passwordShort: 'Password must be at least 8 characters.',
  passwordHint: 'Password must be at least 8 characters.',
  passwordMismatch: 'Passwords do not match.',
  googleFailed: 'Google sign-in failed. Try again.',
  googleCancelled: 'Google sign-in cancelled.',
  accountNotFound: 'Account not found. Please register first.',
  otpTitle: 'WhatsApp verification',
  otpSubtitle:
      'Enter the 6-digit code we sent to WhatsApp {phone}. Code expires in 5 minutes.',
  otpLabel: 'Verification code',
  otpSubmit: 'Verify',
  otpResend: 'Resend',
  otpResendIn: 'Resend ({sec})',
  otpBack: 'Edit details',
  otpInvalid: 'Enter the 6-digit code from WhatsApp.',
);

/// Full-screen auth UI matching orappob `/sign-in` and `/register`.
class AuthPage extends StatefulWidget {
  const AuthPage({super.key, this.initialMode = AuthMode.signIn});

  final AuthMode initialMode;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  late AuthMode mode = widget.initialMode;
  AuthLang lang = AuthLang.id;

  final nameController = TextEditingController();
  final identifierController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  final otpController = TextEditingController();

  bool obscure = true;
  bool obscureConfirm = true;
  bool remember = true;
  bool submitting = false;

  OtpChallenge? otpChallenge;
  String otpPhoneHint = '';
  int resendIn = 0;
  Timer? _resendTimer;

  _Copy get t => lang == AuthLang.id ? _copyId : _copyEn;
  bool get _otpStep => otpChallenge != null;

  void _showError(String message, {VoidCallback? onRetry}) {
    showOraError(
      context,
      title: lang == AuthLang.id ? 'Terjadi kesalahan' : 'Something went wrong',
      message: message,
      onRetry: onRetry,
      retryLabel: lang == AuthLang.id ? 'Coba lagi' : 'Retry',
      dismissLabel: lang == AuthLang.id ? 'Tutup' : 'Dismiss',
    );
  }

  void _startResendCountdown(int seconds) {
    _resendTimer?.cancel();
    setState(() => resendIn = seconds < 0 ? 0 : seconds);
    if (resendIn <= 0) return;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (resendIn <= 1) {
        timer.cancel();
        setState(() => resendIn = 0);
      } else {
        setState(() => resendIn -= 1);
      }
    });
  }

  void _beginOtp(OtpChallenge challenge, String phoneHint) {
    hideOraBanner();
    otpController.clear();
    setState(() {
      otpChallenge = challenge;
      otpPhoneHint = phoneHint;
      submitting = false;
    });
    _startResendCountdown(challenge.resendIn);
  }

  void _cancelOtp() {
    hideOraBanner();
    _resendTimer?.cancel();
    otpController.clear();
    setState(() {
      otpChallenge = null;
      otpPhoneHint = '';
      resendIn = 0;
      submitting = false;
    });
  }

  @override
  void dispose() {
    hideOraBanner();
    _resendTimer?.cancel();
    nameController.dispose();
    identifierController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    otpController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final identifier = identifierController.text.trim();
    final password = passwordController.text;
    FocusScope.of(context).unfocus();

    if (identifier.isEmpty || password.isEmpty) {
      _showError(
        lang == AuthLang.id
            ? 'Isi email/WhatsApp dan kata sandi.'
            : 'Enter email/WhatsApp and password.',
      );
      return;
    }
    if (password.length < 8) {
      _showError(t.passwordShort);
      return;
    }
    if (mode == AuthMode.register && password != confirmController.text) {
      _showError(t.passwordMismatch);
      return;
    }

    setState(() => submitting = true);

    final auth = AppScope.read(context).auth;
    try {
      final split = AuthRepository.splitIdentifier(identifier);
      final phoneHint = split.phone.isNotEmpty ? split.phone : identifier;
      try {
        if (mode == AuthMode.register) {
          await auth.register(
            fullName: nameController.text.trim(),
            identifier: identifier,
            password: password,
          );
        } else {
          // Sign-in uses /login only — /enter auto-provisions unknown phones.
          await auth.login(
            identifier: identifier,
            password: password,
            remember: remember,
          );
        }
      } on OtpRequiredException catch (e) {
        if (!mounted) return;
        _beginOtp(e.challenge, phoneHint);
        return;
      }
      if (!mounted) return;
      hideOraBanner();
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => submitting = false);
      _showError(
        mode == AuthMode.signIn ? _signInErrorMessage(e) : e.message,
        onRetry: _submit,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => submitting = false);
      _showError(
        lang == AuthLang.id ? 'Gagal masuk. Coba lagi.' : 'Sign-in failed. Try again.',
        onRetry: _submit,
      );
    }
  }

  /// Map /login failures to a clear "register first" message for unknown accounts.
  String _signInErrorMessage(ApiException e) {
    final raw = e.message.toLowerCase();
    final looksUnknown = e.statusCode == 401 ||
        raw.contains('salah') ||
        raw.contains('tidak ditemukan') ||
        raw.contains('not found') ||
        raw.contains('invalid');
    if (looksUnknown) return t.accountNotFound;
    return e.message;
  }

  Future<void> _submitOtp() async {
    final digits = otpController.text.replaceAll(RegExp(r'\D'), '');
    final challenge = otpChallenge?.challenge.trim() ?? '';
    FocusScope.of(context).unfocus();

    if (digits.length != 6) {
      _showError(t.otpInvalid);
      return;
    }
    if (challenge.isEmpty) {
      _showError(
        lang == AuthLang.id
            ? 'Sesi verifikasi habis. Minta kode baru.'
            : 'Verification session expired. Request a new code.',
      );
      return;
    }

    setState(() => submitting = true);
    final auth = AppScope.read(context).auth;
    try {
      await auth.verifyEnterOtp(
        challenge: challenge,
        code: digits,
        remember: remember,
      );
      if (!mounted) return;
      hideOraBanner();
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => submitting = false);
      _showError(e.message, onRetry: _submitOtp);
    } catch (_) {
      if (!mounted) return;
      setState(() => submitting = false);
      _showError(
        lang == AuthLang.id
            ? 'Kode gagal diverifikasi. Coba lagi.'
            : 'Code verification failed. Try again.',
        onRetry: _submitOtp,
      );
    }
  }

  Future<void> _resendOtp() async {
    if (resendIn > 0 || submitting) return;
    final identifier = identifierController.text.trim();
    final password = passwordController.text;
    if (identifier.isEmpty || password.length < 8) {
      _cancelOtp();
      return;
    }

    setState(() => submitting = true);
    final auth = AppScope.read(context).auth;
    final split = AuthRepository.splitIdentifier(identifier);
    try {
      await auth.login(
        identifier: identifier,
        password: password,
        remember: remember,
      );
      // Unexpected: login succeeded without OTP — treat as signed in.
      if (!mounted) return;
      hideOraBanner();
      Navigator.pop(context, true);
    } on OtpRequiredException catch (e) {
      if (!mounted) return;
      _beginOtp(e.challenge, split.phone.isNotEmpty ? split.phone : identifier);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => submitting = false);
      _showError(_signInErrorMessage(e), onRetry: _resendOtp);
    } catch (_) {
      if (!mounted) return;
      setState(() => submitting = false);
      _showError(
        lang == AuthLang.id ? 'Gagal kirim ulang kode.' : 'Failed to resend code.',
        onRetry: _resendOtp,
      );
    }
  }

  void _switchMode() {
    hideOraBanner();
    _cancelOtp();
    setState(() {
      mode = mode == AuthMode.signIn ? AuthMode.register : AuthMode.signIn;
    });
  }

  Future<void> _googleSignIn() async {
    // Google sign-in skips the WhatsApp OTP challenge.
    if (_otpStep) _cancelOtp();
    FocusScope.of(context).unfocus();
    setState(() => submitting = true);

    final services = AppScope.read(context);
    try {
      final code = await GoogleAuth(services.config).requestCode();
      await services.auth.loginWithGoogle(code: code);
      if (!mounted) return;
      hideOraBanner();
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => submitting = false);
      _showError(e.message, onRetry: _googleSignIn);
    } catch (e) {
      if (!mounted) return;
      setState(() => submitting = false);
      final message = e.toString();
      final cancelled = message.contains('cancelled') || message.contains('dibatalkan');
      final detail = cancelled
          ? t.googleCancelled
          : (message.contains('StateError') || message.contains('Bad state')
              ? message.replaceFirst(RegExp(r'^[^:]+:\s*'), '')
              : t.googleFailed);
      _showError(detail, onRetry: cancelled ? null : _googleSignIn);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ora = context.ora;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: ora.bg,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 10,
              left: 12,
              child: IconButton(
                onPressed: () => Navigator.pop(context, false),
                style: IconButton.styleFrom(
                  backgroundColor: ora.text.withValues(alpha: 0.08),
                  shape: const CircleBorder(),
                ),
                icon: Icon(Icons.close, color: ora.text, size: 22),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(28, 56, 28, bottomInset + 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const OraLogo(height: 36),
                          const Spacer(),
                          _LangToggle(
                            lang: lang,
                            onChanged: (value) => setState(() => lang = value),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      if (_otpStep) ...[
                        Text(
                          t.otpTitle,
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.8,
                            color: ora.text,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          t.otpSubtitle.replaceAll(
                            '{phone}',
                            otpPhoneHint.isNotEmpty
                                ? otpPhoneHint
                                : identifierController.text.trim(),
                          ),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            height: 1.45,
                            color: ora.muted,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _FieldLabel(t.otpLabel),
                        const SizedBox(height: 6),
                        TextField(
                          controller: otpController,
                          autofocus: true,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          maxLength: 6,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          onSubmitted: (_) => _submitOtp(),
                          style: GoogleFonts.poppins(
                            color: ora.text,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 6,
                          ),
                          decoration: _inputDecoration(hint: '123456').copyWith(
                            counterText: '',
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          height: 52,
                          child: FilledButton(
                            onPressed: submitting ? null : _submitOtp,
                            style: FilledButton.styleFrom(
                              backgroundColor: ora.lime,
                              foregroundColor: ora.onLime,
                              disabledBackgroundColor: ora.line,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  submitting ? '…' : t.otpSubmit,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                if (!submitting) ...[
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_rounded, size: 18),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            TextButton(
                              onPressed: submitting ? null : _cancelOtp,
                              child: Text(
                                t.otpBack,
                                style: GoogleFonts.poppins(
                                  color: ora.muted,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: (submitting || resendIn > 0) ? null : _resendOtp,
                              child: Text(
                                resendIn > 0
                                    ? t.otpResendIn.replaceAll('{sec}', '$resendIn')
                                    : t.otpResend,
                                style: GoogleFonts.poppins(
                                  color: resendIn > 0 ? ora.muted : ora.lime,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Text(
                          mode == AuthMode.signIn ? t.signInTitle : t.registerTitle,
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.8,
                            color: ora.text,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          mode == AuthMode.signIn ? t.signInSubtitle : t.registerSubtitle,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            height: 1.45,
                            color: ora.muted,
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (mode == AuthMode.register) ...[
                          _FieldLabel(t.fullName),
                          const SizedBox(height: 6),
                          TextField(
                            controller: nameController,
                            textInputAction: TextInputAction.next,
                            style: GoogleFonts.poppins(color: ora.text),
                            decoration: _inputDecoration(),
                          ),
                          const SizedBox(height: 14),
                        ],
                        _FieldLabel(t.identifier),
                        const SizedBox(height: 6),
                        TextField(
                          controller: identifierController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          style: GoogleFonts.poppins(color: ora.text),
                          decoration: _inputDecoration(hint: t.identifierPh),
                        ),
                        const SizedBox(height: 14),
                        _FieldLabel(t.password),
                        const SizedBox(height: 6),
                        TextField(
                          controller: passwordController,
                          obscureText: obscure,
                          textInputAction: mode == AuthMode.register
                              ? TextInputAction.next
                              : TextInputAction.done,
                          onSubmitted: (_) {
                            if (mode == AuthMode.signIn) _submit();
                          },
                          style: GoogleFonts.poppins(color: ora.text),
                          decoration: _inputDecoration(
                            hint: '••••••••',
                            suffix: IconButton(
                              onPressed: () => setState(() => obscure = !obscure),
                              icon: Icon(
                                obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: ora.muted,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          t.passwordHint,
                          style: GoogleFonts.poppins(
                            color: ora.muted,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                        if (mode == AuthMode.register) ...[
                          const SizedBox(height: 14),
                          _FieldLabel(t.confirm),
                          const SizedBox(height: 6),
                          TextField(
                            controller: confirmController,
                            obscureText: obscureConfirm,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submit(),
                            style: GoogleFonts.poppins(color: ora.text),
                            decoration: _inputDecoration(
                              hint: '••••••••',
                              suffix: IconButton(
                                onPressed: () =>
                                    setState(() => obscureConfirm = !obscureConfirm),
                                icon: Icon(
                                  obscureConfirm
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: ora.muted,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                        if (mode == AuthMode.signIn) ...[
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              SizedBox(
                                height: 22,
                                width: 22,
                                child: Checkbox(
                                  value: remember,
                                  onChanged: (value) =>
                                      setState(() => remember = value ?? true),
                                  activeColor: ora.lime,
                                  checkColor: ora.onLime,
                                  side: BorderSide(color: ora.line),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => remember = !remember),
                                  child: Text(
                                    t.remember,
                                    style: GoogleFonts.poppins(
                                      color: ora.text,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              Text(
                                t.forgot,
                                style: GoogleFonts.poppins(
                                  color: ora.lime,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 18),
                        SizedBox(
                          height: 52,
                          child: FilledButton(
                            onPressed: submitting ? null : _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: ora.lime,
                              foregroundColor: ora.onLime,
                              disabledBackgroundColor: ora.line,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  submitting
                                      ? '…'
                                      : (mode == AuthMode.signIn
                                          ? t.submitSignIn
                                          : t.submitRegister),
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                if (!submitting) ...[
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_rounded, size: 18),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            Expanded(child: Divider(color: ora.line)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                t.orContinue,
                                style: GoogleFonts.poppins(
                                  color: ora.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: ora.line)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: submitting ? null : _googleSignIn,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: ora.text,
                              side: BorderSide(color: ora.line),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (submitting)
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: ora.lime,
                                    ),
                                  )
                                else ...[
                                  const _GoogleMark(),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Google',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: ora.text,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Center(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                mode == AuthMode.signIn ? t.noAccount : t.hasAccount,
                                style: GoogleFonts.poppins(
                                  color: ora.muted,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: submitting ? null : _switchMode,
                                child: Text(
                                  mode == AuthMode.signIn ? t.signUp : t.signIn,
                                  style: GoogleFonts.poppins(
                                    color: ora.lime,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint, Widget? suffix}) {
    final ora = context.ora;
    return InputDecoration(
      hintText: hint,
      suffixIcon: suffix,
      filled: true,
      fillColor: ora.field,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      hintStyle: GoogleFonts.poppins(color: ora.muted, fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: ora.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: ora.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: ora.lime, width: 1.4),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        color: context.ora.text,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _LangToggle extends StatelessWidget {
  const _LangToggle({required this.lang, required this.onChanged});

  final AuthLang lang;
  final ValueChanged<AuthLang> onChanged;

  @override
  Widget build(BuildContext context) {
    final ora = context.ora;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: ora.field,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LangChip(
            label: 'ID',
            active: lang == AuthLang.id,
            onTap: () => onChanged(AuthLang.id),
          ),
          _LangChip(
            label: 'EN',
            active: lang == AuthLang.en,
            onTap: () => onChanged(AuthLang.en),
          ),
        ],
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  const _LangChip({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ora = context.ora;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 32),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: active ? ora.lime : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: active ? ora.onLime : ora.muted,
          ),
        ),
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  static const _svg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
  <path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
  <path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
  <path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
  <path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      _svg,
      width: 18,
      height: 18,
    );
  }
}
