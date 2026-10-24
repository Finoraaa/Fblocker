import 'package:flutter/material.dart';
import '../models/block_log.dart';
import '../services/blocker_service.dart';
import '../theme/finora_theme.dart';

class LogsScreen extends StatefulWidget {
  final BlockerService service;

  const LogsScreen({
    super.key,
    required this.service,
  });

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  String _filter = 'all'; // 'all', 'blocked', 'allowed'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showLogDetails(BuildContext context, BlockLog log) {
    showModalBottomSheet(
      context: context,
      backgroundColor: FinoraColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: FinoraColors.border),
      ),
      builder: (context) {
        final isBlocked = log.action == LogAction.blocked;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isBlocked ? Icons.block : Icons.check_circle,
                    color: isBlocked ? FinoraColors.red : FinoraColors.green,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      log.domain,
                      style: const TextStyle(
                        color: FinoraColors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildDetailRow('Durum', isBlocked ? 'Engellendi' : 'İzin Verildi'),
              _buildDetailRow('Kategori', log.categoryName),
              _buildDetailRow('Eşleşen Kural', log.ruleMatched),
              _buildDetailRow('İstemci', log.clientIp),
              _buildDetailRow('Zaman Damgası', log.timestamp.toLocal().toString().substring(11, 19)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        widget.service.addWhitelist(log.domain);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${log.domain} Beyaz Listeye eklendi'),
                            backgroundColor: FinoraColors.cardHover,
                          ),
                        );
                      },
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Beyaz Listeye Ekle'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FinoraColors.cardHover,
                        foregroundColor: FinoraColors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        widget.service.addBlacklist(log.domain);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${log.domain} Kara Listeye eklendi'),
                            backgroundColor: FinoraColors.redDark,
                          ),
                        );
                      },
                      icon: const Icon(Icons.shield, size: 16),
                      label: const Text('Kara Listeye Al'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FinoraColors.red,
                        foregroundColor: FinoraColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: FinoraColors.textMuted, fontSize: 13)),
          Text(value, style: const TextStyle(color: FinoraColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allLogs = widget.service.logs;

    final filteredLogs = allLogs.where((log) {
      if (_filter == 'blocked' && log.action != LogAction.blocked) return false;
      if (_filter == 'allowed' && log.action != LogAction.allowed) return false;
      if (_searchQuery.isNotEmpty && !log.domain.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row with Clear Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'CANLI TRAFİK GÜNLÜĞÜ',
                style: TextStyle(
                  color: FinoraColors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: 1.0,
                ),
              ),
              IconButton(
                onPressed: widget.service.clearLogs,
                icon: const Icon(Icons.delete_sweep_outlined, color: FinoraColors.textMuted),
                tooltip: 'Günlüğü Temizle',
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search Field
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Etki alanı ara (örn: google, doubleclick)...',
              prefixIcon: const Icon(Icons.search, color: FinoraColors.textMuted, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: FinoraColors.textMuted, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),

          // Filter Chips
          Row(
            children: [
              _buildFilterChip('all', 'Tümü (${allLogs.length})'),
              const SizedBox(width: 8),
              _buildFilterChip('blocked', 'Engellenenler', color: FinoraColors.red),
              const SizedBox(width: 8),
              _buildFilterChip('allowed', 'İzin Verilenler', color: FinoraColors.green),
            ],
          ),
          const SizedBox(height: 14),

          // Log List
          Expanded(
            child: filteredLogs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.query_builder, size: 48, color: FinoraColors.borderLight),
                        const SizedBox(height: 12),
                        const Text(
                          'Kayıt bulunamadı.',
                          style: TextStyle(color: FinoraColors.textMuted, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredLogs.length,
                    itemBuilder: (context, index) {
                      final log = filteredLogs[index];
                      final isBlocked = log.action == LogAction.blocked;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: FinoraColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: FinoraColors.border),
                        ),
                        child: ListTile(
                          onTap: () => _showLogDetails(context, log),
                          dense: true,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isBlocked
                                  ? FinoraColors.red.withValues(alpha: 0.12)
                                  : FinoraColors.green.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isBlocked ? Icons.block : Icons.check_circle_outline,
                              size: 18,
                              color: isBlocked ? FinoraColors.red : FinoraColors.green,
                            ),
                          ),
                          title: Text(
                            log.domain,
                            style: const TextStyle(
                              color: FinoraColors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Row(
                            children: [
                              Text(
                                log.categoryName,
                                style: TextStyle(
                                  color: isBlocked ? FinoraColors.redLight : FinoraColors.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('•', style: TextStyle(color: FinoraColors.borderLight)),
                              const SizedBox(width: 8),
                              Text(
                                log.timestamp.toLocal().toString().substring(11, 19),
                                style: const TextStyle(color: FinoraColors.textMuted, fontSize: 11),
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.more_vert, color: FinoraColors.textMuted, size: 18),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, {Color? color}) {
    final isSelected = _filter == key;
    final activeColor = color ?? FinoraColors.red;

    return GestureDetector(
      onTap: () => setState(() => _filter = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.15) : FinoraColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : FinoraColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? FinoraColors.white : FinoraColors.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
