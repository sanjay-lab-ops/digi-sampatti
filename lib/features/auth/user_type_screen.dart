import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';

// ── User Type Selection — shown before OTP login ──────────────────────────────

class UserTypeScreen extends StatelessWidget {
  const UserTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),
            // Logo area
            const Icon(Icons.verified_user, color: Colors.white, size: 56),
            const SizedBox(height: 12),
            const Text('DigiSampatti',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1)),
            const Text('ಡಿಜಿ ಸಂಪತ್ತಿ',
                style: TextStyle(color: Colors.amber, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('India\'s Property Verification Platform',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 40),

            // Type cards
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F6FA),
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Select your login type',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.primary)),
                      const SizedBox(height: 6),
                      const Text(
                          'Different access levels are provided based on your role.',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 20),

                      _TypeCard(
                        icon: Icons.person,
                        title: 'Citizen / Public',
                        subtitle: 'Home buyers, farmers, property owners, NRIs',
                        color: const Color(0xFF1B5E20),
                        features: const [
                          'Property verification reports',
                          'Buying journey guidance',
                          'Grievance filing',
                          'NRI Mode with FEMA guidance',
                        ],
                        onTap: () => context.go('/auth'),
                      ),
                      const SizedBox(height: 12),

                      _TypeCard(
                        icon: Icons.account_balance,
                        title: 'Government Official',
                        subtitle: 'VA, RI, Tahsildar, Revenue Officers',
                        color: const Color(0xFF0D47A1),
                        features: const [
                          'View reports in your jurisdiction',
                          'Add digital stamp to reports',
                          'Respond to citizen grievances',
                          'Fraud alert dashboard',
                        ],
                        badge: 'Dept ID Required',
                        onTap: () => _showGovtLogin(context),
                      ),
                      const SizedBox(height: 12),

                      _TypeCard(
                        icon: Icons.corporate_fare,
                        title: 'Bank Officer',
                        subtitle: 'Loan verification, mortgage processing',
                        color: const Color(0xFF4A148C),
                        features: const [
                          'Bulk property verification',
                          'Loan-linked report generation',
                          'High-risk property alerts',
                          'Blockchain-verified reports for court',
                        ],
                        badge: 'Bank License Required',
                        onTap: () => _showBankLogin(context),
                      ),
                      const SizedBox(height: 12),

                      _TypeCard(
                        icon: Icons.gavel,
                        title: 'Legal Professional',
                        subtitle: 'Advocates, Notaries, Legal firms',
                        color: const Color(0xFFB71C1C),
                        features: const [
                          'Full legal report with citations',
                          'Case history export to court format',
                          'Client property file management',
                          'eCourts integration',
                        ],
                        badge: 'Bar Council ID Required',
                        onTap: () => _showLegalLogin(context),
                      ),
                      const SizedBox(height: 20),

                      // Demo mode
                      OutlinedButton.icon(
                        onPressed: () => context.push('/demo'),
                        icon: const Icon(Icons.play_circle_outline,
                            color: AppColors.primary),
                        label: const Text('View Demo Report',
                            style: TextStyle(color: AppColors.primary)),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Center(
                        child: Text(
                          'Startup India ID: IN-0326-9427JD\nPatent Pending',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ),
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

  void _showGovtLogin(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _GovtLoginSheet(),
    );
  }

  void _showBankLogin(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _BankLoginSheet(),
    );
  }

  void _showLegalLogin(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _LegalLoginSheet(),
    );
  }
}

// ── Type Card ─────────────────────────────────────────────────────────────────
class _TypeCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final List<String> features;
  final String? badge;
  final VoidCallback onTap;

  const _TypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.features,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: color)),
                      Text(subtitle,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(badge!,
                        style: TextStyle(
                            fontSize: 9,
                            color: color,
                            fontWeight: FontWeight.bold)),
                  )
                else
                  Icon(Icons.arrow_forward_ios, color: color, size: 14),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: features
                  .map((f) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(f,
                            style: TextStyle(
                                fontSize: 10, color: color)),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Login Sheets ──────────────────────────────────────────────────────────────

class _GovtLoginSheet extends StatelessWidget {
  const _GovtLoginSheet();
  @override
  Widget build(BuildContext context) {
    return _LoginSheet(
      title: 'Government Official Login',
      color: const Color(0xFF0D47A1),
      icon: Icons.account_balance,
      fields: const ['Aadhaar Number', 'Department ID', 'Taluk / District'],
      note:
          'Government login requires your Aadhaar-linked Department ID '
          'issued by NIC Karnataka. Contact your district IT cell if '
          'you do not have a Department ID.\n\n'
          'Access is restricted to records within your assigned jurisdiction.',
      onLogin: (ctx) {
        Navigator.pop(ctx);
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(
              content: Text(
                  'Government login activates after Revenue Dept MOU. '
                  'Showing demo dashboard.'),
              backgroundColor: Color(0xFF0D47A1)),
        );
        ctx.push('/gov-dashboard');
      },
    );
  }
}

class _BankLoginSheet extends StatelessWidget {
  const _BankLoginSheet();
  @override
  Widget build(BuildContext context) {
    return _LoginSheet(
      title: 'Bank Officer Login',
      color: const Color(0xFF4A148C),
      icon: Icons.corporate_fare,
      fields: const ['Bank License Number', 'Officer Employee ID', 'Branch IFSC'],
      note:
          'Bank access allows bulk property verification for loan processing. '
          'Each verification is logged with timestamp for audit purposes. '
          'Reports are blockchain-verified and court-admissible.',
      onLogin: (ctx) {
        Navigator.pop(ctx);
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(
              content:
                  Text('Bank login activates after bank partnership MOU.'),
              backgroundColor: Color(0xFF4A148C)),
        );
      },
    );
  }
}

class _LegalLoginSheet extends StatelessWidget {
  const _LegalLoginSheet();
  @override
  Widget build(BuildContext context) {
    return _LoginSheet(
      title: 'Legal Professional Login',
      color: const Color(0xFFB71C1C),
      icon: Icons.gavel,
      fields: const ['Bar Council Registration ID', 'State Bar Council', 'Phone Number'],
      note:
          'Legal login provides full property history with legal citations '
          'in court-admissible format. Reports can be exported as PDF '
          'with DigiSampatti blockchain reference number for case filing.',
      onLogin: (ctx) {
        Navigator.pop(ctx);
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(
              content:
                  Text('Legal login available from April 2026 launch.'),
              backgroundColor: Color(0xFFB71C1C)),
        );
      },
    );
  }
}

class _LoginSheet extends StatelessWidget {
  final String title, note;
  final Color color;
  final IconData icon;
  final List<String> fields;
  final void Function(BuildContext) onLogin;

  const _LoginSheet({
    required this.title,
    required this.color,
    required this.icon,
    required this.fields,
    required this.note,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 10),
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: color)),
              ],
            ),
            const SizedBox(height: 16),
            ...fields.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: f,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                )),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(note,
                  style: TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => onLogin(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Verify & Login',
                  style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
