# Canvas Persistence Implementation

## Overview

The canvas state persistence system is now fully wired up to save and restore node positions, connections (edges), and viewport state automatically.

## What Was Implemented

### Backend

1. **Database Schema**
   - `canvas_states` table - stores canvas configuration and viewport
   - `node_positions` table - stores individual node positions and metadata
   - `canvas_edges` table - stores connections between nodes

2. **Elixir Modules**
   - `BookVisually.Canvas.State` - Canvas state schema
   - `BookVisually.Canvas.NodePosition` - Node position schema
   - `BookVisually.Canvas.Edge` - Edge/connection schema
   - `BookVisually.Canvas` - Context with CRUD operations

3. **API Endpoints**
   - `GET /api/canvas/:name` - Load canvas by name
   - `POST /api/canvas` - Save/update entire canvas
   - `GET /api/canvas` - List all canvases
   - `DELETE /api/canvas/:id` - Delete canvas

### Frontend

1. **API Client Updates**
   - Added `getCanvasState(name)` method
   - Added `saveCanvasState(data)` method
   - Added `updateNodePositions(canvasId, nodes)` method

2. **App.jsx Enhancements**
   - Integrated `useReactFlow` hook for viewport access
   - Added debounced auto-save (1 second after changes)
   - Load saved positions on startup
   - Save on node drag, edge creation, and node addition
   - Restore edges/connections from database

3. **Main.jsx**
   - Wrapped App with `ReactFlowProvider` for React Flow hooks

## How It Works

### Auto-Save Behavior

The canvas automatically saves to the backend when:
- **Node is dragged** - Saves 1 second after drag ends
- **Edge is created** - Saves 1 second after connection
- **Node is added** - Saves immediately after account/resource creation
- **Edge is deleted** - Saves 1 second after deletion

### Data Flow

1. **On Load**:
   - Fetches accounts, resources, expenses from API
   - Fetches saved canvas state by name ("main_dashboard")
   - Applies saved positions to nodes, or uses defaults
   - Restores saved edges/connections

2. **On Change**:
   - User drags node or creates connection
   - Change triggers debounced save function
   - After 1 second of inactivity, saves to backend
   - Includes viewport (zoom/pan), all node positions, all edges

3. **On Reload**:
   - Loads fresh data from API
   - Applies saved positions from canvas state
   - Nodes appear exactly where user left them
   - Connections are restored

## Node Types Supported

### Entity-Backed Nodes
Nodes that reference database entities (have `entity_id`):
- `account` - Financial accounts
- `resource` - Resources (supplies, assets, utilities)
- `expense` - Individual expenses

### Widget Nodes
UI-only nodes (no `entity_id`):
- `total-expenses` - Currently implemented as expense summary
- Can add more: `total_income`, `net_balance`, `custom_label`, etc.

## Edge/Connection Storage

Edges are stored with:
- `source_node_type` - Type of source node
- `source_entity_id` - ID of source entity (null for widgets)
- `target_node_type` - Type of target node
- `target_entity_id` - ID of target entity (null for widgets)
- `edge_metadata` - JSONB for styling (animated, label, style)

## Testing

To test the persistence:

1. Start backend: `cd backend && mix phx.server`
2. Start frontend: `cd frontend && npm run dev`
3. Drag nodes around
4. Create connections between nodes
5. Refresh the page
6. Verify nodes and connections are in the same positions

## Future Enhancements

Potential improvements:
- Multiple canvas views (monthly, quarterly, etc.)
- Undo/redo functionality
- Canvas snapshots/versions
- Collaborative editing with real-time sync
- Export/import canvas layouts
- Canvas templates

## Configuration

Current settings in `frontend/src/App.jsx`:
```javascript
const CANVAS_NAME = 'main_dashboard';  // Canvas identifier
const SAVE_DEBOUNCE_MS = 1000;         // Save delay in milliseconds
```

## API Payload Examples

### Save Canvas
```json
POST /api/canvas
{
  "name": "main_dashboard",
  "viewport": {"x": 0, "y": 0, "zoom": 1},
  "nodes": [
    {
      "node_type": "account",
      "entity_id": 1,
      "position": {"x": 100, "y": 200},
      "ui_metadata": {}
    }
  ],
  "edges": [
    {
      "source_node_type": "account",
      "source_entity_id": 1,
      "target_node_type": "expense",
      "target_entity_id": null,
      "edge_metadata": {"animated": true}
    }
  ]
}
```

### Load Canvas
```json
GET /api/canvas/main_dashboard

Response:
{
  "data": {
    "id": 1,
    "name": "main_dashboard",
    "viewport": {"x": 0, "y": 0, "zoom": 1},
    "nodes": [...],
    "edges": [...]
  }
}
```

## Notes

- Canvas state is saved per name, not per user (add user_id later for multi-user)
- Debouncing prevents excessive API calls during rapid changes
- Failed saves are logged to console but don't block UI
- First save creates the canvas, subsequent saves update it
- Deleting entities doesn't automatically clean up canvas nodes (future enhancement)
