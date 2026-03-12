# Canvas State Persistence Guide

## Overview

The canvas state system stores the visual layout of nodes and their positions in the React Flow interface. It supports both entity-backed nodes (accounts, resources, expenses) and UI-only widget nodes (totals, labels, charts).

## Database Schema

### Tables

#### `canvas_states`
Stores the overall canvas configuration.

- `id` - Primary key
- `name` - Canvas identifier (e.g., "main_dashboard")
- `viewport` - JSONB storing zoom/pan state `{x, y, zoom}`
- `inserted_at`, `updated_at` - Timestamps

#### `node_positions`
Stores individual node positions and metadata.

- `id` - Primary key
- `canvas_state_id` - Foreign key to canvas_states
- `node_type` - String identifying the node type
- `entity_id` - Integer reference to entity (NULL for widgets)
- `position` - JSONB `{x, y}` coordinates
- `dimensions` - JSONB `{width, height}` (optional)
- `ui_metadata` - JSONB for custom node data
- `z_index` - Integer for layering
- `inserted_at`, `updated_at` - Timestamps

## Node Types

### Entity-Backed Nodes
These nodes reference actual database entities and require `entity_id`:

- `"account"` - Financial accounts
- `"resource"` - Resources (supplies, assets, utilities, subscriptions)
- `"expense"` - Expense records
- `"bill"` - Utility bills
- `"supply"` - Supply-specific view (if needed)

### UI Widget Nodes
These nodes are purely visual and have `entity_id: null`:

- `"total_expenses"` - Shows total expenses
- `"total_income"` - Shows total income
- `"net_balance"` - Shows net balance
- `"custom_label"` - Custom text labels
- `"chart_widget"` - Charts and visualizations
- Any custom type you define

## API Endpoints

### Load Canvas State
```
GET /api/canvas/:name
```

Response:
```json
{
  "data": {
    "id": 1,
    "name": "main_dashboard",
    "viewport": {"x": 0, "y": 0, "zoom": 1},
    "nodes": [
      {
        "id": 1,
        "node_type": "account",
        "entity_id": 123,
        "position": {"x": 100, "y": 200},
        "dimensions": null,
        "ui_metadata": {},
        "z_index": 0
      },
      {
        "id": 2,
        "node_type": "total_expenses",
        "entity_id": null,
        "position": {"x": 500, "y": 100},
        "ui_metadata": {
          "title": "Total Expenses",
          "color": "#ef4444"
        },
        "z_index": 0
      }
    ]
  }
}
```

### Save Canvas State
```
POST /api/canvas
```

Request:
```json
{
  "name": "main_dashboard",
  "viewport": {"x": 0, "y": 0, "zoom": 1},
  "nodes": [
    {
      "node_type": "account",
      "entity_id": 123,
      "position": {"x": 100, "y": 200}
    },
    {
      "node_type": "total_expenses",
      "position": {"x": 500, "y": 100},
      "ui_metadata": {
        "title": "Total Expenses",
        "color": "#ef4444"
      }
    }
  ]
}
```

This endpoint creates or updates the entire canvas state, replacing all nodes.

### Update Node Positions Only
```
PATCH /api/canvas/:id/nodes
```

Request:
```json
{
  "nodes": [
    {
      "node_type": "account",
      "entity_id": 123,
      "position": {"x": 150, "y": 250}
    }
  ]
}
```

Updates only the positions of specified nodes without replacing the entire canvas.

### List All Canvas States
```
GET /api/canvas
```

### Delete Canvas State
```
DELETE /api/canvas/:id
```

## Frontend Integration

### Converting to React Flow Nodes

```javascript
// Backend response
const canvasData = {
  viewport: {x: 0, y: 0, zoom: 1},
  nodes: [
    {
      id: 1,
      node_type: "account",
      entity_id: 123,
      position: {x: 100, y: 200},
      ui_metadata: {}
    },
    {
      id: 2,
      node_type: "total_expenses",
      entity_id: null,
      position: {x: 500, y: 100},
      ui_metadata: {title: "Total Expenses"}
    }
  ]
};

// Convert to React Flow format
const reactFlowNodes = canvasData.nodes.map(node => {
  if (node.entity_id) {
    // Entity-backed node
    return {
      id: `${node.node_type}-${node.entity_id}`,
      type: node.node_type,
      position: node.position,
      data: {
        entityId: node.entity_id,
        dbNodeId: node.id,
        ...node.ui_metadata
      }
    };
  } else {
    // Widget node
    return {
      id: `widget-${node.node_type}-${node.id}`,
      type: node.node_type,
      position: node.position,
      data: {
        dbNodeId: node.id,
        ...node.ui_metadata
      }
    };
  }
});
```

### Saving Canvas State

```javascript
const saveCanvasState = async (nodes, viewport) => {
  const payload = {
    name: "main_dashboard",
    viewport: viewport,
    nodes: nodes.map(node => ({
      node_type: node.type,
      entity_id: node.data.entityId || null,
      position: node.position,
      ui_metadata: {
        // Store any custom data
        title: node.data.title,
        color: node.data.color,
        // etc.
      }
    }))
  };

  const response = await fetch('/api/canvas', {
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify(payload)
  });

  return response.json();
};
```

## Context Functions

### `BookVisually.Canvas.get_canvas_state(id)`
Loads a canvas state with all nodes preloaded.

### `BookVisually.Canvas.get_canvas_state_by_name(name)`
Loads a canvas state by name (e.g., "main_dashboard").

### `BookVisually.Canvas.save_full_canvas_state(name, attrs)`
Saves or updates entire canvas state, replacing all nodes.

### `BookVisually.Canvas.update_node_positions(canvas_state_id, node_updates)`
Updates only specific node positions without replacing all nodes.

## Example Usage

### Creating a New Canvas

```elixir
alias BookVisually.Canvas

# Create canvas with nodes
{:ok, canvas} = Canvas.save_full_canvas_state("main_dashboard", %{
  viewport: %{x: 0, y: 0, zoom: 1},
  nodes: [
    %{
      node_type: "account",
      entity_id: 1,
      position: %{x: 100, y: 200}
    },
    %{
      node_type: "total_expenses",
      position: %{x: 500, y: 100},
      ui_metadata: %{title: "Total Expenses", color: "#ef4444"}
    }
  ]
})
```

### Loading a Canvas

```elixir
canvas = Canvas.get_canvas_state_by_name("main_dashboard")
# Returns canvas with node_positions preloaded
```

### Updating Node Positions

```elixir
Canvas.update_node_positions(canvas.id, [
  %{node_type: "account", entity_id: 1, position: %{x: 150, y: 250}}
])
```

## Best Practices

1. **Use descriptive canvas names**: "main_dashboard", "monthly_view", etc.
2. **Store minimal data in ui_metadata**: Only what's needed for rendering
3. **Batch updates**: Use `save_full_canvas_state` for bulk changes
4. **Incremental updates**: Use `update_node_positions` for drag operations
5. **Widget flexibility**: Add new widget types without schema changes
6. **Clean up**: Delete canvas states when no longer needed

## Adding New Node Types

To add a new node type, simply use it in your frontend:

```javascript
// No backend changes needed!
const newNode = {
  node_type: "pie_chart",  // New type
  position: {x: 300, y: 400},
  ui_metadata: {
    data_source: "expenses_by_category",
    colors: ["#ef4444", "#10b981", "#3b82f6"]
  }
};
```

The string-based `node_type` field allows unlimited flexibility.
