import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/app_scope.dart';
import '../../../data/auth_store.dart';
import '../../../data/models/biller_models.dart';
import '../../../theme/ora_palette.dart';
import '../../auth/sign_in_sheet.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  Future<void> _logout() async {
    await AppScope.read(context).auth.logout();
    if (!mounted) return;
    await showSignInSheet(context);
  }

  void _soon(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label segera tersedia.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context).authStore;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => _ProfileBody(
        store: store,
        onLogout: _logout,
        onSoon: _soon,
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({
    required this.store,
    required this.onLogout,
    required this.onSoon,
  });

  final AuthStore store;
  final Future<void> Function() onLogout;
  final void Function(String label) onSoon;

  @override
  Widget build(BuildContext context) {
    final ora = context.ora;
    final BillerUser? user = store.user;
    final signedIn = store.isSignedIn;

    // Backend `/biller/auth/enter` → users_fullname + users_email.
    final name = signedIn
        ? (user?.usersName?.trim().isNotEmpty == true
            ? user!.usersName!.trim()
            : 'Pelanggan')
        : 'Tamu';
    final subtitle = signedIn
        ? (user?.usersEmail?.trim().isNotEmpty == true
            ? user!.usersEmail!.trim()
            : (user?.userPhonenumber?.trim().isNotEmpty == true
                ? user!.userPhonenumber!.trim()
                : 'Akun terhubung'))
        : 'Masuk untuk mengelola akun';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'O';

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        children: [
          const SizedBox(height: 12),
          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundColor: ora.field,
              child: Text(
                initial,
                style: GoogleFonts.poppins(
                  color: ora.lime,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name.toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: ora.text,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: ora.muted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),
          _MenuCard(
            children: [
              _MenuTile(
                icon: Icons.support_agent_rounded,
                title: 'LAYANAN BANTUAN',
                onTap: () => onSoon('Layanan bantuan'),
              ),
              _MenuTile(
                icon: Icons.help_outline_rounded,
                title: 'FAQ',
                onTap: () => onSoon('FAQ'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _MenuCard(
            children: [
              if (signedIn)
                _MenuTile(
                  icon: Icons.settings_outlined,
                  title: 'PENGATURAN AKUN',
                  onTap: () => onSoon('Pengaturan akun'),
                ),
              _MenuTile(
                icon: Icons.star_outline_rounded,
                title: 'NILAI KAMI',
                onTap: () => onSoon('Nilai kami'),
              ),
              if (signedIn)
                _MenuTile(
                  icon: Icons.logout_rounded,
                  title: 'KELUAR',
                  danger: true,
                  onTap: onLogout,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ora = context.ora;
    return Container(
      decoration: BoxDecoration(
        color: ora.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ora.line),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(height: 1, thickness: 1, color: ora.line, indent: 56, endIndent: 16),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final ora = context.ora;
    final color = danger ? ora.danger : ora.text;
    final iconColor = danger ? ora.danger : ora.lime;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: ora.field,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: color,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_rounded, size: 18, color: ora.muted2),
          ],
        ),
      ),
    );
  }
}
