import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';
import 'package:digi_sampatti/core/constants/app_strings.dart';

// ─── Physical Verification Screen ─────────────────────────────────────────────
// Shows checklist of checks that CANNOT be done digitally.
// User marks each item as done after physically visiting the office.

class PhysicalVerificationScreen extends StatefulWidget {
  final Map<String, dynamic>? reportData;
  const PhysicalVerificationScreen({super.key, this.reportData});

  @override
  State<PhysicalVerificationScreen> createState() =>
      _PhysicalVerificationScreenState();
}

class _PhysicalVerificationScreenState
    extends State<PhysicalVerificationScreen> {
  final List<_VerificationItem> _items = [
    _VerificationItem(
      title: 'Court Case Check',
      description: 'Check for any pending/past cases on this survey number',
      office: 'City Civil Court / District Court',
      counter: 'Record Room / Copying Section',
      carry: 'Survey number printout, owner name',
      canPartiallyCheck: true,
      digitalNote: 'eCourts app checked — no active cases found digitally',
      icon: Icons.gavel,
    ),
    _VerificationItem(
      title: 'Benami Property Check',
      description: 'Verify property is not under Benami Transactions Act',
      office: 'Income Tax Office — Benami Prohibition Unit',
      counter: 'Assessing Officer counter',
      carry: 'Survey number, Bhoomi printout, owner Aadhaar copy',
      canPartiallyCheck: false,
      digitalNote: 'Cannot be verified digitally — must visit IT office',
      icon: Icons.account_balance,
    ),
    _VerificationItem(
      title: 'Original Document Chain (30 Years)',
      description: 'Verify sale deed, mother deed chain for last 30 years',
      office: 'Sub-Registrar Office',
      counter: 'Document search / Record Room',
      carry: 'Survey number, current owner name, approximate year of purchase',
      canPartiallyCheck: false,
      digitalNote: 'Pre-2004 documents not digitized — physical visit mandatory',
      icon: Icons.description,
    ),
    _VerificationItem(
      title: 'Tahsildar Mutation Verification',
      description: 'Confirm mutation entries with revenue officer stamp',
      office: 'Taluk Office (Tahsildar)',
      counter: 'Revenue Section',
      carry: 'Bhoomi RTC printout, mutation number',
      canPartiallyCheck: true,
      digitalNote: 'Mutation history fetched from Bhoomi — physical stamp needed',
      icon: Icons.approval,
    ),
    _VerificationItem(
      title: 'Physical Boundary Verification',
      description: 'Compare survey sketch with actual site boundaries',
      office: 'Licensed Government Surveyor',
      counter: 'Survey Department, District Office',
      carry: 'Survey sketch, RTC printout',
      canPartiallyCheck: false,
      digitalNote: 'GPS captured — physical measurement by surveyor needed',
      icon: Icons.map,
    ),
    _VerificationItem(
      title: 'Bank NOC (if mortgaged)',
      description: 'Get No Objection Certificate if property had a loan',
      office: 'Bank that issued the loan',
      counter: 'Loans / Legal Department',
      carry: 'Encumbrance certificate showing bank name',
      canPartiallyCheck: true,
      digitalNote: 'Encumbrance check done — verify NOC if loan existed',
      icon: Icons.account_balance_wallet,
    ),
    _VerificationItem(
      title: 'Gram Panchayat / BBMP NOC',
      description: 'Check for any pending dues or objections',
      office: 'Local Gram Panchayat or BBMP Ward Office',
      counter: 'Property Tax Counter',
      carry: 'Khata number, survey number',
      canPartiallyCheck: false,
      digitalNote: 'Property tax status checked — NOC needs physical collection',
      icon: Icons.location_city,
    ),
    _VerificationItem(
      title: 'Will / Inheritance Dispute Check',
      description: 'Check for family disputes on ownership if inherited property',
      office: 'Civil Court — Probate Division',
      counter: 'Filing Section',
      carry: 'Owner name, survey number, approximate inheritance year',
      canPartiallyCheck: false,
      digitalNote: 'Cannot be checked digitally — only family/court records show',
      icon: Icons.family_restroom,
    ),
  ];

  int get _completedCount => _items.where((i) => i.isDone).length;
  double get _progress => _completedCount / _items.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Physical Verification'),
        backgroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '$_completedCount/${_items.length}',
                style: TextStyle(
                  color: _completedCount == _items.length
                      ? AppColors.safe
                      : AppColors.textLight,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (context, index) =>
                  _buildVerificationCard(_items[index], index),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.caution.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.caution.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, size: 14, color: AppColors.caution),
                    const SizedBox(width: 4),
                    Text(
                      'Phase 2 — Human Verification Required',
                      style: TextStyle(
                        color: AppColors.caution,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'These checks cannot be done digitally.\nVisit each office and mark as done.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textLight,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _progress,
              backgroundColor: AppColors.background,
              valueColor: AlwaysStoppedAnimation<Color>(
                _completedCount == _items.length
                    ? AppColors.safe
                    : AppColors.primary,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _completedCount == _items.length
                ? '✅ All physical checks complete — safe to proceed'
                : '$_completedCount of ${_items.length} checks completed',
            style: TextStyle(
              fontSize: 12,
              color: _completedCount == _items.length
                  ? AppColors.safe
                  : AppColors.textLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationCard(_VerificationItem item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.isDone
              ? AppColors.safe.withOpacity(0.3)
              : AppColors.borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: item.isDone
                  ? AppColors.safe.withOpacity(0.1)
                  : AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              item.isDone ? Icons.check_circle : item.icon,
              color: item.isDone ? AppColors.safe : AppColors.primary,
              size: 22,
            ),
          ),
          title: Text(
            item.title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: item.isDone ? AppColors.textLight : AppColors.textDark,
              decoration: item.isDone ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Text(
            item.description,
            style: const TextStyle(fontSize: 12, color: AppColors.textLight),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.canPartiallyCheck)
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.safe.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.safe.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 14, color: AppColors.safe),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item.digitalNote,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.safe,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  _buildInfoRow(Icons.business, 'Office', item.office),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.place, 'Counter', item.counter),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.folder, 'Carry with you', item.carry),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _copyToClipboard(item),
                          icon: const Icon(Icons.copy, size: 14),
                          label: const Text('Copy Details'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _toggleDone(index),
                          icon: Icon(
                            item.isDone ? Icons.undo : Icons.check,
                            size: 14,
                          ),
                          label: Text(item.isDone ? 'Undo' : 'Mark Done'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: item.isDone
                                ? AppColors.textLight
                                : AppColors.safe,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppColors.textLight),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textLight,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, color: AppColors.textDark),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final allDone = _completedCount == _items.length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.borderColor)),
      ),
      child: Column(
        children: [
          if (!allDone)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.danger.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.danger),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'DO NOT complete purchase until all checks are marked done.',
                      style: TextStyle(fontSize: 12, color: AppColors.danger),
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: allDone
                  ? () => context.push('/partners')
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: allDone ? AppColors.safe : AppColors.textLight,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                allDone
                    ? 'All Done — Get Expert Help'
                    : '${_items.length - _completedCount} checks remaining',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleDone(int index) {
    setState(() => _items[index].isDone = !_items[index].isDone);
  }

  void _copyToClipboard(_VerificationItem item) {
    final text = '''
DigiSampatti — Physical Verification
${item.title}

Office: ${item.office}
Counter: ${item.counter}
Carry: ${item.carry}
    ''';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }
}

class _VerificationItem {
  final String title;
  final String description;
  final String office;
  final String counter;
  final String carry;
  final bool canPartiallyCheck;
  final String digitalNote;
  final IconData icon;
  bool isDone;

  _VerificationItem({
    required this.title,
    required this.description,
    required this.office,
    required this.counter,
    required this.carry,
    required this.canPartiallyCheck,
    required this.digitalNote,
    required this.icon,
    this.isDone = false,
  });
}
