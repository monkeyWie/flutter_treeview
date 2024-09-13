import 'package:flutter/material.dart';
import 'package:checkable_treeview/checkable_treeview.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TreeView Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'TreeView Example'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

enum SortOrder { defaultOrder, ascending, descending }

class _MyHomePageState extends State<MyHomePage> {
  List<TreeNode<String>> _nodes = [];
  String _searchKeyword = '';
  final TextEditingController _searchController = TextEditingController();
  final _treeViewKey = GlobalKey<TreeViewState<String>>();
  SortOrder _currentSortOrder = SortOrder.defaultOrder;

  @override
  void initState() {
    super.initState();
    _nodes = [
      TreeNode(
        label: const Text('Project Folder'),
        value: 'project_folder',
        children: [
          TreeNode(
            label: const Text('src'),
            icon: Icons.folder_open,
            children: [
              TreeNode(
                  label: const Text('main.js'),
                  value: 'main_js',
                  icon: Icons.javascript,
                  isSelected: true),
              TreeNode(
                  label: const Text('app.js'),
                  value: 'app_js',
                  icon: Icons.javascript),
              TreeNode(
                  label: const Text('styles.css'),
                  value: 'styles_css',
                  icon: Icons.css),
            ],
          ),
          TreeNode(
            label: const Text('public'),
            value: 'public_folder',
            icon: Icons.folder_open,
            children: [
              TreeNode(
                  label: const Text('index.html'),
                  value: 'index_html',
                  icon: Icons.html),
              TreeNode(
                  label: const Text('favicon.ico'),
                  value: 'favicon',
                  icon: Icons.image),
            ],
          ),
        ],
      ),
      TreeNode(
        label: const Text('Config Files'),
        value: 'config_folder',
        children: [
          TreeNode(
              label: const Text('package.json'),
              value: 'package_json',
              icon: Icons.settings),
          TreeNode(
              label: const Text('.gitignore'),
              value: 'gitignore',
              icon: Icons.remove_red_eye),
        ],
      ),
    ];
  }

  void _onSelectionChanged(List<String?> selectedValues) {
    print('Selected node values: $selectedValues');
  }

  bool _filterNode(TreeNode<String> node) {
    if (_searchKeyword.isEmpty) {
      return true;
    }
    return node.value?.toLowerCase().contains(_searchKeyword.toLowerCase()) ??
        false;
  }

  void _performSearch() {
    setState(() {
      _searchKeyword = _searchController.text;
      _treeViewKey.currentState?.filter(_filterNode);
    });
    // Add this line to print selected nodes after search
    _printSelectedNodes();
  }

  void _sortNodes(SortOrder order) {
    setState(() {
      _currentSortOrder = order;
      switch (order) {
        case SortOrder.defaultOrder:
          _treeViewKey.currentState?.sort(null);
          break;
        case SortOrder.ascending:
          _treeViewKey.currentState
              ?.sort((a, b) => (a.value ?? '').compareTo(b.value ?? ''));
          break;
        case SortOrder.descending:
          _treeViewKey.currentState
              ?.sort((a, b) => (b.value ?? '').compareTo(a.value ?? ''));
          break;
      }
    });
  }

  void _expandAll() {
    _treeViewKey.currentState?.expandAll();
  }

  void _collapseAll() {
    _treeViewKey.currentState?.collapseAll();
  }

  void _printSelectedNodes() {
    List<TreeNode<String>> selectedNodes =
        _treeViewKey.currentState?.getSelectedNodes() ?? [];
    print('Selected nodes:');
    for (var node in selectedNodes) {
      print('Value: ${node.value}, Label: ${node.label}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Enter search keyword',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _performSearch,
                  child: const Text('Search'),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 150, // 设置固定宽度
                  child: DropdownButton<SortOrder>(
                    isExpanded: true,
                    value: _currentSortOrder,
                    onChanged: (SortOrder? newValue) {
                      if (newValue != null) {
                        _sortNodes(newValue);
                      }
                    },
                    items: SortOrder.values.map((SortOrder order) {
                      return DropdownMenuItem<SortOrder>(
                        value: order,
                        child: Text(_getSortOrderText(order)),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _expandAll,
                  child: const Text('Expand All'),
                ),
                ElevatedButton(
                  onPressed: _collapseAll,
                  child: const Text('Collapse All'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _treeViewKey.currentState?.setSelectAll(true);
                  },
                  child: const Text('Select All'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _treeViewKey.currentState?.setSelectAll(false);
                  },
                  child: const Text('Deselect All'),
                ),
                ElevatedButton(
                  onPressed: _printSelectedNodes,
                  child: const Text('Print Selected Nodes'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TreeView<String>(
                key: _treeViewKey,
                nodes: _nodes,
                onSelectionChanged: _onSelectionChanged,
                initialExpandedLevels: 1,
                showSelectAll: true,
                selectAllWidget: const Text('Select All'),
                showExpandCollapseButton: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getSortOrderText(SortOrder order) {
    switch (order) {
      case SortOrder.defaultOrder:
        return 'Default Order';
      case SortOrder.ascending:
        return 'Ascending';
      case SortOrder.descending:
        return 'Descending';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
