import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Simple demo page that mirrors the structure described in the issue.
///
/// The page exposes a narrow layout that scrolls vertically and a wide layout
/// that shows multiple panels side by side. The wide layout previously lived
/// inside a [SingleChildScrollView], which meant that the surrounding
/// [LayoutBuilder] delivered `BoxConstraints` with an infinite height. Once the
/// central panel asked for a [SizedBox.expand], Flutter rightfully complained
/// about the missing finite height.
///
/// The fix keeps the scroll view exclusive to the narrow layout. When the view
/// is wide enough we instead hand a finite height to `_buildWideLayout` by
/// wrapping it in a [SizedBox]. The [SizedBox] either reuses the tight height
/// from the parent constraints or, when the parent is still unbounded, falls
/// back to a constant `_wideLayoutMinHeight`. `_buildCentralPanel` can therefore
/// continue to rely on [SizedBox.expand] without hitting exceptions.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  static const double _wideLayoutBreakpoint = 920;
  static const double _wideLayoutMinHeight = 600;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return _buildContent(context, constraints);
      },
    );
  }

  Widget _buildContent(BuildContext context, BoxConstraints constraints) {
    final bool isWide = constraints.maxWidth >= _wideLayoutBreakpoint;

    if (isWide) {
      // Provide a finite height so that the row in `_buildWideLayout` receives
      // tight vertical constraints before `_buildCentralPanel(expand: true)`
      // invokes `SizedBox.expand`.
      final bool hasTightHeight = constraints.hasBoundedHeight;
      final double resolvedHeight = hasTightHeight
          ? constraints.maxHeight
          : _wideLayoutMinHeight;

      return SizedBox(
        height: resolvedHeight,
        child: _buildWideLayout(context),
      );
    }

    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: _buildNarrowLayout(context),
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          flex: 2,
          child: _buildNavigationRail(context),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 5,
          child: _buildCentralPanel(expand: true),
        ),
        const SizedBox(width: 24),
        Flexible(
          flex: 3,
          child: _buildSidePanel(context),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildNavigationRail(context),
        const SizedBox(height: 16),
        _buildCentralPanel(),
        const SizedBox(height: 16),
        _buildSidePanel(context),
      ],
    );
  }

  Widget _buildNavigationRail(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('Navigation ${index + 1}'),
          );
        },
      ),
    );
  }

  Widget _buildCentralPanel({bool expand = false}) {
    final Widget content = Container(
      padding: const EdgeInsets.all(24),
      color: Colors.blueGrey.shade50,
      child: const Text('Central panel placeholder'),
    );

    if (!expand) {
      return content;
    }

    return SizedBox.expand(child: content);
  }

  Widget _buildSidePanel(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final int columnCount = math.max(1, (constraints.maxWidth ~/ 180));
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 8,
          itemBuilder: (context, index) {
            return Card(
              child: Center(child: Text('Item ${index + 1}')),
            );
          },
        );
      },
    );
  }
}
