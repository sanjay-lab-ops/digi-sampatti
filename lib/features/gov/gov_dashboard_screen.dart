import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';

// ── Government Official Dashboard — Demo mockup ───────────────────────────────

class GovDashboardScreen extends StatefulWidget {
  const GovDashboardScreen({super.key});
  @override
  State<GovDashboardScreen> createState() => _GovDashboardScreenState();
}

class _GovDashboardScreenState extends State<GovDashboardScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: AppColors.arthBlue,
        foregroundColor: Colors.white,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop()),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Government Dashboard',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            Text('Tahsildar — Bengaluru Urban Taluk',
                style: TextStyle(fontSize: 10, color: Colors.white70)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('DEMO',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Row(children: [
            _Tab('Overview', 0, _tab, (i) => setState(() => _tab = i)),
            _Tab('Grievances', 1, _tab, (i) => setState(() => _tab = i)),
            _Tab('Fraud Alerts', 2, _tab, (i) => setState(() => _tab = i)),
            _Tab('Sign Reports', 3, _tab, (i) => setState(() => _tab = i)),
          ]),
        ),
      ),
      body: IndexedStack(
        index: _tab,
        children: const [
          _OverviewTab(),
          _GrievancesTab(),
          _FraudTab(),
          _SignTab(),
        ],
      ),
    );
  }
}

// ── Overview ─────────────────────────────────────────────────────────────────
class _OverviewTab extends StatelessWidget {
  const _OverviewTab();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Officer info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.arthBlue,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white24,
                radius: 26,
                child: Icon(Icons.person, color: Colors.white, size: 28),
              ),
              SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rajesh Kumar B.',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  Text('Tahsildar — Bengaluru Urban',
                      style:
                          TextStyle(color: Colors.white70, fontSize: 12)),
                  Text('Dept ID: KA-REV-BLR-2847',
                      style:
                          TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Stats row
        Row(
          children: [
            _StatCard('12', 'Reports\nThis Week', AppColors.primary),
            const SizedBox(width: 10),
            _StatCard('3', 'Pending\nGrievances', Colors.orange),
            const SizedBox(width: 10),
            _StatCard('1', 'Fraud\nAlerts', Colors.red),
          ],
        ),
        const SizedBox(height: 16),

        // Data sync status
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.sync, color: AppColors.primary, size: 18),
                  SizedBox(width: 8),
                  Text('Data Sync Status',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 10),
              _SyncRow('Bhoomi (RTC)', '26 Mar 2026 — 14:32', true),
              _SyncRow('Kaveri Online (EC)', '26 Mar 2026 — 13:58', true),
              _SyncRow('eCourts', '26 Mar 2026 — 12:00', true),
              _SyncRow('KSRSAC Spatial', 'Pending API access', false),
              const SizedBox(height: 8),
              const Text(
                'DigiSampatti syncs with government databases every 30 minutes. '
                'Citizens are notified within 2 hours of any data change.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Recent activity
        const Text('Recent Activity in Your Jurisdiction',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.arthBlue)),
        const SizedBox(height: 8),
        _ActivityTile('Survey 45/2, Yelahanka',
            'Verified — Score 87/100', '2 hours ago', Icons.check_circle,
            Colors.green),
        _ActivityTile('Survey 112/3, Hebbal',
            'Warning — Khata pending', '5 hours ago', Icons.warning,
            Colors.orange),
        _ActivityTile('Survey 78/1, Dasarahalli',
            'Fraud alert raised by citizen', '1 day ago', Icons.flag,
            Colors.red),
      ],
    );
  }
}

// ── Grievances ────────────────────────────────────────────────────────────────
class _GrievancesTab extends StatelessWidget {
  const _GrievancesTab();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _GrievanceCard(
          id: 'DS-GRV-2026-4821',
          issue: 'Wrong ownership record — Survey 78/1',
          citizen: 'Citizen (Anonymous)',
          filed: '24 Mar 2026',
          daysLeft: 5,
          status: 'Pending',
          color: Colors.orange,
        ),
        const SizedBox(height: 10),
        _GrievanceCard(
          id: 'DS-GRV-2026-4756',
          issue: 'EC mismatch — Bank loan not showing',
          citizen: 'Citizen (Anonymous)',
          filed: '20 Mar 2026',
          daysLeft: 1,
          status: 'Urgent',
          color: Colors.red,
        ),
        const SizedBox(height: 10),
        _GrievanceCard(
          id: 'DS-GRV-2026-4601',
          issue: 'Mutation not updated after registration',
          citizen: 'Citizen (Anonymous)',
          filed: '15 Mar 2026',
          daysLeft: 0,
          status: 'Escalated to RI',
          color: Colors.deepOrange,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'Grievances not responded within 7 days are auto-escalated '
            'to the next officer level. Unresolved cases after 30 days '
            'trigger RTI and Lokayukta options for citizens.',
            style: TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}

// ── Fraud Alerts ──────────────────────────────────────────────────────────────
class _FraudTab extends StatelessWidget {
  const _FraudTab();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.warning, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Text('Active Fraud Alert',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.red)),
                ],
              ),
              const SizedBox(height: 10),
              const Text('Survey 78/1, Dasarahalli, Bengaluru Urban',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              const Text(
                'AI Pattern Detection: This survey number was searched '
                '3 times in 24 hours from different users. EC shows no '
                'loan, but Bhoomi shows litigant as co-owner — possible '
                'double-sale attempt.',
                style: TextStyle(fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Fraud alert flagged for investigation. Revenue department notified.'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red)),
                      child: const Text('Flag for Investigation',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Alert sent to Karnataka Police Cyber Cell. Reference ID generated.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red),
                      child: const Text('Alert Police',
                          style: TextStyle(
                              color: Colors.white, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('AI Fraud Detection Rules',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.arthBlue)),
        const SizedBox(height: 8),
        _RuleCard('Same survey no. searched 3+ times in 24 hrs',
            'Possible double-sale attempt', Colors.red),
        _RuleCard('EC shows no loan but Bhoomi shows bank lien',
            'Data mismatch — possible fraud', Colors.orange),
        _RuleCard('3+ owners with same Khata number',
            'Benami transaction pattern', Colors.deepOrange),
        _RuleCard('RERA expired but builder still advertising',
            'Illegal project marketing', Colors.orange),
      ],
    );
  }
}

// ── Sign Reports ──────────────────────────────────────────────────────────────
class _SignTab extends StatefulWidget {
  const _SignTab();
  @override
  State<_SignTab> createState() => _SignTabState();
}

class _SignTabState extends State<_SignTab> {
  bool _signed = false;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Add your official digital stamp to verified reports. '
          'Your Aadhaar-verified signature will be stored on blockchain '
          'and cannot be modified after signing.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 16),

        // Report to sign
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Survey 45/2 — Yelahanka',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              const Text('Requested by citizen — 26 Mar 2026',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 10),
              const Divider(),
              const SizedBox(height: 8),
              const Text('Report verified — all checks passed',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.primary)),
              const SizedBox(height: 12),
              if (_signed)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceGreen,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.primary.withOpacity(0.4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified, color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Digitally Signed',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary)),
                            Text(
                                'Tahsildar, Bengaluru Urban • 26 Mar 2026\n'
                                'Aadhaar-verified • Blockchain: tx-8f2a...3c1d',
                                style: TextStyle(fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: () => _confirmSign(context),
                  icon: const Icon(Icons.draw),
                  label: const Text('Sign with Aadhaar e-Sign'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.arthBlue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 46),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'Your digital signature is stored immutably — cannot be revoked or '
            'modified by anyone, including DigiSampatti. DigiSampatti accesses all '
            'government databases directly as a public citizen right, with no MOU required.',
            style: TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  void _confirmSign(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Digital Signature'),
        content: const Text(
          'You are about to digitally sign this property report '
          'using your Aadhaar. This action will be recorded on '
          'blockchain and cannot be reversed.\n\nProceed?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _signed = true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Report signed and stored on blockchain'),
                    backgroundColor: AppColors.primary),
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.arthBlue),
            child: const Text('Sign Now',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Helper Widgets ────────────────────────────────────────────────────────────

class _Tab extends StatelessWidget {
  final String label;
  final int index, current;
  final void Function(int) onTap;
  const _Tab(this.label, this.index, this.current, this.onTap);
  @override
  Widget build(BuildContext context) {
    final sel = index == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(
                    color: sel ? Colors.amber : Colors.transparent,
                    width: 2.5)),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11,
                  color: sel ? Colors.amber : Colors.white60,
                  fontWeight:
                      sel ? FontWeight.bold : FontWeight.normal)),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value, label;
  final Color color;
  const _StatCard(this.value, this.label, this.color);
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color)),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ),
      );
}

class _SyncRow extends StatelessWidget {
  final String source, time;
  final bool synced;
  const _SyncRow(this.source, this.time, this.synced);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Icon(
                synced ? Icons.check_circle : Icons.pending,
                color: synced ? AppColors.primary : Colors.grey,
                size: 14),
            const SizedBox(width: 8),
            Expanded(
                child: Text(source,
                    style: const TextStyle(fontSize: 12))),
            Text(time,
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      );
}

class _ActivityTile extends StatelessWidget {
  final String title, subtitle, time;
  final IconData icon;
  final Color color;
  const _ActivityTile(
      this.title, this.subtitle, this.time, this.icon, this.color);
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            Text(time,
                style:
                    const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      );
}

class _GrievanceCard extends StatelessWidget {
  final String id, issue, citizen, filed, status;
  final int daysLeft;
  final Color color;
  const _GrievanceCard(
      {required this.id,
      required this.issue,
      required this.citizen,
      required this.filed,
      required this.daysLeft,
      required this.status,
      required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(id,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500)),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(status,
                      style: TextStyle(
                          fontSize: 10,
                          color: color,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(issue,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
            Text('Filed: $filed',
                style:
                    const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: daysLeft == 0
                        ? 1.0
                        : (7 - daysLeft) / 7,
                    backgroundColor: Colors.grey.shade200,
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                    daysLeft == 0
                        ? 'Overdue'
                        : '$daysLeft days left',
                    style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                        foregroundColor: color,
                        side: BorderSide(color: color),
                        padding: const EdgeInsets.symmetric(vertical: 8)),
                    child: const Text('Respond',
                        style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 8)),
                    child: const Text('Escalate Up',
                        style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

class _RuleCard extends StatelessWidget {
  final String trigger, meaning;
  final Color color;
  const _RuleCard(this.trigger, this.meaning, this.color);
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border(left: BorderSide(color: color, width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(trigger,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 12)),
            Text(meaning,
                style: TextStyle(fontSize: 11, color: color)),
          ],
        ),
      );
}
