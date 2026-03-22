import 'package:flutter/material.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';

class MutationGuideScreen extends StatefulWidget {
  const MutationGuideScreen({super.key});

  @override
  State<MutationGuideScreen> createState() => _MutationGuideScreenState();
}

class _MutationGuideScreenState extends State<MutationGuideScreen> {
  String _activeTab = 'Bhoomi';

  static const _bhoomiSteps = [
    _MutStep('1', 'Get Registered Sale Deed', 'Obtain certified copy of your registered sale deed from Sub-Registrar office. Usually ready within 2–3 working days.', 'Sub-Registrar Office', Icons.description),
    _MutStep('2', 'Login to Bhoomi Portal', 'Visit bhoomi.karnataka.gov.in → Citizen Services → Mutation Application (Form 7A). Create account if first time.', 'bhoomi.karnataka.gov.in', Icons.computer),
    _MutStep('3', 'Fill Mutation Form', 'Enter: District, Taluk, Hobli, Village, Survey Number, Hissa Number. Upload sale deed PDF and Aadhar of both buyer & seller.', 'Online Form', Icons.edit_document),
    _MutStep('4', 'Pay Mutation Fee', 'Pay ₹25–₹100 online (varies by district). Keep payment receipt.', 'Online Payment', Icons.payment),
    _MutStep('5', 'Village Accountant Inspection', 'VA visits property to verify. May take 15–30 days. You may need to follow up at Taluk office.', 'Taluk Office', Icons.person_search),
    _MutStep('6', 'Tahsildar Approval', 'Mutation order signed by Tahsildar. Updated RTC (Form 9) issued in new owner\'s name.', 'Taluk Office', Icons.approval),
    _MutStep('7', 'Download New RTC', 'Login to Bhoomi portal → Download Form 9 (RTC) with your name as owner. Keep certified copy.', 'bhoomi.karnataka.gov.in', Icons.download),
  ];

  static const _khataSteps = [
    _MutStep('1', 'Get Mutation Order Copy', 'Obtain certified copy of Bhoomi mutation order (Form 9 with new owner name).', 'Taluk Office', Icons.description),
    _MutStep('2', 'Visit BBMP / Panchayat Office', 'For BBMP areas: visit ward office. For rural: visit Gram Panchayat. Carry all documents.', 'Ward Office / Panchayat', Icons.location_city),
    _MutStep('3', 'Submit Form B', 'Fill Khata Transfer Application (Form B). Attach: Sale Deed copy, Mutation order, Previous Khata, Property tax receipts (3 years), Aadhar.', 'Ward Office', Icons.assignment),
    _MutStep('4', 'Pay Transfer Fee', 'Pay Khata transfer fee: 2% of property value (min ₹500). Get receipt.', 'Ward Office', Icons.payment),
    _MutStep('5', 'Inspector Visit', 'BBMP inspector verifies property details on-site. Timeline: 30–60 days typically.', 'Field Visit', Icons.person_search),
    _MutStep('6', 'New Khata Issued', 'New Khata Certificate + Khata Extract issued in your name. Property tax account updated.', 'Ward Office', Icons.approval),
    _MutStep('7', 'Update Property Tax', 'Ensure property tax records updated. Pay any pending dues. Get Property Tax Paid Receipt.', 'Ward Office / Online', Icons.receipt),
  ];

  List<_MutStep> get _steps => _activeTab == 'Bhoomi' ? _bhoomiSteps : _khataSteps;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Mutation Guide')),
      body: Column(
        children: [
          // Tab Selector
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Mutation Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 10),
                Row(
                  children: ['Bhoomi', 'Khata'].map((tab) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _activeTab = tab),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _activeTab == tab ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _activeTab == tab ? AppColors.primary : AppColors.borderColor),
                          ),
                          child: Column(
                            children: [
                              Text(tab == 'Bhoomi' ? 'Bhoomi Mutation' : 'Khata Transfer',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13,
                                  color: _activeTab == tab ? Colors.white : AppColors.textDark,
                                )),
                              Text(tab == 'Bhoomi' ? 'RTC Name Change' : 'BBMP / Panchayat',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _activeTab == tab ? Colors.white70 : AppColors.textLight,
                                )),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.primary, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _activeTab == 'Bhoomi'
                            ? 'Bhoomi mutation updates the RTC (land record) in your name. Do this FIRST.'
                            : 'Khata transfer updates property tax records. Do this AFTER Bhoomi mutation.',
                          style: const TextStyle(fontSize: 11, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Timeline
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _steps.length,
              itemBuilder: (context, i) {
                final step = _steps[i];
                final isLast = i == _steps.length - 1;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(child: Text(step.step,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                        ),
                        if (!isLast) Container(width: 2, height: 60, color: AppColors.borderColor),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(step.icon, size: 16, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Expanded(child: Text(step.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(step.description,
                              style: const TextStyle(fontSize: 12, color: AppColors.textMedium, height: 1.4)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.place, size: 12, color: AppColors.textLight),
                                const SizedBox(width: 4),
                                Text(step.where,
                                  style: const TextStyle(fontSize: 11, color: AppColors.textLight, fontStyle: FontStyle.italic)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Bottom note
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.statusWarningBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.access_time, size: 16, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _activeTab == 'Bhoomi'
                        ? 'Bhoomi mutation typically takes 30–90 days. Follow up at Taluk office if delayed. Hire a document agent (₹2,000–₹5,000) to assist.'
                        : 'Khata transfer takes 30–90 days in BBMP areas. Rural Panchayat: 15–30 days. Hiring a document agent (₹1,500–₹3,000) speeds up the process.',
                      style: const TextStyle(fontSize: 11, color: AppColors.warning, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MutStep {
  final String step;
  final String title;
  final String description;
  final String where;
  final IconData icon;
  const _MutStep(this.step, this.title, this.description, this.where, this.icon);
}
