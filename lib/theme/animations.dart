import 'package:flutter/material.dart';

/// Lensify OCR Scanner için animasyon yardımcı sınıfları
class AppAnimations {
  // Animasyon süreleri
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration extraSlow = Duration(milliseconds: 800);

  // Animasyon eğrileri
  static const Curve bounceIn = Curves.elasticOut;
  static const Curve slideIn = Curves.easeOutCubic;
  static const Curve fadeIn = Curves.easeInOutQuart;
  static const Curve scaleIn = Curves.easeOutBack;

  /// Sayfa geçiş animasyonu
  static PageRouteBuilder<T> slidePageRoute<T>({
    required Widget page,
    SlideDirection direction = SlideDirection.left,
    Duration duration = medium,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        Offset begin;
        switch (direction) {
          case SlideDirection.left:
            begin = const Offset(1.0, 0.0);
            break;
          case SlideDirection.right:
            begin = const Offset(-1.0, 0.0);
            break;
          case SlideDirection.up:
            begin = const Offset(0.0, 1.0);
            break;
          case SlideDirection.down:
            begin = const Offset(0.0, -1.0);
            break;
        }
        
        const end = Offset.zero;
        
        final tween = Tween(begin: begin, end: end);
        final offsetAnimation = animation.drive(tween.chain(
          CurveTween(curve: slideIn),
        ));
        
        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }

  /// Fade geçiş animasyonu
  static PageRouteBuilder<T> fadePageRoute<T>({
    required Widget page,
    Duration duration = medium,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation.drive(
            Tween<double>(begin: 0.0, end: 1.0).chain(
              CurveTween(curve: fadeIn),
            ),
          ),
          child: child,
        );
      },
    );
  }

  /// Scale geçiş animasyonu
  static PageRouteBuilder<T> scalePageRoute<T>({
    required Widget page,
    Duration duration = medium,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: animation.drive(
            Tween<double>(begin: 0.0, end: 1.0).chain(
              CurveTween(curve: scaleIn),
            ),
          ),
          child: child,
        );
      },
    );
  }

  /// Combinedi geçiş animasyonu (fade + scale)
  static PageRouteBuilder<T> combinedPageRoute<T>({
    required Widget page,
    Duration duration = medium,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation.drive(
            Tween<double>(begin: 0.0, end: 1.0).chain(
              CurveTween(curve: fadeIn),
            ),
          ),
          child: ScaleTransition(
            scale: animation.drive(
              Tween<double>(begin: 0.8, end: 1.0).chain(
                CurveTween(curve: scaleIn),
              ),
            ),
            child: child,
          ),
        );
      },
    );
  }
}

/// Sayfa geçiş yönleri
enum SlideDirection {
  left,
  right,
  up,
  down,
}

/// Animasyonlu Container widget
class AnimatedWrapper extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final bool animate;

  const AnimatedWrapper({
    super.key,
    required this.child,
    this.duration = AppAnimations.medium,
    this.curve = AppAnimations.fadeIn,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!animate) return child;

    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: curve,
      switchOutCurve: curve,
      child: child,
    );
  }
}

/// Hover animasyonu widget
class AnimatedHoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Duration duration;
  final double hoverScale;
  final double hoverElevation;

  const AnimatedHoverCard({
    super.key,
    required this.child,
    this.onTap,
    this.duration = AppAnimations.fast,
    this.hoverScale = 1.02,
    this.hoverElevation = 8.0,
  });

  @override
  State<AnimatedHoverCard> createState() => _AnimatedHoverCardState();
}

class _AnimatedHoverCardState extends State<AnimatedHoverCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.hoverScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.scaleIn,
    ));
    
    _elevationAnimation = Tween<double>(
      begin: 0.0,
      end: widget.hoverElevation,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.fadeIn,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: _elevationAnimation.value,
                    offset: Offset(0, _elevationAnimation.value / 2),
                  ),
                ],
              ),
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}

/// Loading animasyonu widget
class LoadingAnimation extends StatefulWidget {
  final double size;
  final Color? color;
  final LoadingType type;

  const LoadingAnimation({
    super.key,
    this.size = 40,
    this.color,
    this.type = LoadingType.pulse,
  });

  @override
  State<LoadingAnimation> createState() => _LoadingAnimationState();
}

class _LoadingAnimationState extends State<LoadingAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.type == LoadingType.pulse 
          ? AppAnimations.slow 
          : AppAnimations.medium,
      vsync: this,
    );
    
    switch (widget.type) {
      case LoadingType.pulse:
        _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        );
        _controller.repeat(reverse: true);
        break;
      case LoadingType.rotate:
        _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.linear),
        );
        _controller.repeat();
        break;
      case LoadingType.bounce:
        _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.bounceInOut),
        );
        _controller.repeat(reverse: true);
        break;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        switch (widget.type) {
          case LoadingType.pulse:
            return Transform.scale(
              scale: _animation.value,
              child: _buildLoadingIcon(),
            );
          case LoadingType.rotate:
            return Transform.rotate(
              angle: _animation.value * 6.28, // 2π
              child: _buildLoadingIcon(),
            );
          case LoadingType.bounce:
            return Transform.translate(
              offset: Offset(0, -10 * _animation.value),
              child: _buildLoadingIcon(),
            );
        }
      },
    );
  }

  Widget _buildLoadingIcon() {
    return Icon(
      Icons.refresh,
      size: widget.size,
      color: widget.color ?? Theme.of(context).primaryColor,
    );
  }
}

/// Loading animasyon tipleri
enum LoadingType {
  pulse,
  rotate,
  bounce,
}

/// Shimmer loading effect
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerLoading({
    super.key,
    required this.child,
    required this.isLoading,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _animation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    if (widget.isLoading) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(ShimmerLoading oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }

    final baseColor = widget.baseColor ?? 
        Theme.of(context).colorScheme.surface.withValues(alpha: 0.3);
    final highlightColor = widget.highlightColor ?? 
        Theme.of(context).colorScheme.surface.withValues(alpha: 0.1);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
              transform: _SlidingGradientTransform(_animation.value),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Gradient sliding transform for shimmer effect
class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlidingGradientTransform(this.slidePercent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}

/// Fade in animasyonu widget
class FadeInAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;

  const FadeInAnimation({
    super.key,
    required this.child,
    this.duration = AppAnimations.medium,
    this.delay = Duration.zero,
    this.curve = AppAnimations.fadeIn,
  });

  @override
  State<FadeInAnimation> createState() => _FadeInAnimationState();
}

class _FadeInAnimationState extends State<FadeInAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );
    
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}

/// Slide in animasyonu widget
class SlideInAnimation extends StatefulWidget {
  final Widget child;
  final SlideDirection direction;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final double distance;

  const SlideInAnimation({
    super.key,
    required this.child,
    this.direction = SlideDirection.left,
    this.duration = AppAnimations.medium,
    this.delay = Duration.zero,
    this.curve = AppAnimations.slideIn,
    this.distance = 100.0,
  });

  @override
  State<SlideInAnimation> createState() => _SlideInAnimationState();
}

class _SlideInAnimationState extends State<SlideInAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    Offset begin;
    switch (widget.direction) {
      case SlideDirection.left:
        begin = Offset(widget.distance, 0);
        break;
      case SlideDirection.right:
        begin = Offset(-widget.distance, 0);
        break;
      case SlideDirection.up:
        begin = Offset(0, widget.distance);
        break;
      case SlideDirection.down:
        begin = Offset(0, -widget.distance);
        break;
    }
    
    _animation = Tween<Offset>(begin: begin, end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );
    
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: _animation.value,
          child: widget.child,
        );
      },
    );
  }
} 