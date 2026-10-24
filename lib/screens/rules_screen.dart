import 'package:flutter/material.dart';
import '../services/blocker_service.dart';
import '../theme/finora_theme.dart';

class RulesScreen extends StatefulWidget {
  final BlockerService service;

  const RulesScreen({
    super.key,
    required this.service,
  });

  @override
  State<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends State<RulesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _domainController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _domainController.dispose();
    super.dispose();
  }

  void _addCurrentDomain() {
    final domain = _domainController.text.trim();
    if (domain.isEmpty) return;

    if (_tabController.index == 0) {
      widget.service.addWhitelist(domain);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$domain Beyaz Listeye eklendi'),
          backgroundColor: FinoraColors.cardHover,
        ),
      );
    } else {
      widget.service.addBlacklist(domain);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$domain Kara Listeye eklendi'),
          backgroundColor: FinoraColors.redDark,
        ),
      );
    }
    _domainController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final whitelist = widget.service.whitelist.toList();
    final blacklist = widget.service.blacklist.toList();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tab Header
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: FinoraColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: FinoraColors.border),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: FinoraColors.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: FinoraColors.borderLight),
              ),
              labelColor: FinoraColors.white,
              unselectedLabelColor: FinoraColors.textMuted,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 16, color: FinoraColors.green),
                      const SizedBox(width: 6),
                      Text('Beyaz Liste (${whitelist.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.block, size: 16, color: FinoraColors.red),
                      const SizedBox(width: 6),
                      Text('Kara Liste (${blacklist.length})'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Add Domain Bar
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _domainController,
                  decoration: const InputDecoration(
                    hintText: 'Etki alanı girin (örn: youtube.com)',
                    prefixIcon: Icon(Icons.language, color: FinoraColors.textMuted, size: 20),
                  ),
                  onSubmitted: (_) => _addCurrentDomain(),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _addCurrentDomain,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
                child: const Text('Ekle'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Lists
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDomainList(
                  domains: whitelist,
                  isWhitelist: true,
                  onRemove: widget.service.removeWhitelist,
                  emptyText: 'Beyaz listede özel kural yok. Tüm temiz istekler geçer.',
                ),
                _buildDomainList(
                  domains: blacklist,
                  isWhitelist: false,
                  onRemove: widget.service.removeBlacklist,
                  emptyText: 'Kara listede özel kural yok. Filtre listeleri standart engelleme yapar.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDomainList({
    required List<String> domains,
    required bool isWhitelist,
    required ValueChanged<String> onRemove,
    required String emptyText,
  }) {
    if (domains.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isWhitelist ? Icons.verified : Icons.security,
              size: 48,
              color: FinoraColors.borderLight,
            ),
            const SizedBox(height: 12),
            Text(
              emptyText,
              style: const TextStyle(color: FinoraColors.textMuted, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: domains.length,
      itemBuilder: (context, index) {
        final domain = domains[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: FinoraColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: FinoraColors.border),
          ),
          child: ListTile(
            dense: true,
            leading: Icon(
              isWhitelist ? Icons.check : Icons.block,
              color: isWhitelist ? FinoraColors.green : FinoraColors.red,
              size: 18,
            ),
            title: Text(
              domain,
              style: const TextStyle(
                color: FinoraColors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.close, color: FinoraColors.textMuted, size: 18),
              onPressed: () => onRemove(domain),
              tooltip: 'Listeden Kaldır',
            ),
          ),
        );
      },
    );
  }
}
