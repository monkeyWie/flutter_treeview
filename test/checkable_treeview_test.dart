import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:checkable_treeview/checkable_treeview.dart';

void main() {
  testWidgets('TreeView initializes with correct number of nodes',
      (WidgetTester tester) async {
    // Create test node data
    final testNodes = [
      TreeNode<String>(
        label: const Text('Root 1'),
        children: [
          TreeNode<String>(label: const Text('Child 1.1')),
          TreeNode<String>(label: const Text('Child 1.2')),
        ],
      ),
      TreeNode<String>(
        label: const Text('Root 2'),
        children: [
          TreeNode<String>(label: const Text('Child 2.1')),
          TreeNode<String>(label: const Text('Child 2.2')),
        ],
      ),
    ];

    // Build the TreeView widget
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: TreeView<String>(
            nodes: testNodes,
            onSelectionChanged: (_) {},
            initialExpandedLevels: 0, // Expand all nodes
          ),
        ),
      ),
    );

    // Wait for all animations to complete
    await tester.pumpAndSettle();

    // Verify root node count
    expect(find.text('Root 1'), findsOneWidget);
    expect(find.text('Root 2'), findsOneWidget);

    // Verify child node count
    expect(find.text('Child 1.1'), findsOneWidget);
    expect(find.text('Child 1.2'), findsOneWidget);
    expect(find.text('Child 2.1'), findsOneWidget);
    expect(find.text('Child 2.2'), findsOneWidget);

    // Verify total node count
    expect(find.byType(Text), findsNWidgets(6));
  });

  testWidgets('TreeView getSelectedValues returns correct values',
      (WidgetTester tester) async {
    // Create test node data with values
    final testNodes = [
      TreeNode<String>(
        label: const Text('Root 1'),
        value: 'value1',
        children: [
          TreeNode<String>(label: const Text('Child 1.1'), value: 'value1.1'),
          TreeNode<String>(label: const Text('Child 1.2'), value: 'value1.2'),
        ],
      ),
      TreeNode<String>(
        label: const Text('Root 2'),
        value: 'value2',
        children: [
          TreeNode<String>(label: const Text('Child 2.1'), value: 'value2.1'),
          TreeNode<String>(label: const Text('Child 2.2'), value: 'value2.2'),
        ],
      ),
    ];

    // Create a GlobalKey to access the TreeViewState
    final GlobalKey<TreeViewState<String>> treeViewKey = GlobalKey();

    // Build the TreeView widget
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: TreeView<String>(
            key: treeViewKey,
            nodes: testNodes,
            onSelectionChanged: (_) {},
            initialExpandedLevels: 0, // Expand all nodes
          ),
        ),
      ),
    );

    // Wait for all animations to complete
    await tester.pumpAndSettle();

    // Select some nodes
    await tester.tap(find.text('Root 1'));
    await tester.tap(find.text('Child 2.2'));
    await tester.pumpAndSettle();

    // Get selected values
    final selectedValues = treeViewKey.currentState!.getSelectedValues();

    // Verify selected values
    expect(selectedValues,
        containsAll(['value1', 'value1.1', 'value1.2', 'value2.2']));
    expect(selectedValues.length, 4);
  });
}
