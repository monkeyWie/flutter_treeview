import 'package:flutter/material.dart';

import 'tree_node.dart';
import 'treeview_state.dart';

/// A customizable tree view widget that displays hierarchical data.
///
/// This widget creates a tree structure from a list of [TreeNode]s and allows
/// for selection, expansion, and collapsing of nodes. It also supports filtering
/// and sorting of nodes.
///
/// The [onSelectionChanged] callback is called whenever the selection state
/// of any node changes.
///
/// Example:
///
/// ```dart
/// TreeView<String>(
///   nodes: [
///     TreeNode(
///       label: 'Root',
///       children: [
///         TreeNode(label: 'Child 1'),
///         TreeNode(label: 'Child 2'),
///       ],
///     ),
///   ],
///   onSelectionChanged: (selectedValues) {
///     print('Selected values: $selectedValues');
///   },
/// )
/// ```
///
/// Method Examples:
///
/// ```dart
/// treeViewKey.currentState?.filter((node) => node.label.contains('Search'));
/// treeViewKey.currentState?.sort((a, b) => a.label.compareTo(b.label));
/// treeViewKey.currentState?.selectAll(true);
/// treeViewKey.currentState?.getSelectedValues();
/// treeViewKey.currentState?.getSelectedNodes();
/// ```
class TreeView<T> extends StatefulWidget {
  /// The root nodes of the tree.
  final List<TreeNode<T>> nodes;

  /// Callback function called when the selection state changes.
  final Function(List<T?>) onSelectionChanged;

  /// Optional theme data for the tree view.
  final ThemeData? theme;

  /// Whether to show a "Select All" checkbox.
  final bool showSelectAll;

  /// The number of levels to initially expand. If null, no nodes are expanded.
  final int? initialExpandedLevels;

  /// Custom widget to replace the default "Select All" checkbox.
  final Widget? selectAllWidget;

  /// Whether to show the expand/collapse all button.
  final bool showExpandCollapseButton;

  /// Creates a [TreeView] widget.
  ///
  /// The [nodes] and [onSelectionChanged] parameters are required.
  ///
  /// The [theme] parameter can be used to customize the appearance of the tree view.
  ///
  /// Set [showSelectAll] to true to display a "Select All" checkbox.
  ///
  /// The [selectAllWidget] can be used to provide a custom widget for the "Select All" functionality.
  ///
  /// Use [initialExpandedLevels] to control how many levels of the tree are initially expanded, default is null, no nodes are expanded.
  /// if set to 0, all nodes are expanded, if set to 1, only the root nodes are expanded, if set to 2, the root nodes and their direct children are expanded, and so on.
  ///
  /// Set [showExpandCollapseButton] to true to display a button that expands or collapses all nodes.
  const TreeView({
    super.key,
    required this.nodes,
    required this.onSelectionChanged,
    this.theme,
    this.showSelectAll = false,
    this.selectAllWidget,
    this.initialExpandedLevels,
    this.showExpandCollapseButton = false,
  });

  @override
  TreeViewState<T> createState() => TreeViewState<T>();
}
