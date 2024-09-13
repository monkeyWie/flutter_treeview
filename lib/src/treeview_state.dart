part of 'treeview.dart';

/// The state management class for the [TreeView] widget.
///
/// This class handles the internal logic and state of the tree view, including:
/// - Node selection and deselection
/// - Expansion and collapse of nodes
/// - Filtering and sorting of nodes
/// - Handling of "Select All" functionality
/// - Managing the overall tree structure
///
/// It also provides methods for external manipulation of the tree, such as:
/// - [filter] for applying filters to the tree nodes
/// - [sort] for sorting the tree nodes
/// - [setSelectAll] for selecting or deselecting all nodes
/// - [expandAll] and [collapseAll] for expanding or collapsing all nodes
/// - [getSelectedNodes] and [getSelectedValues] for retrieving selected items
///
/// This class is not intended to be used directly by users of the [TreeView] widget,
/// but rather serves as the internal state management mechanism.
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
            _roots, (a, b) => a._originalIndex.compareTo(b._originalIndex));
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
      nodes[i]._originalIndex = i;
      nodes[i]._parent = parent;
      _initializeNodes(nodes[i].children, nodes[i]);
    }
  }

  void _setInitialExpansion(List<TreeNode<T>> nodes, int currentLevel) {
    if (widget.initialExpandedLevels == null) {
      return;
    }
    for (var node in nodes) {
      if (widget.initialExpandedLevels == 0) {
        node._isExpanded = true;
      } else {
        node._isExpanded = currentLevel < widget.initialExpandedLevels!;
      }
      if (node._isExpanded) {
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
      node._hidden = !shouldShow;
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
    if (node._isSelected || node._isPartiallySelected) {
      _updateNodeAndDescendants(node, false);
    } else {
      _updateNodeAndDescendants(node, true);
    }
  }

  void _updateNodeAndDescendants(TreeNode<T> node, bool isSelected) {
    if (!node._hidden) {
      node._isSelected = isSelected;
      node._isPartiallySelected = false;
      for (var child in node.children) {
        _updateNodeAndDescendants(child, isSelected);
      }
    }
  }

  void _updateAncestorsRecursively(TreeNode<T> node) {
    TreeNode<T>? parent = node._parent;
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
      if (node._isSelected && !node._hidden) {
        selectedValues.add(node.value);
      }
      selectedValues.addAll(_getSelectedValues(node.children));
    }
    return selectedValues;
  }

  Widget _buildTreeNode(TreeNode<T> node, {double leftPadding = 0}) {
    if (node._hidden) {
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
              onTap: () => _updateNodeSelection(node, !node._isSelected),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: node.children.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              node._isExpanded
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
                      value: node._isSelected
                          ? true
                          : (node._isPartiallySelected ? null : false),
                      tristate: true,
                      onChanged: (bool? value) =>
                          _updateNodeSelection(node, value ?? false),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  if (node.icon != null) Icon(node.icon),
                  const SizedBox(width: 4),
                  Expanded(child: node.label),
                ],
              ),
            ),
          ),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            tween: Tween<double>(
              begin: node._isExpanded ? 0 : 1,
              end: node._isExpanded ? 1 : 0,
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
      node._isExpanded = !node._isExpanded;
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
    if (node.children.isEmpty ||
        node.children.every((child) => child._hidden)) {
      return;
    }

    List<TreeNode<T>> visibleChildren =
        node.children.where((child) => !child._hidden).toList();
    bool allSelected = visibleChildren.every((child) => child._isSelected);
    bool anySelected = visibleChildren
        .any((child) => child._isSelected || child._isPartiallySelected);

    if (allSelected) {
      node._isSelected = true;
      node._isPartiallySelected = false;
    } else if (anySelected) {
      node._isSelected = false;
      node._isPartiallySelected = true;
    } else {
      node._isSelected = false;
      node._isPartiallySelected = false;
    }
  }

  void _setExpansionState(List<TreeNode<T>> nodes, bool isExpanded) {
    for (var node in nodes) {
      node._isExpanded = isExpanded;
      _setExpansionState(node.children, isExpanded);
    }
  }

  void _updateSelectAllState() {
    if (!widget.showSelectAll) return;
    bool allSelected = _roots
        .where((node) => !node._hidden)
        .every((node) => _isNodeFullySelected(node));
    setState(() {
      _isAllSelected = allSelected;
    });
  }

  bool _isNodeFullySelected(TreeNode<T> node) {
    if (node._hidden) return true;
    if (!node._isSelected) return false;
    return node.children
        .where((child) => !child._hidden)
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
    if (node._hidden) return;
    node._isSelected = isSelected;
    node._isPartiallySelected = false;
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
      if (node._isSelected && !node._hidden) {
        selectedNodes.add(node);
      }
      if (node.children.isNotEmpty) {
        selectedNodes.addAll(_getSelectedNodesRecursive(node.children));
      }
    }
    return selectedNodes;
  }
}
