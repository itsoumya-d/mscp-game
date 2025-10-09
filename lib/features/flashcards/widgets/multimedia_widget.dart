import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/flashcard.dart';
import '../../../core/services/multimedia_service.dart';

/// Widget for displaying multimedia content in flashcards
class MultimediaWidget extends StatefulWidget {
  final List<MultimediaContent> content;
  final double maxHeight;
  final bool showControls;
  final VoidCallback? onInteraction;

  const MultimediaWidget({
    Key? key,
    required this.content,
    this.maxHeight = 200,
    this.showControls = true,
    this.onInteraction,
  }) : super(key: key);

  @override
  State<MultimediaWidget> createState() => _MultimediaWidgetState();
}

class _MultimediaWidgetState extends State<MultimediaWidget>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  int _currentIndex = 0;
  bool _isLoading = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.content.isEmpty) {
      return const SizedBox.shrink();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        height: widget.maxHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[50],
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              _buildContentView(),
              if (widget.content.length > 1) _buildNavigationDots(),
              if (widget.showControls) _buildControlsOverlay(),
              if (_isLoading) _buildLoadingOverlay(),
              if (_hasError) _buildErrorOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentView() {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() => _currentIndex = index);
        widget.onInteraction?.call();
      },
      itemCount: widget.content.length,
      itemBuilder: (context, index) {
        final content = widget.content[index];
        return _buildContentItem(content);
      },
    );
  }

  Widget _buildContentItem(MultimediaContent content) {
    switch (content.type) {
      case MultimediaType.image:
        return _buildImageContent(content);
      case MultimediaType.animation:
        return _buildAnimationContent(content);
      case MultimediaType.audio:
        return _buildAudioContent(content);
      case MultimediaType.code:
        return _buildCodeContent(content);
      case MultimediaType.video:
        return _buildVideoContent(content);
      default:
        return _buildPlaceholderContent(content);
    }
  }

  Widget _buildImageContent(MultimediaContent content) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // SVG or regular image
          if (content.url.endsWith('.svg'))
            _buildSVGImage(content)
          else
            _buildRegularImage(content),
          
          // Interactive overlay for diagrams
          if (content.metadata['interactive'] == true)
            _buildInteractiveOverlay(content),
        ],
      ),
    );
  }

  Widget _buildSVGImage(MultimediaContent content) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              content.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Text(
                'SVG Diagram',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegularImage(MultimediaContent content) {
    return Image.asset(
      content.url,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return _buildImagePlaceholder(content);
      },
    );
  }

  Widget _buildImagePlaceholder(MultimediaContent content) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            content.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnimationContent(MultimediaContent content) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animation placeholder with play button
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.purple[50],
              shape: BoxShape.circle,
              border: Border.all(color: Colors.purple[200]!),
            ),
            child: Icon(
              Icons.play_circle_filled,
              size: 40,
              color: Colors.purple[600],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            content.description,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.purple[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.purple[200]!),
            ),
            child: Text(
              'Interactive Animation',
              style: TextStyle(
                fontSize: 12,
                color: Colors.purple[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _playAnimation(content),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Play Animation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioContent(MultimediaContent content) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Audio visualization
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.orange[50],
              shape: BoxShape.circle,
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Sound waves animation
                ...List.generate(3, (index) => 
                  Container(
                    width: 60 + (index * 15),
                    height: 60 + (index * 15),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.orange[300]!.withOpacity(0.3 - (index * 0.1)),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                Icon(
                  Icons.volume_up,
                  size: 32,
                  color: Colors.orange[600],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            content.description,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            content.metadata['duration'] ?? '2-3 minutes',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => _playAudio(content),
                icon: const Icon(Icons.play_arrow),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.orange[600],
                  foregroundColor: Colors.white,
                  shape: const CircleBorder(),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: () => _pauseAudio(content),
                icon: const Icon(Icons.pause),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  foregroundColor: Colors.grey[700],
                  shape: const CircleBorder(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCodeContent(MultimediaContent content) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Code header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.code,
                      size: 16,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Code Example',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[300],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _copyCode(content),
                icon: const Icon(Icons.copy, size: 16),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  foregroundColor: Colors.grey[600],
                  minimumSize: const Size(32, 32),
                ),
              ),
            ],
          ),
          // Code content
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _getCodeExample(content),
                  style: const TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 12,
                    color: Colors.green,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoContent(MultimediaContent content) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Icon(
              Icons.play_circle_filled,
              size: 48,
              color: Colors.red[600],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            content.description,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _playVideo(content),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Play Video'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderContent(MultimediaContent content) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.help_outline,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            content.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveOverlay(MultimediaContent content) {
    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleInteraction(content),
          child: Container(
            alignment: Alignment.bottomRight,
            padding: const EdgeInsets.all(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.touch_app,
                    size: 16,
                    color: Colors.white,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Interactive',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationDots() {
    return Positioned(
      bottom: 8,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          widget.content.length,
          (index) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index == _currentIndex
                  ? Colors.blue[600]
                  : Colors.grey[300],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlsOverlay() {
    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: _toggleFullscreen,
              icon: const Icon(Icons.fullscreen, color: Colors.white),
              iconSize: 20,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black26,
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  Widget _buildErrorOverlay() {
    return Container(
      color: Colors.black26,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 48,
            ),
            const SizedBox(height: 8),
            const Text(
              'Failed to load content',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _retryLoad,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _playAnimation(MultimediaContent content) {
    // Implement animation playback
    HapticFeedback.lightImpact();
    widget.onInteraction?.call();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Playing: ${content.description}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _playAudio(MultimediaContent content) {
    // Implement audio playback
    HapticFeedback.lightImpact();
    widget.onInteraction?.call();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Playing audio: ${content.description}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _pauseAudio(MultimediaContent content) {
    // Implement audio pause
    HapticFeedback.lightImpact();
  }

  void _playVideo(MultimediaContent content) {
    // Implement video playback
    HapticFeedback.lightImpact();
    widget.onInteraction?.call();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Playing video: ${content.description}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _copyCode(MultimediaContent content) {
    final code = _getCodeExample(content);
    Clipboard.setData(ClipboardData(text: code));
    HapticFeedback.lightImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Code copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleInteraction(MultimediaContent content) {
    HapticFeedback.lightImpact();
    widget.onInteraction?.call();
    
    // Show interaction dialog or navigate to detailed view
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Interactive Content'),
        content: Text(content.description),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to detailed interactive view
            },
            child: const Text('Explore'),
          ),
        ],
      ),
    );
  }

  void _toggleFullscreen() {
    // Implement fullscreen toggle
    HapticFeedback.lightImpact();
  }

  void _retryLoad() {
    setState(() {
      _hasError = false;
      _isLoading = true;
    });
    
    // Simulate retry
    Future.delayed(const Duration(seconds: 1), () {
      setState(() => _isLoading = false);
    });
  }

  String _getCodeExample(MultimediaContent content) {
    // Return sample code based on content
    return '''
// Example: ${content.description}
function example() {
  console.log("Interactive code example");
  return "Learning in progress...";
}

example();
''';
  }
}