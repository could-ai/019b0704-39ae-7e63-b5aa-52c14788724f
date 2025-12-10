import 'package:flutter/material.dart';
import 'dart:math';
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
  
  String _generateUuid() {
    return '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(10000)}';
  }

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
        instanceId: _generateUuid(),
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
                                final RenderBox renderBox = context.findRenderObject() as RenderBox;
                                final localPos = renderBox.globalToLocal(details.offset);
                                _updateItemPosition(item.instanceId, localPos.translate(-30, -30)); 
                              }
                            },
                            onCombine: (sourceId) {
                              // Logic handled in DraggableWorkspaceItem
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
                final data = details.data;
                final RenderBox renderBox = context.findRenderObject() as RenderBox;
                final localPos = renderBox.globalToLocal(details.offset);
                
                if (data.sourceType == SourceType.inventory) {
                  _addWorkspaceItem(data.elementId, localPos.translate(-30, -30));
                } else if (data.sourceType == SourceType.workspace) {
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
  final String? instanceId; 

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
        if (details.data.instanceId == widget.item.instanceId) return false;
        return true;
      },
      onAcceptWithDetails: (details) {
        final droppedData = details.data;
        final result = getCombinationResult(widget.item.id, droppedData.elementId);
        
        final parentState = context.findAncestorStateOfType<_AlchemyGameScreenState>();
        if (parentState != null) {
          if (result != null) {
            // Combination successful
            if (droppedData.sourceType == SourceType.workspace && droppedData.instanceId != null) {
              parentState._removeItem(droppedData.instanceId!);
            }
            parentState._removeItem(widget.item.instanceId);
            parentState._addWorkspaceItem(result, widget.item.position);
            
            if (!parentState._unlockedElements.contains(result)) {
              parentState.setState(() {
                parentState._unlockedElements.add(result);
              });
              parentState._showDiscoveryDialog(getElementById(result));
            }
          } else {
            // No combination, just move/add nearby
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
