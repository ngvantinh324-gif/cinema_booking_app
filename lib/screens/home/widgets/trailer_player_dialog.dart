// Người phụ trách: Triết - xem trailer YouTube ngay trong app
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../../models/movie.dart';
import '../../../theme/app_theme.dart';

/// Mở trailer bằng app YouTube (hoặc trình duyệt). Trả về false nếu không mở được.
Future<bool> openTrailerExternally(String url) async {
  try {
    return await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

/// Hộp thoại phát trailer trong app. Xoay ngang điện thoại để xem toàn màn hình.
Future<void> showTrailerPlayer(BuildContext context, Movie movie) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    builder: (_) => TrailerPlayerDialog(movie: movie),
  );
}

class TrailerPlayerDialog extends StatefulWidget {
  const TrailerPlayerDialog({super.key, required this.movie});

  final Movie movie;

  @override
  State<TrailerPlayerDialog> createState() => _TrailerPlayerDialogState();
}

class _TrailerPlayerDialogState extends State<TrailerPlayerDialog> {
  late final YoutubePlayerController _controller =
      YoutubePlayerController.fromVideoId(
    videoId: widget.movie.youtubeKey!,
    autoPlay: true,
    params: const YoutubePlayerParams(
      showFullscreenButton: true,
      strictRelatedVideos: true,
      interfaceLanguage: 'vi',
      captionLanguage: 'vi',
    ),
  );
  late final StreamSubscription<YoutubePlayerValue> _subscription;
  bool _cannotEmbed = false;

  @override
  void initState() {
    super.initState();
    // Một số video bị chủ sở hữu chặn phát nhúng -> đề nghị mở bằng YouTube
    _subscription = _controller.listen((value) {
      if (value.hasError && !_cannotEmbed && mounted) {
        setState(() => _cannotEmbed = true);
      }
    });
    // Thư viện chỉ phủ video lên toàn màn hình, không tự xoay -> app tự xoay ngang
    _controller.setFullScreenListener(_onFullScreenChanged);
    // Mặc định bấm logo/tiêu đề YouTube trong khung video sẽ tải lại video.
    // Thay bằng: chặn mọi điều hướng trong khung, link YouTube thì mở app YouTube.
    _controller.webViewController.setNavigationDelegate(
      NavigationDelegate(onNavigationRequest: _onNavigationRequest),
    );
  }

  NavigationDecision _onNavigationRequest(NavigationRequest request) {
    final host = Uri.tryParse(request.url)?.host ?? '';
    if (host.contains('youtube.com') || host.contains('youtu.be')) {
      _controller.pauseVideo();
      _openInYoutube();
    }
    return NavigationDecision.prevent;
  }

  void _onFullScreenChanged(bool fullScreen) {
    if (fullScreen) {
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  @override
  void dispose() {
    // Đóng trailer: trả lại hướng màn hình và thanh trạng thái như bình thường
    SystemChrome.setPreferredOrientations(const []);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _subscription.cancel();
    _controller.close();
    super.dispose();
  }

  Future<void> _openInYoutube() async {
    final url = widget.movie.trailerUrl;
    if (url == null) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final opened = await openTrailerExternally(url);
    if (opened) {
      navigator.pop();
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('Không mở được YouTube, thử lại sau')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 4, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Trailer · ${widget.movie.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  tooltip: 'Đóng',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _cannotEmbed
                ? _CannotEmbed(onOpen: _openInYoutube)
                : YoutubePlayer(
                    controller: _controller,
                    backgroundColor: Colors.black,
                    // Giao hết thao tác chạm/vuốt cho video để kéo được thanh tua
                    gestureRecognizers: {
                      Factory<OneSequenceGestureRecognizer>(
                        EagerGestureRecognizer.new,
                      ),
                    },
                    // Đã có nút phóng to; tắt vuốt dọc để không giành cử chỉ kéo
                    enableFullScreenOnVerticalDrag: false,
                  ),
          ),
          if (widget.movie.trailerUrl != null)
            _TrailerLink(url: widget.movie.trailerUrl!, onOpen: _openInYoutube),
        ],
      ),
    );
  }
}

/// Dòng link trailer: bấm để mở YouTube, nút bên phải để sao chép link
class _TrailerLink extends StatefulWidget {
  const _TrailerLink({required this.url, required this.onOpen});

  final String url;
  final VoidCallback onOpen;

  @override
  State<_TrailerLink> createState() => _TrailerLinkState();
}

class _TrailerLinkState extends State<_TrailerLink> {
  bool _copied = false;
  Timer? _resetTimer;

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.url));
    if (!mounted) return;
    setState(() => _copied = true);
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
      child: Row(
        children: [
          const Icon(Icons.link_rounded, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: widget.onOpen,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  widget.url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: _copied ? 'Đã sao chép' : 'Sao chép link',
            onPressed: _copy,
            icon: Icon(
              _copied ? Icons.check_rounded : Icons.copy_rounded,
              size: 18,
              color: _copied ? AppColors.success : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CannotEmbed extends StatelessWidget {
  const _CannotEmbed({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.block_rounded, color: Colors.white54, size: 36),
              const SizedBox(height: 8),
              const Text(
                'Video này không cho phát trong ứng dụng',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Xem trên YouTube'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
