import 'package:flutter/material.dart';

import 'tree_node.dart';
import 'treeview.dart';

/// The state for the [TreeView] widget.
///
/// This class manages the state of the tree view, including node selection,
/// expansion, filtering, and sorting.
class TreeViewState<T> extends State<TreeView<T>> {
  late List<TreeNode<T>> _roots;
  bool _isAllSelected = false;
  late bool _isAllExpanded;

  @override
  void initState() {
    super.initState();
    _roots = widget.nodes;
    _initializeNodes(_roots, null);
    _setInitialExpansion(_roots, 0);
    _updateAllNodesSelectionState();
    _updateSelectAllState();
    _isAllExpanded = widget.initialExpandedLevels == 0;
  }

  /// Filters the tree nodes based on the provided filter function.
  ///
  /// The [filterFunction] should return true for nodes that should be visible.
  void filter(bool Function(TreeNode<T>) filterFunction) {
    setState(() {
      _applyFilter(_roots, filterFunction);
      _updateAllNodesSelectionState();
      _updateSelectAllState();
    });
  }

  /// Sorts the tree nodes based on the provided compare function.
  ///
  /// If [compareFunction] is null, the original order is restored.
  void sort(int Function(TreeNode<T>, TreeNode<T>)? compareFunction) {
    setState(() {
      if (compareFunction == null) {
        _applySort(
            _roots, (a, b) => a.originalIndex.compareTo(b.originalIndex));
      } else {
        _applySort(_roots, compareFunction);
      }
    });
  }

  /// Sets the selection state of all nodes.
  void setSelectAll(bool isSelected) {
    setState(() {
      _setAllNodesSelection(isSelected);
      _updateSelectAllState();
    });
    _notifySelectionChanged();
  }

  /// Expands all nodes in the tree.
  void expandAll() {
    setState(() {
      _setExpansionState(_roots, true);
    });
  }

  /// Collapses all nodes in the tree.
  void collapseAll() {
    setState(() {
      _setExpansionState(_roots, false);
    });
  }

  /// Returns a list of all selected nodes in the tree.
  List<TreeNode<T>> getSelectedNodes() {
    return _getSelectedNodesRecursive(_roots);
  }

  /// Returns a list of all selected values in the tree.
  List<T?> getSelectedValues() {
    return _getSelectedValues(_roots);
  }

  void _initializeNodes(List<TreeNode<T>> nodes, TreeNode<T>? parent) {
    for (int i = 0; i < nodes.length; i++) {
      nodes[i].originalIndex = i;
      nodes[i].parent = parent;
      _initializeNodes(nodes[i].children, nodes[i]);
    }
  }

  void _setInitialExpansion(List<TreeNode<T>> nodes, int currentLevel) {
    if (widget.initialExpandedLevels == null) {
      return;
    }
    for (var node in nodes) {
      if (widget.initialExpandedLevels == 0) {
        node.isExpanded = true;
      } else {
        node.isExpanded = currentLevel < widget.initialExpandedLevels!;
      }
      if (node.isExpanded) {
        _setInitialExpansion(node.children, currentLevel + 1);
      }
    }
  }

  void _applySort(List<TreeNode<T>> nodes,
      int Function(TreeNode<T>, TreeNode<T>) compareFunction) {
    nodes.sort(compareFunction);
    for (var node in nodes) {
      if (node.children.isNotEmpty) {
        _applySort(node.children, compareFunction);
      }
    }
  }

  void _applyFilter(
      List<TreeNode<T>> nodes, bool Function(TreeNode<T>) filterFunction) {
    for (var node in nodes) {
      bool shouldShow =
          filterFunction(node) || _hasVisibleDescendant(node, filterFunction);
      node.hidden = !shouldShow;
      _applyFilter(node.children, filterFunction);
    }
  }

  void _updateAllNodesSelectionState() {
    for (var root in _roots) {
      _updateNodeSelectionStateBottomUp(root);
    }
  }

  void _updateNodeSelectionStateBottomUp(TreeNode<T> node) {
    for (var child in node.children) {
      _updateNodeSelectionStateBottomUp(child);
    }
    _updateSingleNodeSelectionState(node);
  }

  void _updateNodeSelection(TreeNode<T> node, bool? isSelected) {
    setState(() {
      if (isSelected == null) {
        _handlePartialSelection(node);
      } else {
        _updateNodeAndDescendants(node, isSelected);
      }
      _updateAncestorsRecursively(node);
      _updateSelectAllState();
    });
    _notifySelectionChanged();
  }

  void _handlePartialSelection(TreeNode<T> node) {
    if (node.isSelected || node.isPartiallySelected) {
      _updateNodeAndDescendants(node, false);
    } else {
      _updateNodeAndDescendants(node, true);
    }
  }

  void _updateNodeAndDescendants(TreeNode<T> node, bool isSelected) {
    if (!node.hidden) {
      node.isSelected = isSelected;
      node.isPartiallySelected = false;
      for (var child in node.children) {
        _updateNodeAndDescendants(child, isSelected);
      }
    }
  }

  void _updateAncestorsRecursively(TreeNode<T> node) {
    TreeNode<T>? parent = node.parent;
    if (parent != null) {
      _updateSingleNodeSelectionState(parent);
      _updateAncestorsRecursively(parent);
    }
  }

  void _notifySelectionChanged() {
    List<T?> selectedValues = _getSelectedValues(_roots);
    widget.onSelectionChanged(selectedValues);
  }

  List<T?> _getSelectedValues(List<TreeNode<T>> nodes) {
    List<T?> selectedValues = [];
    for (var node in nodes) {
      if (node.isSelected && !node.hidden) {
        selectedValues.add(node.value);
      }
      selectedValues.addAll(_getSelectedValues(node.children));
    }
    return selectedValues;
  }

  Widget _buildTreeNode(TreeNode<T> node, {double leftPadding = 0}) {
    if (node.hidden) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsets.only(left: leftPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: InkWell(
              onTap: () => _updateNodeSelection(node, !node.isSelected),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: node.children.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              node.isExpanded
                                  ? Icons.expand_more
                                  : Icons.chevron_right,
                            ),
                            onPressed: () => _toggleNodeExpansion(node),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          )
                        : null,
                  ),
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: node.isSelected
                          ? true
                          : (node.isPartiallySelected ? null : false),
                      tristate: true,
                      onChanged: (bool? value) =>
                          _updateNodeSelection(node, value ?? false),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  Icon(node.icon),
                  const SizedBox(width: 4),
                  Expanded(child: Text(node.label)),
                ],
              ),
            ),
          ),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            tween: Tween<double>(
              begin: node.isExpanded ? 0 : 1,
              end: node.isExpanded ? 1 : 0,
            ),
            builder: (context, value, child) {
              return ClipRect(
                child: Align(
                  heightFactor: value,
                  child: child,
                ),
              );
            },
            child: node.children.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: node.children
                          .map((child) => _buildTreeNode(child))
                          .toList(),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  void _toggleNodeExpansion(TreeNode<T> node) {
    setState(() {
      node.isExpanded = !node.isExpanded;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  bool _hasVisibleDescendant(
      TreeNode<T> node, bool Function(TreeNode<T>) filterFunction) {
    for (var child in node.children) {
      if (filterFunction(child) ||
          _hasVisibleDescendant(child, filterFunction)) {
        return true;
      }
    }
    return false;
  }

  void _updateSingleNodeSelectionState(TreeNode<T> node) {
    if (node.children.isEmpty || node.children.every((child) => child.hidden)) {
      return;
    }

    List<TreeNode<T>> visibleChildren =
        node.children.where((child) => !child.hidden).toList();
    bool allSelected = visibleChildren.every((child) => child.isSelected);
    bool anySelected = visibleChildren
        .any((child) => child.isSelected || child.isPartiallySelected);

    if (allSelected) {
      node.isSelected = true;
      node.isPartiallySelected = false;
    } else if (anySelected) {
      node.isSelected = false;
      node.isPartiallySelected = true;
    } else {
      node.isSelected = false;
      node.isPartiallySelected = false;
    }
  }

  void _setExpansionState(List<TreeNode<T>> nodes, bool isExpanded) {
    for (var node in nodes) {
      node.isExpanded = isExpanded;
      _setExpansionState(node.children, isExpanded);
    }
  }

  void _updateSelectAllState() {
    if (!widget.showSelectAll) return;
    bool allSelected = _roots
        .where((node) => !node.hidden)
        .every((node) => _isNodeFullySelected(node));
    setState(() {
      _isAllSelected = allSelected;
    });
  }

  bool _isNodeFullySelected(TreeNode<T> node) {
    if (node.hidden) return true;
    if (!node.isSelected) return false;
    return node.children
        .where((child) => !child.hidden)
        .every(_isNodeFullySelected);
  }

  void _handleSelectAll(bool? value) {
    if (value == null) return;
    _setAllNodesSelection(value);
    _updateSelectAllState();
    _notifySelectionChanged();
  }

  void _setAllNodesSelection(bool isSelected) {
    for (var root in _roots) {
      _setNodeAndDescendantsSelection(root, isSelected);
    }
  }

  void _setNodeAndDescendantsSelection(TreeNode<T> node, bool isSelected) {
    if (node.hidden) return;
    node.isSelected = isSelected;
    node.isPartiallySelected = false;
    for (var child in node.children) {
      _setNodeAndDescendantsSelection(child, isSelected);
    }
  }

  void _toggleExpandCollapseAll() {
    setState(() {
      _isAllExpanded = !_isAllExpanded;
      _setExpansionState(_roots, _isAllExpanded);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: widget.theme ?? Theme.of(context),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showSelectAll || widget.showExpandCollapseButton)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: InkWell(
                    onTap: () {
                      if (widget.showSelectAll) {
                        setState(() {
                          _isAllSelected = !_isAllSelected;
                        });
                        _handleSelectAll(_isAllSelected);
                      }
                    },
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: widget.showExpandCollapseButton
                              ? IconButton(
                                  icon: Icon(_isAllExpanded
                                      ? Icons.unfold_less
                                      : Icons.unfold_more),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: _toggleExpandCollapseAll,
                                )
                              : const SizedBox(),
                        ),
                        if (widget.showSelectAll)
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _isAllSelected,
                              onChanged: _handleSelectAll,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        if (widget.showSelectAll &&
                            widget.selectAllWidget != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: widget.selectAllWidget!,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ..._roots.map((root) => _buildTreeNode(root)),
          ],
        ),
      ),
    );
  }

  List<TreeNode<T>> _getSelectedNodesRecursive(List<TreeNode<T>> nodes) {
    List<TreeNode<T>> selectedNodes = [];
    for (var node in nodes) {
      if (node.isSelected && !node.hidden) {
        selectedNodes.add(node);
      }
      if (node.children.isNotEmpty) {
        selectedNodes.addAll(_getSelectedNodesRecursive(node.children));
      }
    }
    return selectedNodes;
  }
}
