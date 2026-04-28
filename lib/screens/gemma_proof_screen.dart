library;

import 'package:flutter/material.dart';

import '../services/hybrid_ai_service.dart';

class GemmaProofScreen extends StatefulWidget {
  final HybridAIService aiService;

  const GemmaProofScreen({
    super.key,
    required this.aiService,
  });

  @override
  State<GemmaProofScreen> createState() => _GemmaProofScreenState();
}

class _GemmaProofScreenState extends State<GemmaProofScreen> {
  final TextEditingController _promptController = TextEditingController(
    text: 'Perkenalkan dirimu singkat dalam bahasa Indonesia dan sebutkan bahwa kamu berjalan lokal di device.',
  );

  bool _isInitializing = false;
  bool _isGenerating = false;
  double _downloadProgress = 0.0;
  String _statusText = 'Belum diinisialisasi';
  String _responseText = '';
  String? _errorText;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _initializeGemma() async {
    setState(() {
      _isInitializing = true;
      _downloadProgress = 0.0;
      _errorText = null;
      _statusText = 'Menyiapkan Gemma lokal...';
    });

    try {
      final ready = await widget.aiService.initialize(
        onDownloadProgress: (progress) {
          if (!mounted) return;
          setState(() {
            _downloadProgress = progress;
            _statusText =
                'Mengunduh model Gemma... ${(progress * 100).toStringAsFixed(0)}%';
          });
        },
      );

      if (!mounted) return;
      setState(() {
        _errorText = ready ? null : widget.aiService.localAIErrorMessage;
        _statusText = ready ? 'Gemma siap dipakai' : 'Inisialisasi gagal';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = e.toString();
        _statusText = 'Inisialisasi gagal';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _generateProof() async {
    if (!widget.aiService.isLocalAIReady) {
      setState(() {
        _errorText = 'Gemma belum siap. Jalankan inisialisasi dulu.';
      });
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorText = null;
      _responseText = '';
    });

    try {
      await for (final chunk in widget.aiService.generateLocalResponseStream(
        prompt: _promptController.text.trim(),
        systemPrompt:
            'Jawab singkat dan jelas. Jika kamu bisa menjawab prompt ini, berarti inferensi lokal berhasil.',
      )) {
        if (!mounted) return;
        setState(() {
          _responseText += chunk;
        });
      }

      if (!mounted) return;
      setState(() {
        _statusText = 'Streaming selesai';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Color _statusColor(ThemeData theme) {
    if (widget.aiService.isLocalAIReady) return Colors.green.shade700;
    if (_errorText != null) return theme.colorScheme.error;
    return Colors.orange.shade800;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bukti Gemma Lokal'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD1D5DB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Screen ini bypass flow hybrid dan memanggil Gemma lokal langsung.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kalau teks muncul bertahap di bawah, berarti plugin, model, dan streaming inference lokal sudah bekerja.',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _statusText,
                    style: TextStyle(
                      color: _statusColor(theme),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_downloadProgress > 0 && _isInitializing) ...[
                    const SizedBox(height: 12),
                    LinearProgressIndicator(value: _downloadProgress),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isInitializing ? null : _initializeGemma,
                      icon: _isInitializing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.memory),
                      label: Text(
                        _isInitializing ? 'Menginisialisasi...' : 'Inisialisasi Gemma',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _promptController,
              minLines: 4,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Prompt Uji',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateProof,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(_isGenerating ? 'Menjalankan Prompt...' : 'Jalankan Prompt'),
              ),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Text(
                  _errorText!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(16),
              ),
              child: SelectableText(
                _responseText.isEmpty
                    ? 'Output akan muncul di sini setelah prompt berhasil dijalankan.'
                    : _responseText,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'monospace',
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
