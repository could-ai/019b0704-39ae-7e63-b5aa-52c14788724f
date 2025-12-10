import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'alchemy_data.dart';

class AlchemyGameScreen extends StatefulWidget {
  const AlchemyGameScreen({super.key});

  @override
  State<AlchemyGameScreen> createState() => _AlchemyGameScreenState();
}

class WorkspaceItem {
  final String id;
  final String instanceId;
  Offset position;

  WorkspaceItem({
    required this.id,
    required this.instanceId,
    required this.position,
  });
}

class _AlchemyGameScreenState extends State<AlchemyGameScreen> {
  final Set<String> _unlockedElements = {};
  final List<WorkspaceItem> _workspaceItems = [];
  final Uuid _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    // Initialize with basic elements
    for (var el in initialElements) {
      _unlockedElements.add(el.id);
    }
  }

  void _addWorkspaceItem(String elementId, Offset position) {
    setState(() {
      _workspaceItems.add(WorkspaceItem(
        id: elementId,
        instanceId: _uuid.v4(),
        position: position,
      ));
    });
  }

  void _updateItemPosition(String instanceId, Offset newPosition) {
    setState(() {
      final index = _workspaceItems.indexWhere((item) => item.instanceId == instanceId);
      if (index != -1) {
        _workspaceItems[index].position = newPosition;
      }
    });
  }

  void _removeItem(String instanceId) {
    setState(() {
      _workspaceItems.removeWhere((item) => item.instanceId == instanceId);
    });
  }

  void _handleCombination(String targetInstanceId, String droppedElementId) {
    final targetItem = _workspaceItems.firstWhere(
      (item) => item.instanceId == targetInstanceId,
      orElse: () => WorkspaceItem(id: '', instanceId: '', position: Offset.zero),
    );

    if (targetItem.instanceId.isEmpty) return;

    final resultId = getCombinationResult(targetItem.id, droppedElementId);

    if (resultId != null) {
      // Successful combination!
      final resultElement = getElementById(resultId);
      
      // Remove the target item (the dropped one is handled by the drag end usually, 
      // but if it was from workspace we need to remove it too. 
      // However, this method is called when 'accepting' data.
      // If dragging from inventory, we just remove target and add new.
      // If dragging from workspace, the 'onDragEnd' or similar logic handles the source removal?
      // Actually, DragTarget onAccept gives us the data. We need to know if the source was workspace or inventory.
      
      // Let's simplify: The data passed during drag will be a custom object containing source info.
      
      _removeItem(targetInstanceId);
      
      // Add the new item at the target's position
      _addWorkspaceItem(resultId, targetItem.position);

      // Check if it's a new discovery
      if (!_unlockedElements.contains(resultId)) {
        _unlockedElements.add(resultId);
        _showDiscoveryDialog(resultElement);
      }
    } else {
      // No combination, just stack? Or bounce?
      // For now, if we drag from inventory, we add it nearby.
      // If we drag from workspace, it just moves there.
      // But wait, this method is called inside the Target's onAccept.
      // If we return false or don't do anything, the drag might just complete.
    }
  }

  void _showDiscoveryDialog(AlchemyElement element) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("New Discovery!"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(element.icon, size: 64, color: element.color),
            const SizedBox(height: 16),
            Text(
              element.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Awesome!"),
          ),
        ],
      ),
    );
  }

  void _clearWorkspace() {
    setState(() {
      _workspaceItems.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alchemy Lab'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear Workspace',
            onPressed: _clearWorkspace,
          ),
        ],
      ),
      body: Column(
        children: [
          // Workspace Area
          Expanded(
            flex: 3,
            child: DragTarget<DragData>(
              builder: (context, candidateData, rejectedData) {
                return Container(
                  color: Colors.grey.shade100,
                  child: Stack(
                    children: [
                      // Render all workspace items
                      ..._workspaceItems.map((item) {
                        return Positioned(
                          left: item.position.dx,
                          top: item.position.dy,
                          child: DraggableWorkspaceItem(
                            key: ValueKey(item.instanceId),
                            item: item,
                            onDragEnd: (details, wasAccepted) {
                              if (!wasAccepted) {
                                // Update position if dropped on empty space (handled by background target)
                                // But wait, the background target accepts it.
                                // We need to calculate local position relative to the stack.
                                final RenderBox renderBox = context.findRenderObject() as RenderBox;
                                final localPos = renderBox.globalToLocal(details.offset);
                                // Adjust for the item size (centering) - assuming 60x60 item
                                _updateItemPosition(item.instanceId, localPos.translate(-30, -30)); // rough center
                              }
                            },
                            onCombine: (sourceId) {
                              // Handle combination logic
                              // sourceId is the element ID of the item being dropped ONTO this item
                              // We need to know if the source was from inventory or workspace to remove it correctly?
                              // Actually, the DraggableWorkspaceItem's DragTarget onAccept will handle this.
                            },
                            onRemove: () => _removeItem(item.instanceId),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
              onWillAcceptWithDetails: (details) => true,
              onAcceptWithDetails: (details) {
                // Dropped on the background (empty space)
                final data = details.data;
                final RenderBox renderBox = context.findRenderObject() as RenderBox;
                final localPos = renderBox.globalToLocal(details.offset);
                
                if (data.sourceType == SourceType.inventory) {
                  _addWorkspaceItem(data.elementId, localPos.translate(-30, -30));
                } else if (data.sourceType == SourceType.workspace) {
                  // Moved within workspace
                  _updateItemPosition(data.instanceId!, localPos.translate(-30, -30));
                }
              },
            ),
          ),
          
          // Divider
          const Divider(height: 1, thickness: 1),
          
          // Inventory Area
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      "Elements (${_unlockedElements.length}/${allElements.length})",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 80,
                        childAspectRatio: 1,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _unlockedElements.length,
                      itemBuilder: (context, index) {
                        final elementId = _unlockedElements.elementAt(index);
                        final element = getElementById(elementId);
                        return Draggable<DragData>(
                          data: DragData(
                            elementId: element.id,
                            sourceType: SourceType.inventory,
                          ),
                          feedback: ElementIcon(element: element, isDragging: true),
                          childWhenDragging: ElementIcon(element: element, isGhost: true),
                          child: ElementIcon(element: element),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum SourceType { inventory, workspace }

class DragData {
  final String elementId;
  final SourceType sourceType;
  final String? instanceId; // Only for workspace items

  DragData({required this.elementId, required this.sourceType, this.instanceId});
}

class ElementIcon extends StatelessWidget {
  final AlchemyElement element;
  final bool isDragging;
  final bool isGhost;

  const ElementIcon({
    super.key,
    required this.element,
    this.isDragging = false,
    this.isGhost = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isGhost ? 0.5 : 1.0,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isDragging ? element.color.withOpacity(0.8) : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: element.color, width: 2),
          boxShadow: isDragging
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(element.icon, color: isDragging ? Colors.white : element.color),
            const SizedBox(height: 2),
            Text(
              element.name,
              style: TextStyle(
                fontSize: 10,
                color: isDragging ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class DraggableWorkspaceItem extends StatefulWidget {
  final WorkspaceItem item;
  final Function(DraggableDetails, bool) onDragEnd;
  final Function(String) onCombine;
  final VoidCallback onRemove;

  const DraggableWorkspaceItem({
    super.key,
    required this.item,
    required this.onDragEnd,
    required this.onCombine,
    required this.onRemove,
  });

  @override
  State<DraggableWorkspaceItem> createState() => _DraggableWorkspaceItemState();
}

class _DraggableWorkspaceItemState extends State<DraggableWorkspaceItem> {
  @override
  Widget build(BuildContext context) {
    final element = getElementById(widget.item.id);

    return DragTarget<DragData>(
      onWillAcceptWithDetails: (details) {
        // Don't accept itself
        if (details.data.instanceId == widget.item.instanceId) return false;
        return true;
      },
      onAcceptWithDetails: (details) {
        final droppedData = details.data;
        
        // Check for combination
        final result = getCombinationResult(widget.item.id, droppedData.elementId);
        
        if (result != null) {
          // We have a match!
          
          // 1. If source was workspace, remove it (parent needs to handle this via callback or state)
          // Actually, the parent handles the state. We need to tell the parent:
          // "I (target) combined with (source). Remove me, remove source (if workspace), add result."
          
          // Since we are inside the item widget, we can't easily modify the parent list directly 
          // without a callback that handles everything.
          
          // Let's use a global event or callback that passes all info.
          // But wait, we are in a DragTarget.
          
          // We need to access the parent state.
          final parentState = context.findAncestorStateOfType<_AlchemyGameScreenState>();
          if (parentState != null) {
            // Remove source if it's from workspace
            if (droppedData.sourceType == SourceType.workspace && droppedData.instanceId != null) {
              parentState._removeItem(droppedData.instanceId!);
            }
            
            // Remove target (myself)
            parentState._removeItem(widget.item.instanceId);
            
            // Add result
            parentState._addWorkspaceItem(result, widget.item.position);
            
            // Check discovery
            if (!parentState._unlockedElements.contains(result)) {
              parentState.setState(() {
                parentState._unlockedElements.add(result);
              });
              parentState._showDiscoveryDialog(getElementById(result));
            }
          }
        } else {
          // No combination.
          // If source was inventory, maybe we just add it on top?
          // If source was workspace, it just moves on top.
          // The background DragTarget might NOT get this event if this target consumes it.
          // If we want the item to just "move" here without combining, we should probably 
          // let the background handle it?
          // But DragTarget consumes the drop.
          
          // If we don't combine, we should probably just place the item nearby or on top.
          final parentState = context.findAncestorStateOfType<_AlchemyGameScreenState>();
           if (parentState != null) {
             // Just add/move the item to this location (slightly offset so they don't perfectly overlap)
             if (droppedData.sourceType == SourceType.inventory) {
               parentState._addWorkspaceItem(droppedData.elementId, widget.item.position + const Offset(20, 20));
             } else if (droppedData.sourceType == SourceType.workspace && droppedData.instanceId != null) {
               parentState._updateItemPosition(droppedData.instanceId!, widget.item.position + const Offset(20, 20));
             }
           }
        }
      },
      builder: (context, candidateData, rejectedData) {
        return Draggable<DragData>(
          data: DragData(
            elementId: widget.item.id,
            sourceType: SourceType.workspace,
            instanceId: widget.item.instanceId,
          ),
          feedback: ElementIcon(element: element, isDragging: true),
          childWhenDragging: Opacity(opacity: 0.0, child: ElementIcon(element: element)),
          onDragEnd: (details) => widget.onDragEnd(details, details.wasAccepted),
          child: ScaleTransition(
            scale: candidateData.isNotEmpty 
                ? const AlwaysStoppedAnimation(1.1) 
                : const AlwaysStoppedAnimation(1.0),
            child: ElementIcon(element: element),
          ),
        );
      },
    );
  }
}
