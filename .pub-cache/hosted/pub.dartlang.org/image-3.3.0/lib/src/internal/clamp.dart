/// Clamp [x] to [a] [b]
int clamp(int x, int a, int b) => x.clamp(a, b).toInt();

/// Clamp [x] to [0, 255]
int clamp255(int x) => x.clamp(0, 255).toInt();
