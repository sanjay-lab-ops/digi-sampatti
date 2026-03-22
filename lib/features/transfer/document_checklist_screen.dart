import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:digi_sampatti/core/constants/app_colors.dart';

class DocumentChecklistScreen extends StatefulWidget {
  const DocumentChecklistScreen({super.key});

  @override
  State<DocumentChecklistScreen> createState() => _DocumentChecklistScreenState();
}

class _DocumentChecklistScreenState extends State<DocumentChecklistScreen> {
  String _transferType = 'Sale';

  static const _saleDocs = [
    _Doc('Original Title Deed / Mother Deed', 'Chain of ownership from original to current owner', true),
    _Doc('Bhoomi RTC Extract', 'Latest RTC from bhoomi.karnataka.gov.in', true),
    _Doc('Encumbrance Certificate (EC)', 'Last 30 years from Sub-Registrar office', true),
    _Doc('Khata Certificate + Extract', 'From BBMP / Gram Panchayat', true),
    _Doc('Property Tax Receipts', 'Last 3 years paid receipts', true),
    _Doc('Aadhar + PAN of Buyer', 'Both buyer and seller copies', true),
    _Doc('Passport Photos', '2 each for buyer and seller', true),
    _Doc('Sale Agreement / Draft Deed', 'Prepared by registered advocate', true),
    _Doc('Bank NOC (if mortgaged)', 'No Objection from loan bank', false),
    _Doc('Power of Attorney', 'If seller is NRI or unavailable', false),
    _Doc('Death Certificate + Legal Heir', 'If inherited property', false),
  ];

  static const _inheritanceDocs = [
    _Doc('Death Certificate of Previous Owner', 'Original + attested copy', true),
    _Doc('Legal Heir Certificate', 'From Tahsildar office', true),
    _Doc('Succession Certificate', 'From Civil Court if disputed', false),
    _Doc('Will (if exists)', 'Registered will from Sub-Registrar', false),
    _Doc('Bhoomi RTC Extract', 'Current land record', true),
    _Doc('Aadhar of all legal heirs', 'All claimants\' ID proof', true),
    _Doc('NOC from other heirs', 'If only one heir transferring', false),
  ];

  static const _giftDocs = [
    _Doc('Gift Deed (drafted by advocate)', 'Stamped and registered deed', true),
    _Doc('Original Title Deed', 'Proof of donor\'s ownership', true),
    _Doc('Bhoomi RTC Extract', 'Current land record', true),
    _Doc('Aadhar of donor + recipient', 'Both parties ID proof', true),
    _Doc('Relationship proof', 'If claiming stamp duty exemption', false),
    _Doc('Khata Certificate', 'For Khata transfer after gift', true),
  ];

  List<_Doc> get _docs {
    switch (_transferType) {
      case 'Sale': return _saleDocs;
      case 'Inheritance': return _inheritanceDocs;
      case 'Gift': return _giftDocs;
      default: return _saleDocs;
    }
  }

  final Set<int> _checked = {};

  @override
  Widget build(BuildContext context) {
    final mandatory = _docs.where((d) => d.mandatory).length;
    final checked = _checked.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Document Checklist'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: Text('$checked/${_docs.length}',
              style: TextStyle(
                color: checked == _docs.length ? AppColors.safe : AppColors.textLight,
                fontWeight: FontWeight.bold,
              ),
            )),
          ),
        ],
      ),
      body: Column(
        children: [
          // Transfer type selector
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Transfer Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 10),
                Row(
                  children: ['Sale', 'Inheritance', 'Gift'].map((type) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() { _transferType = type; _checked.clear(); }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _transferType == type ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _transferType == type ? AppColors.primary : AppColors.borderColor),
                          ),
                          child: Text(type, textAlign: TextAlign.center, style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13,
                            color: _transferType == type ? Colors.white : AppColors.textDark,
                          )),
                        ),
                      ),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: _docs.isEmpty ? 0 : checked / _docs.length,
                  backgroundColor: AppColors.borderColor,
                  color: AppColors.primary,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
                const SizedBox(height: 6),
                Text('$checked of ${_docs.length} documents ready ($mandatory mandatory)',
                  style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _docs.length,
              itemBuilder: (context, i) {
                final doc = _docs[i];
                final isChecked = _checked.contains(i);
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isChecked ? AppColors.safe.withOpacity(0.4) : AppColors.borderColor),
                  ),
                  child: CheckboxListTile(
                    value: isChecked,
                    onChanged: (_) => setState(() {
                      if (isChecked) _checked.remove(i);
                      else _checked.add(i);
                    }),
                    title: Row(
                      children: [
                        Expanded(child: Text(doc.name, style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          decoration: isChecked ? TextDecoration.lineThrough : null,
                          color: isChecked ? AppColors.textLight : AppColors.textDark,
                        ))),
                        if (doc.mandatory)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Must', style: TextStyle(fontSize: 9, color: AppColors.danger, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(doc.description, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                    ),
                    activeColor: AppColors.safe,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Doc {
  final String name;
  final String description;
  final bool mandatory;
  const _Doc(this.name, this.description, this.mandatory);
}
