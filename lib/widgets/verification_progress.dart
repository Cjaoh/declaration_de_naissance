import 'package:flutter/material.dart';

class VerificationProgress extends StatefulWidget {
  final String title;
  final String message;
  final bool isComplete;
  final bool isError;
  final VoidCallback? onRetry;

  const VerificationProgress({
    super.key,
    required this.title,
    required this.message,
    this.isComplete = false,
    this.isError = false,
    this.onRetry,
  });

  @override
  State<VerificationProgress> createState() => _VerificationProgressState();
}

class _VerificationProgressState extends State<VerificationProgress>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.linear),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.isError
                    ? [Colors.red.shade400, Colors.red.shade600]
                    : widget.isComplete
                        ? [const Color(0xFF4CAF9E), const Color(0xFF26A69A)]
                        : [Colors.blue.shade400, Colors.blue.shade600],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon avec animation
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: widget.isComplete
                      ? const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 48,
                        )
                      : widget.isError
                          ? const Icon(
                              Icons.error,
                              color: Colors.white,
                              size: 48,
                            )
                          : Transform.rotate(
                              angle: _rotationAnimation.value * 2 * 3.14159,
                              child: const Icon(
                                Icons.hourglass_empty,
                                color: Colors.white,
                                size: 48,
                              ),
                            ),
                ),
                const SizedBox(height: 20),
                
                // Titre
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                
                // Message
                Text(
                  widget.message,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                // Bouton de retry si erreur
                if (widget.isError && widget.onRetry != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextButton(
                      onPressed: widget.onRetry,
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Réessayer',
                        style: TextStyle(
                          color: Color(0xFF4CAF9E),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class VerificationSteps extends StatelessWidget {
  final List<VerificationStep> steps;
  final int currentStep;

  const VerificationSteps({
    super.key,
    required this.steps,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isCompleted = index < currentStep;
        final isCurrent = index == currentStep;
        // final isPending = index > currentStep; // Not used yet

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              // Indicateur de progression
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFF4CAF9E)
                      : isCurrent
                          ? Colors.blue.shade400
                          : Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCompleted
                      ? Icons.check
                      : isCurrent
                          ? Icons.hourglass_empty
                          : Icons.circle_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              
              // Contenu de l'étape
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isCompleted
                            ? const Color(0xFF4CAF9E)
                            : isCurrent
                                ? Colors.blue.shade600
                                : Colors.grey.shade600,
                      ),
                    ),
                    if (step.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        step.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class VerificationStep {
  final String title;
  final String? description;

  const VerificationStep({
    required this.title,
    this.description,
  });
} 