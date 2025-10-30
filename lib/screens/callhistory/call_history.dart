import 'package:audioplayers/audioplayers.dart';
import 'package:ebv/provider/patient_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/custom_table.dart';

class CallHistory extends ConsumerStatefulWidget {
  const CallHistory({super.key});

  @override
  ConsumerState<CallHistory> createState() => _CallHistoryState();
}

class _CallHistoryState extends ConsumerState<CallHistory> {
  TextEditingController textController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isCardView = true;
  String? _currentlyPlayingUrl;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      // ref.read(patientProvider.notifier).getPatientsCallHistory(context);
    });

    // Set up player listeners
    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      if (state == PlayerState.stopped || state == PlayerState.completed) {
        if (mounted) {
          setState(() {
            _currentlyPlayingUrl = null;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    textController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(patientProvider);
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF29BFFF),
                Color(0xFF8548D0),
              ],
            ),
          ),
        ),
        elevation: 0,
        title: const Text(
          'Call History',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: Icon(
                _isCardView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                size: 22,
              ),
              onPressed: () {
                setState(() {
                  _isCardView = !_isCardView;
                });
              },
              tooltip: _isCardView ? 'Table View' : 'Card View',
              color: Colors.white,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(
              'assets/images/dentiverify-logo.png',
              width: 120,
              height: 40,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
      body: state.isLoading
          ? _buildLoadingState()
          : Column(
        children: [
          _buildHeaderSection(state),
          const SizedBox(height: 16),
          Expanded(
            child: state.patientCallHistory == null || state.patientCallHistory!.isEmpty
                ? _buildEmptyState()
                : _isCardView
                ? _buildCardView(state, context)
                : _buildTableView(state, context),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              color: Colors.blue,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading Call History...',
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait a moment',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(PatientState state) {
    final count = state.patientCallHistory?.length ?? 0;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF667eea),
            Color(0xFF764ba2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Calls',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    count.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isCardView ? Icons.grid_view_rounded : Icons.view_list_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isCardView ? 'Cards' : 'Table',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSearchBar(ref),
        ],
      ),
    );
  }

  Widget _buildSearchBar(WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: CupertinoSearchTextField(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        onChanged: (value) {
          // Add search functionality here
          // ref.read(patientProvider.notifier).searchCallHistory(value);
        },
        controller: textController,
        placeholder: 'Search calls by name, phone, or type...',
        prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
        suffixIcon: const Icon(Icons.close_rounded, color: Colors.grey),
        style: const TextStyle(fontSize: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.history_toggle_off_rounded,
              size: 80,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "No Call History Found",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Try adjusting your search or filter criteria",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Add refresh functionality
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
            ),
            child: const Text('Refresh Data'),
          ),
        ],
      ),
    );
  }

  Widget _buildTableView(PatientState state, BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CommonDataTable<dynamic>(
            dataList: state.patientCallHistory!,
            columns: const [
              DataColumn(
                  label: Text('ID',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
              DataColumn(
                  label: Text('Name',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
              DataColumn(
                  label: Text('Caller',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
              DataColumn(
                  label: Text('Type',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
              DataColumn(
                  label: Text('Payer',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
              DataColumn(
                  label: Text('Phone',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
              DataColumn(
                  label: Text('Recording',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
            ],
            dataSourceBuilder: (dataList) => GenericDataSource<dynamic>(
              dataList,
                  (item) => [
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item['Source'].toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 100,
                    child: Text(
                      item['firstName'] ?? 'NA',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item['CallSource'] ?? '--',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getCallTypeColor(item['calltype']).withOpacity(0.15),
                      border: Border.all(color: _getCallTypeColor(item['calltype']).withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item['calltype']?.toString() ?? '--',
                      style: TextStyle(
                        fontSize: 11,
                        color: _getCallTypeColor(item['calltype']),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 80,
                    child: Text(
                      item['insurancePayer'] ?? '--',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item['Phoneno'] ?? '--',
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Center(
                    child: AudioPlayerWidget(
                      audioUrl: item['audiourl'] ?? '',
                      audioPlayer: _audioPlayer,
                      isPlaying: _currentlyPlayingUrl == item['audiourl'],
                      onPlayStateChanged: (bool isPlaying) {
                        setState(() {
                          if (isPlaying) {
                            _currentlyPlayingUrl = item['audiourl'];
                          } else if (_currentlyPlayingUrl == item['audiourl']) {
                            _currentlyPlayingUrl = null;
                          }
                        });
                      },
                    ),
                  ),
                ),
              ],
                  (dynamic data) {
                // Navigation logic if needed
              },
            ),
            onSelect: (person) {},
          ),
        ),
      ),
    );
  }

  Widget _buildCardView(PatientState state, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ListView.builder(
        itemCount: state.patientCallHistory!.length,
        itemBuilder: (context, index) {
          final call = state.patientCallHistory![index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: _buildCallCard(call, context),
          );
        },
      ),
    );
  }

  Widget _buildCallCard(dynamic call, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with ID and call type
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'ID: ${call['Source']}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getCallTypeColor(call['calltype']).withOpacity(0.15),
                    border: Border.all(color: _getCallTypeColor(call['calltype']).withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    call['calltype']?.toString() ?? '--',
                    style: TextStyle(
                      fontSize: 12,
                      color: _getCallTypeColor(call['calltype']),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Caller information
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF29BFFF), Color(0xFF8548D0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        call['firstName'] ?? 'Unknown Caller',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        call['CallSource'] ?? '--',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Call details in a nice grid
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildDetailItem(
                    Icons.phone_rounded,
                    'Phone',
                    call['Phoneno'] ?? '--',
                    Colors.blue,
                  ),
                  _buildDetailItem(
                    Icons.business_center_rounded,
                    'Payer',
                    call['insurancePayer'] ?? 'No Payer',
                    Colors.purple,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Audio player section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: AudioPlayerWidget(
                audioUrl: call['audiourl'] ?? '',
                audioPlayer: _audioPlayer,
                isPlaying: _currentlyPlayingUrl == call['audiourl'],
                onPlayStateChanged: (bool isPlaying) {
                  setState(() {
                    if (isPlaying) {
                      _currentlyPlayingUrl = call['audiourl'];
                    } else if (_currentlyPlayingUrl == call['audiourl']) {
                      _currentlyPlayingUrl = null;
                    }
                  });
                },
                compact: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String title, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _getCallTypeColor(callType) {
    if (callType == null) return Colors.grey;

    final type = callType.toString().toLowerCase();
    if (type.contains('incoming')) {
      return Colors.green;
    } else if (type.contains('outgoing')) {
      return Colors.blue;
    } else if (type.contains('missed')) {
      return Colors.red;
    } else if (type.contains('voicemail')) {
      return Colors.orange;
    } else {
      return Colors.grey;
    }
  }
}

class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  final AudioPlayer audioPlayer;
  final bool isPlaying;
  final Function(bool) onPlayStateChanged;
  final bool compact;

  const AudioPlayerWidget({
    super.key,
    required this.audioUrl,
    required this.audioPlayer,
    this.isPlaying = false,
    required this.onPlayStateChanged,
    this.compact = true,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  bool _isLoading = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _setupPlayerListeners();
  }

  void _setupPlayerListeners() {
    widget.audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        if (state == PlayerState.stopped || state == PlayerState.completed) {
          widget.onPlayStateChanged(false);
        }
      }
    });
  }

  Future<void> _togglePlay() async {
    if (_hasError || widget.audioUrl.isEmpty) return;

    try {
      setState(() => _isLoading = true);

      if (widget.isPlaying) {
        await widget.audioPlayer.stop();
        widget.onPlayStateChanged(false);
      } else {
        // Stop any currently playing audio
        await widget.audioPlayer.stop();

        // Play the new audio
        await widget.audioPlayer.setSource(UrlSource(
          widget.audioUrl,
          mimeType: 'audio/wav',
        ));
        await widget.audioPlayer.resume();
        widget.onPlayStateChanged(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _hasError = true);
        widget.onPlayStateChanged(false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error playing audio: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      // Compact version for table view
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: _isLoading
                  ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.blue[700],
                ),
              )
                  : Icon(
                _hasError
                    ? Icons.error_outline_rounded
                    : widget.isPlaying
                    ? Icons.stop_rounded
                    : Icons.play_arrow_rounded,
                size: 18,
                color: _hasError ? Colors.red : Colors.blue,
              ),
              onPressed: _togglePlay,
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );
    } else {
      // Expanded version for card view
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.audio_file_rounded, size: 18, color: Colors.grey),
              const SizedBox(width: 6),
              const Text(
                'Call Recording',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _hasError
                        ? Colors.red.shade50
                        : widget.isPlaying
                        ? Colors.red.shade50
                        : Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: _isLoading
                        ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.blue[700],
                      ),
                    )
                        : Icon(
                      _hasError
                          ? Icons.error_outline_rounded
                          : widget.isPlaying
                          ? Icons.stop_rounded
                          : Icons.play_arrow_rounded,
                      color: _hasError
                          ? Colors.red
                          : widget.isPlaying
                          ? Colors.red
                          : Colors.blue,
                      size: 20,
                    ),
                    onPressed: _togglePlay,
                    padding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isPlaying ? 'Playing...' : 'Tap to play',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: widget.isPlaying ? Colors.green : Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: widget.isPlaying ? null : 0,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          widget.isPlaying ? Colors.green : Colors.blue,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: Icon(
                    Icons.volume_up_rounded,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                  onPressed: () => _showVolumeSlider(context),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }

  void _showVolumeSlider(BuildContext context) {
    double volume = 1.0;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Adjust Volume'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Slider(
                    value: volume,
                    min: 0,
                    max: 1,
                    divisions: 10,
                    onChanged: (value) {
                      setState(() => volume = value);
                      widget.audioPlayer.setVolume(value);
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Volume: ${(volume * 100).round()}%',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}