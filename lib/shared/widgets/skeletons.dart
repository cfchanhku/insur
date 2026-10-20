/// Generic skeleton placeholders for asynchronous lists.
library;

import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Card-shaped placeholder matching the client and policy list rows.
class CardSkeleton extends StatelessWidget {
  /// Creates a card skeleton with an optional leading avatar.
  const CardSkeleton({super.key, this.showAvatar = true});

  /// Whether the row reserves space for a leading avatar.
  final bool showAvatar;

  @override
  Widget build(BuildContext context) => Skeletonizer.zone(
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            if (showAvatar) ...<Widget>[
              const Bone.circle(size: 48),
              const SizedBox(width: 16),
            ],
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Bone.text(width: 180),
                  SizedBox(height: 8),
                  Bone.text(width: 120),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Five generic placeholders for the client list.
class ClientListSkeleton extends StatelessWidget {
  /// Creates a client list skeleton.
  const ClientListSkeleton({super.key});

  @override
  Widget build(BuildContext context) =>
      const _SkeletonList(itemCount: 5, showAvatar: true);
}

/// Three generic placeholders for the policy list.
class PolicyListSkeleton extends StatelessWidget {
  /// Creates a policy list skeleton.
  const PolicyListSkeleton({super.key});

  @override
  Widget build(BuildContext context) =>
      const _SkeletonList(itemCount: 3, showAvatar: false, embedded: true);
}

/// Three generic placeholders for the plan list.
class PlanListSkeleton extends StatelessWidget {
  /// Creates a plan list skeleton.
  const PlanListSkeleton({super.key});

  @override
  Widget build(BuildContext context) =>
      const _SkeletonList(itemCount: 3, showAvatar: false, embedded: true);
}

/// Five generic placeholders for the audit history.
class AuditListSkeleton extends StatelessWidget {
  /// Creates an audit list skeleton.
  const AuditListSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Skeletonizer.zone(
    child: ListView.builder(
      itemCount: 5,
      itemBuilder: (BuildContext context, int index) => const ListTile(
        leading: Bone.circle(size: 40),
        title: Bone.text(width: 180),
        subtitle: Bone.text(width: 120),
      ),
    ),
  );
}

class _SkeletonList extends StatelessWidget {
  const _SkeletonList({
    required this.itemCount,
    required this.showAvatar,
    this.embedded = false,
  });

  final int itemCount;
  final bool showAvatar;
  final bool embedded;

  List<Widget> _buildItems() => <Widget>[
    for (int index = 0; index < itemCount; index++) ...<Widget>[
      CardSkeleton(showAvatar: showAvatar),
      if (index < itemCount - 1) const SizedBox(height: 8),
    ],
  ];

  @override
  Widget build(BuildContext context) {
    if (embedded) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Skeletonizer.zone(child: Column(children: _buildItems())),
      );
    }
    return Skeletonizer.zone(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: _buildItems(),
      ),
    );
  }
}
