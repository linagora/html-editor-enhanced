class SignaturePosition {
  final double top;
  final double left;
  final double width;
  final double height;

  const SignaturePosition({
    required this.top,
    required this.left,
    required this.width,
    required this.height,
  });

  factory SignaturePosition.fromJson(Map<String, dynamic> json) {
    return SignaturePosition(
      top: (json['top'] as num).toDouble(),
      left: (json['left'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
    );
  }
}
