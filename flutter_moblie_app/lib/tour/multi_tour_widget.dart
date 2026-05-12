import 'package:flutter/material.dart';
import 'package:thoutha_mobile_app/tour/tour_config.dart';
import 'package:thoutha_mobile_app/tour/tour_service.dart';

class MultiTourWidget extends StatefulWidget {
  final Widget child;
  const MultiTourWidget({Key? key, required this.child}) : super(key: key);

  static MultiTourWidgetState of(BuildContext context) {
    return context.findAncestorStateOfType<MultiTourWidgetState>()!;
  }

  @override
  MultiTourWidgetState createState() => MultiTourWidgetState();
}

class MultiTourWidgetState extends State<MultiTourWidget> {
  OverlayEntry? _overlayEntry;

  void startTour(List<List<TourStep>> groups) {
    if (groups.isEmpty) return;
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => MultiTourOverlay(
        groups: groups,
        onComplete: _removeOverlay,
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class MultiTourOverlay extends StatefulWidget {
  final List<List<TourStep>> groups;
  final VoidCallback onComplete;

  const MultiTourOverlay({
    Key? key,
    required this.groups,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<MultiTourOverlay> createState() => _MultiTourOverlayState();
}

class _MultiTourOverlayState extends State<MultiTourOverlay> with TickerProviderStateMixin {
  int _currentGroupIndex = 0;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _next() async {
    for (var step in widget.groups[_currentGroupIndex]) {
      await TourService.markSeen(step.id);
    }

    if (_currentGroupIndex < widget.groups.length - 1) {
      setState(() {
        _currentGroupIndex++;
      });
      _animController.forward(from: 0.0);
    } else {
      widget.onComplete();
    }
  }

  void _skip() async {
    await TourService.skipAll();
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final currentGroup = widget.groups[_currentGroupIndex];
    
    List<Rect> holes = [];
    List<Widget> tooltips = [];

    for (int i = 0; i < currentGroup.length; i++) {
      final step = currentGroup[i];
      final renderBox = step.key.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final position = renderBox.localToGlobal(Offset.zero);
        final size = renderBox.size;
        final rect = position & size;
        holes.add(rect);

        // Animation logic based on order:
        // 0 -> from top (-1, 0)
        // 1 -> from bottom (1, 0)
        // 2 -> from middle/right (0, 1)
        Offset slideOffset;
        if (i % 3 == 0) slideOffset = const Offset(0, -1);
        else if (i % 3 == 1) slideOffset = const Offset(0, 1);
        else slideOffset = const Offset(1, 0);

        // Smart positioning to prevent overflow
        double top = rect.bottom + 15;
        double left = rect.left;
        if (top > MediaQuery.of(context).size.height - 150) {
          top = rect.top - 150; // place above if at the bottom
        }
        
        // Prevent going off-screen to the right
        if (left > MediaQuery.of(context).size.width - 280) {
          left = MediaQuery.of(context).size.width - 290;
        }

        tooltips.add(
          Positioned(
            top: top,
            left: left,
            child: SlideTransition(
              position: Tween<Offset>(begin: slideOffset, end: Offset.zero).animate(
                CurvedAnimation(parent: _animController, curve: Curves.easeOutBack)
              ),
              child: FadeTransition(
                opacity: _animController,
                child: _buildTooltip(step),
              ),
            ),
          )
        );
      }
    }

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Dark background with highlighted holes
          CustomPaint(
            size: Size.infinite,
            painter: MultiHolePainter(holes),
          ),
          
          // Tour Tooltips
          ...tooltips,
          
          // Global Controls (Skip / Next)
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
                CurvedAnimation(parent: _animController, curve: Curves.easeOutBack)
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? const Color(0xFF1E293B).withOpacity(0.9)
                      : Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10))
                  ]
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: _skip,
                      child: Text('تخطي الجولة', style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54, 
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Cairo'
                      )),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8DECB4),
                        foregroundColor: const Color(0xFF064E3B),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _next,
                      child: Text(
                        _currentGroupIndex == widget.groups.length - 1 ? 'إنهاء' : 'التالي',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTooltip(TourStep step) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 270,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8DECB4).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 8))
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF8DECB4).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.tips_and_updates_rounded, color: Color(0xFF8DECB4), size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  step.title, 
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 15, 
                    fontFamily: 'Cairo',
                    color: isDark ? Colors.white : Colors.black87
                  )
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            step.description, 
            style: TextStyle(
              fontSize: 13, 
              fontFamily: 'Cairo', 
              color: isDark ? Colors.white70 : Colors.black54,
              height: 1.5
            )
          ),
        ],
      ),
    );
  }
}

class MultiHolePainter extends CustomPainter {
  final List<Rect> holes;

  MultiHolePainter(this.holes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.75)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    for (final hole in holes) {
      path.addRRect(RRect.fromRectAndRadius(hole.inflate(6), const Radius.circular(12)));
    }
    
    path.fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(MultiHolePainter oldDelegate) => true;
}
