import 'package:flutter/material.dart';

/// A node in a tree structure.
///
/// Each [TreeNode] represents an item in a hierarchical data structure.
/// It contains information about its state (expanded, selected, etc.),
/// its children, and its parent.
///
/// The type parameter [T] represents the type of the [value] associated
/// with this node.
class TreeNode<T> {
  /// The label text displayed for this node.
  final String label;

  /// Whether this node is currently expanded to show its children.
  bool isExpanded;

  /// Whether this node is currently selected.
  bool isSelected;

  /// Whether this node is partially selected (some children selected).
  bool isPartiallySelected;

  /// The icon to display next to this node.
  final IconData? icon;

  /// The list of child nodes for this node.
  final List<TreeNode<T>> children;

  /// The parent node of this node, or null if this is a root node.
  TreeNode<T>? parent;

  /// Whether this node is hidden in the tree view.
  bool hidden;

  /// The original index of this node in its parent's children list.
  int originalIndex;

  /// An optional value associated with this node.
  final T? value;

  /// Creates a [TreeNode].
  ///
  /// The [label] parameter is required and specifies the text to display for this node.
  ///
  /// The [isExpanded], [isSelected], [isPartiallySelected], and [hidden] parameters
  /// control the initial state of the node.
  ///
  /// The [icon] parameter specifies the icon to display next to the node.
  ///
  /// The [children] parameter is an optional list of child nodes.
  ///
  /// The [parent] parameter is the parent node of this node, if any.
  ///
  /// The [originalIndex] parameter is used to maintain the original order of nodes.
  ///
  /// The [value] parameter is an optional value associated with this node.
  TreeNode({
    required this.label,
    this.isExpanded = false,
    this.isSelected = false,
    this.isPartiallySelected = false,
    this.icon, // 移除默认值，允许传入 null
    List<TreeNode<T>>? children,
    this.parent,
    this.hidden = false,
    this.originalIndex = 0,
    this.value,
  }) : children = children ?? [] {
    for (var child in this.children) {
      child.parent = this;
    }
  }
}
