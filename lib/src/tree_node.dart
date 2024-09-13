part of 'treeview.dart';

/// A node in a tree structure.
///
/// Each [TreeNode] represents an item in a hierarchical data structure.
/// It contains information about its state (expanded, selected, etc.),
/// its children, and its parent.
///
/// The type parameter [T] represents the type of the [value] associated
/// with this node.
class TreeNode<T> {
  /// The label widget displayed for this node.
  final Widget label;

  /// An optional value associated with this node.
  final T? value;

  /// The icon to display next to this node.
  final IconData? icon;

  /// The list of child nodes for this node.
  final List<TreeNode<T>> children;

  TreeNode<T>? _parent;
  bool _hidden = false;
  int _originalIndex = 0;
  bool _isExpanded = false;
  bool _isSelected = false;
  bool _isPartiallySelected = false;

  TreeNode._internal({
    required this.label,
    this.value,
    this.icon,
    required this.children,
    TreeNode<T>? parent,
    bool hidden = false,
    int originalIndex = 0,
    bool isExpanded = false,
    bool isSelected = false,
    bool isPartiallySelected = false,
  })  : _parent = parent,
        _hidden = hidden,
        _originalIndex = originalIndex,
        _isExpanded = isExpanded,
        _isSelected = isSelected,
        _isPartiallySelected = isPartiallySelected {
    for (var child in this.children) {
      child._parent = this;
    }
  }

  /// Creates a [TreeNode].
  ///
  /// The [label] parameter is required and specifies the widget to display for this node.
  ///
  /// The [value] parameter is an optional value associated with this node.
  ///
  /// The [icon] parameter specifies the icon to display next to the node.
  ///
  /// The [isSelected] parameter controls the initial selection state of the node.
  ///
  /// The [children] parameter is an optional list of child nodes.
  factory TreeNode({
    required Widget label,
    T? value,
    IconData? icon,
    bool isSelected = false,
    List<TreeNode<T>>? children,
  }) {
    return TreeNode._internal(
      label: label,
      value: value,
      icon: icon,
      children: children ?? [],
      isSelected: isSelected,
    );
  }
}
