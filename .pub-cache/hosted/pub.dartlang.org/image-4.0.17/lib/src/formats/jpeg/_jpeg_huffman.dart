class HuffmanNode {
  const HuffmanNode();
}

class HuffmanParent extends HuffmanNode {
  final List<HuffmanNode?> children;
  const HuffmanParent(this.children);
}

class HuffmanValue extends HuffmanNode {
  final int value;
  const HuffmanValue(this.value);
}
