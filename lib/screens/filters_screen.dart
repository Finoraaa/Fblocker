import 'package:flutter/material.dart';
import '../services/blocker_service.dart';
import '../theme/finora_theme.dart';

class FiltersScreen extends StatefulWidget {
  final BlockerService service;

  const FiltersScreen({
    super.key,
    required this.service,
  });

  @override
  State<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  void _showAddFilterDialog(BuildContext context) {
    final nameController = TextEditingController();
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: FinoraColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: FinoraColors.border),
          ),
          title: const Text(
            'ÖZEL FİLTRE LİSTESİ EKLE',
            style: TextStyle(
              color: FinoraColors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
              letterSpacing: 0.8,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Liste Adı',
                  hintText: 'Örn: Türkiye Reklam Engel Listesi',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: 'Filtre Listesi URL (hosts veya EasyList)',
                  hintText: 'https://ornek.com/filters.txt',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal', style: TextStyle(color: FinoraColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final url = urlController.text.trim();
                if (name.isNotEmpty && url.isNotEmpty) {
                  widget.service.addCustomFilterList(name, url);
                  Navigator.pop(context);
                }
              },
              child: const Text('Listeyi Ekle'),
            ),
          ],
        );
      },
    );
  }

  String _formatRules(int rules) {
    if (rules >= 1000) {
      return '${(rules / 1000).toStringAsFixed(1)}K Kural';
    }
    return '$rules Kural';
  }

  @override
  Widget build(BuildContext context) {
    final lists = widget.service.filterLists;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with total active rules summary
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  FinoraColors.redDark.withValues(alpha: 0.3),
                  FinoraColors.card,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: FinoraColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOPLAM AKTİF KURAL SAYISI',
                      style: TextStyle(
                        color: FinoraColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.service.totalActiveRules.toString(),
                      style: const TextStyle(
                        color: FinoraColors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddFilterDialog(context),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Liste Ekle'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'YÜKLÜ FİLTRE VERİTABANLARI',
            style: TextStyle(
              color: FinoraColors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: ListView.builder(
              itemCount: lists.length,
              itemBuilder: (context, index) {
                final list = lists[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: FinoraColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: list.isEnabled ? FinoraColors.borderLight : FinoraColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: list.isEnabled
                              ? FinoraColors.red.withValues(alpha: 0.12)
                              : FinoraColors.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          list.isBuiltIn ? Icons.verified_user : Icons.public,
                          color: list.isEnabled ? FinoraColors.red : FinoraColors.textMuted,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    list.name,
                                    style: const TextStyle(
                                      color: FinoraColors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                if (list.isBuiltIn)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: FinoraColors.surface,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: FinoraColors.border),
                                    ),
                                    child: const Text(
                                      'RESMİ',
                                      style: TextStyle(
                                        color: FinoraColors.textMuted,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              list.description,
                              style: const TextStyle(
                                color: FinoraColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(
                                  _formatRules(list.ruleCount),
                                  style: TextStyle(
                                    color: list.isEnabled ? FinoraColors.redLight : FinoraColors.textMuted,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text('•', style: TextStyle(color: FinoraColors.borderLight)),
                                const SizedBox(width: 8),
                                Text(
                                  'Güncellendi: ${list.lastUpdated.day}/${list.lastUpdated.month}',
                                  style: const TextStyle(
                                    color: FinoraColors.textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Switch(
                        value: list.isEnabled,
                        onChanged: (val) => widget.service.toggleFilterList(list.id),
                      ),
                    ],
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
