import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models.dart';
import '../../core/store.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';

/// 本地音乐播放器（新增功能 7）
class MusicPage extends StatefulWidget {
  const MusicPage({super.key});

  @override
  State<MusicPage> createState() => _MusicPageState();
}

class _MusicPageState extends State<MusicPage> {
  final _player = AudioPlayer();
  int? _currentIndex;
  bool _playing = false;
  Duration _pos = Duration.zero;
  Duration _dur = Duration.zero;
  int _mode = 0; // 0 顺序 1 单曲 2 随机

  static const _modeLabels = ['顺序播放', '单曲循环', '随机播放'];
  static const _modeIcons = ['🔁', '🔂', '🔀'];

  @override
  void initState() {
    super.initState();
    _player.onPositionChanged.listen((d) {
      if (mounted) setState(() => _pos = d);
    });
    _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _dur = d);
    });
    _player.onPlayerComplete.listen((_) {
      if (mounted) _onComplete();
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  int _nextIndex(int total) {
    if (total <= 0) return 0;
    if (_mode == 1) return _currentIndex ?? 0;
    if (_mode == 2) {
      final i = DateTime.now().millisecondsSinceEpoch % total;
      return i == _currentIndex && total > 1 ? (i + 1) % total : i;
    }
    return ((_currentIndex ?? -1) + 1) % total;
  }

  Future<void> _playAt(int index) async {
    final store = context.read<AppStore>();
    if (store.musicTracks.isEmpty) return;
    final track = store.musicTracks[index];
    await _player.stop();
    await _player.play(DeviceFileSource(track.path));
    if (!mounted) return;
    setState(() {
      _currentIndex = index;
      _playing = true;
    });
  }

  void _onComplete() {
    final store = context.read<AppStore>();
    if (store.musicTracks.isEmpty) return;
    _playAt(_nextIndex(store.musicTracks.length));
  }

  Future<void> _toggle() async {
    if (_currentIndex == null) {
      final store = context.read<AppStore>();
      if (store.musicTracks.isEmpty) {
        tipSnackBar(context, '先导入一首歌吧 🎵');
        return;
      }
      await _playAt(0);
      return;
    }
    if (_playing) {
      await _player.pause();
      if (mounted) setState(() => _playing = false);
    } else {
      await _player.resume();
      if (mounted) setState(() => _playing = true);
    }
  }

  Future<void> _next() async {
    final store = context.read<AppStore>();
    if (store.musicTracks.isEmpty) return;
    await _playAt(_nextIndex(store.musicTracks.length));
  }

  Future<void> _prev() async {
    final store = context.read<AppStore>();
    if (store.musicTracks.isEmpty) return;
    final i = ((_currentIndex ?? 1) - 1 + store.musicTracks.length) % store.musicTracks.length;
    await _playAt(i);
  }

  Future<void> _import() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.audio, allowMultiple: true);
    if (res == null || res.files.isEmpty) return;
    final store = context.read<AppStore>();
    var added = 0;
    for (final f in res.files) {
      if (f.path == null) continue;
      final name = (f.name.contains('.')) ? f.name.substring(0, f.name.lastIndexOf('.')) : f.name;
      store.addMusicTrack(name, f.path!);
      added++;
    }
    if (added > 0) tipSnackBar(context, '已导入 $added 首 🎵');
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final pal = store.palette;
    final tracks = store.musicTracks;
    final current = _currentIndex != null && _currentIndex! < tracks.length ? tracks[_currentIndex!] : null;

    return ModuleScaffold(
      title: '🎵 我的音乐',
      child: Column(
        children: [
          Expanded(
            child: tracks.isEmpty
                ? const EmptyState('🎧', '还没有歌曲，点下面「导入音乐」吧')
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
                    itemCount: tracks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => _TrackRow(
                      track: tracks[i],
                      active: i == _currentIndex,
                      onTap: () => _playAt(i),
                      onDelete: () {
                        final wasCurrent = i == _currentIndex;
                        store.removeMusicTrack(tracks[i]);
                        if (wasCurrent) {
                          _player.stop();
                          _currentIndex = null;
                          _playing = false;
                          _pos = Duration.zero;
                          _dur = Duration.zero;
                        }
                        setState(() {});
                      },
                    ),
                  ),
          ),

          // 播放控制区
          Container(
            decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.line))),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                // 进度条
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    activeTrackColor: pal.primary,
                    inactiveTrackColor: AppColors.line,
                    thumbColor: pal.primary,
                  ),
                  child: Slider(
                    value: _pos.inMilliseconds.toDouble().clamp(0, _dur.inMilliseconds.toDouble()),
                    max: _dur.inMilliseconds.toDouble() > 0 ? _dur.inMilliseconds.toDouble() : 1,
                    onChanged: (v) => _player.seek(Duration(milliseconds: v.round())),
                  ),
                ),
                Row(
                  children: [
                    Text(_fmt(_pos), style: const TextStyle(fontSize: 10, color: AppColors.muted)),
                    Expanded(
                      child: Text(
                        current?.title ?? '未在播放',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: current != null ? AppColors.ink : AppColors.muted),
                      ),
                    ),
                    Text(_fmt(_dur), style: const TextStyle(fontSize: 10, color: AppColors.muted)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _mode = (_mode + 1) % 3),
                      child: Column(
                        children: [
                          Text(_modeIcons[_mode], style: const TextStyle(fontSize: 18)),
                          const SizedBox(height: 2),
                          Text(_modeLabels[_mode], style: const TextStyle(fontSize: 8.5, color: AppColors.muted)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 26),
                    _CtrlBtn(icon: Icons.skip_previous_rounded, onTap: _prev),
                    const SizedBox(width: 18),
                    GestureDetector(
                      onTap: _toggle,
                      child: Container(
                        width: 56,
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(gradient: pal.gradient, shape: BoxShape.circle, boxShadow: [
                          BoxShadow(color: pal.gradEnd.withOpacity(.35), blurRadius: 12, offset: const Offset(0, 4)),
                        ]),
                        child: Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 30),
                      ),
                    ),
                    const SizedBox(width: 18),
                    _CtrlBtn(icon: Icons.skip_next_rounded, onTap: _next),
                    const SizedBox(width: 26),
                    const SizedBox(width: 36, height: 40), // 占位平衡
                  ],
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _import,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: pal.softBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: pal.softBorder)),
                    child: Text('＋ 导入手机里的音乐', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: pal.primary)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CtrlBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CtrlBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(13), border: Border.all(color: AppColors.line)),
        child: Icon(icon, size: 24, color: AppColors.sub),
      ),
    );
  }
}

class _TrackRow extends StatelessWidget {
  final MusicTrack track;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TrackRow({required this.track, required this.active, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final pal = context.watch<AppStore>().palette;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active ? pal.softBg : Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: active ? pal.softBorder : AppColors.line),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: active ? pal.gradient : null,
                color: active ? null : AppColors.bg,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(active ? Icons.graphic_eq_rounded : Icons.music_note_rounded, size: 19, color: active ? Colors.white : AppColors.muted),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: active ? pal.primary : AppColors.ink)),
                  const SizedBox(height: 2),
                  Text('本地音乐', style: const TextStyle(fontSize: 10, color: AppColors.muted)),
                ],
              ),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.close_rounded, size: 17, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
