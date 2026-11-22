import 'package:flutter/material.dart';

import '../../../common_widgets/ora_logo.dart';
import '../../../theme/ora_palette.dart';

class CustomerPage extends StatelessWidget {
  const CustomerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ora = context.ora;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: OraLogo(height: 36),
          ),
          const SizedBox(height: 36),
          Text(
            'LAYANAN BANTUAN',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 22,
                  letterSpacing: 0.4,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Customer service untuk transaksi digital, status order, dan pengaduan.',
            style: TextStyle(color: ora.muted, height: 1.5),
          ),
          const SizedBox(height: 24),
          _SupportTile(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Chat bantuan',
            subtitle: 'Hubungi tim CS OraRepot',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat CS segera tersedia.')),
              );
            },
          ),
          const SizedBox(height: 10),
          _SupportTile(
            icon: Icons.help_outline_rounded,
            title: 'FAQ',
            subtitle: 'Pertanyaan umum seputar pulsa & tagihan',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('FAQ segera tersedia.')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SupportTile extends StatelessWidget {
  const _SupportTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ora = context.ora;
    return Material(
      color: ora.panel,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ora.line),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: ora.field,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: ora.lime),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: ora.text),
                    ),
                    const SizedBox(height: 3),
                    Text(subtitle, style: TextStyle(color: ora.muted, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: ora.muted),
            ],
          ),
        ),
      ),
    );
  }
}
