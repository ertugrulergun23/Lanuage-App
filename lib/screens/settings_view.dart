import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        final isDark = state.isDarkMode;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Screen Header
              Text(
                'Application Settings',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.indigo[200] : Colors.indigo[900],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Customize your vocabulary learning experience.',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),

              // Theme Configuration Card
              Card(
                elevation: isDark ? 1 : 2,
                shadowColor: Colors.black12,
                color: isDark ? Colors.grey[900] : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                    width: 0.8,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'APPEARANCE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.indigo[200] : Colors.indigo[700],
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: Colors.indigo.withOpacity(0.2),
                          child: const Icon(
                            Icons.dark_mode_rounded,
                            color: Colors.indigo,
                          ),
                        ),
                        title: const Text(
                          'Dark Theme Mode',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                        subtitle: const Text(
                          'Forced premium Dark Theme style active',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Statistics Card
              Card(
                elevation: isDark ? 1 : 2,
                shadowColor: Colors.black12,
                color: isDark ? Colors.grey[900] : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                    width: 0.8,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SYSTEM STATISTICS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.indigo[200] : Colors.indigo[700],
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Stat 1: Words
                      _buildStatRow(
                        icon: Icons.bookmark_added_rounded,
                        label: 'Library Vocabulary Pairs',
                        value: '${state.words.length}',
                        isDark: isDark,
                      ),
                      const Divider(height: 24),

                      // Stat 2: Topics
                      _buildStatRow(
                        icon: Icons.category_rounded,
                        label: 'Cached Writing Topics',
                        value: '${state.topics.length}',
                        isDark: isDark,
                      ),
                      const Divider(height: 24),

                      // Stat 3: Connection status
                      _buildStatRow(
                        icon: state.isOnline ? Icons.cloud_done : Icons.cloud_off,
                        label: 'Network Synced State',
                        value: state.isOnline ? 'Online Synced' : 'Offline Cached',
                        isDark: isDark,
                        valueColor: state.isOnline ? Colors.teal : Colors.orange[700],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // System Logs Card
              Card(
                elevation: isDark ? 1 : 2,
                shadowColor: Colors.black12,
                color: isDark ? Colors.grey[900] : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                    width: 0.8,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'SİSTEM GÜNLÜĞÜ / HATA LOGLARI',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.indigo[200] : Colors.indigo[700],
                              letterSpacing: 1.2,
                            ),
                          ),
                          if (state.errorLogs.isNotEmpty)
                            TextButton.icon(
                              onPressed: () => state.clearLogs(),
                              icon: const Icon(Icons.delete_sweep_rounded, size: 18, color: Colors.redAccent),
                              label: const Text(
                                'Temizle',
                                style: TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.bold),
                              ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      Container(
                        width: double.infinity,
                        height: 160,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black26 : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                            width: 0.5,
                          ),
                        ),
                        child: state.errorLogs.isEmpty
                            ? Center(
                                child: Text(
                                  'Henüz bir hata günlüğü kaydedilmedi.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(12),
                                itemCount: state.errorLogs.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 6.0),
                                    child: SelectableText(
                                      state.errorLogs[index],
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 11,
                                        color: isDark ? Colors.amber[100] : const Color(0xFFC0392B),
                                        height: 1.4,
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // App Version & Signature
              Center(
                child: Column(
                  children: [
                    Text(
                      'LingoLib v1.0.0',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Designed for Modern Language Acquirers',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.grey[700] : Colors.grey[400],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: isDark ? Colors.grey[400] : Colors.grey[500]),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[300] : Colors.black87,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: valueColor ?? (isDark ? Colors.white : Colors.black87),
          ),
        ),
      ],
    );
  }
}
