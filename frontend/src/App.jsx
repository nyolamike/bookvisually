import { useState, useCallback, useEffect, useRef } from 'react';
import {
  ReactFlow,
  Background,
  Controls,
  MiniMap,
  useNodesState,
  useEdgesState,
  addEdge,
  useReactFlow,
} from '@xyflow/react';
import '@xyflow/react/dist/style.css';

import AccountNode from './components/nodes/AccountNode';
import ResourceNode from './components/nodes/ResourceNode';
import ExpenseNode from './components/nodes/ExpenseNode';
import AnimatedEdge from './components/edges/AnimatedEdge';
import CreateAccountModal from './components/modals/CreateAccountModal';
import CreateResourceModal from './components/modals/CreateResourceModal';
import DepositModal from './components/modals/DepositModal';
import SupplyActionsModal from './components/modals/SupplyActionsModal';
import api from './services/api';

const nodeTypes = {
  account: AccountNode,
  resource: ResourceNode,
  expense: ExpenseNode,
};

const edgeTypes = {
  animated: AnimatedEdge,
};

const CANVAS_NAME = 'main_dashboard';
const SAVE_DEBOUNCE_MS = 1000; // Save 1 second after last change

function App() {
  const [nodes, setNodes, onNodesChange] = useNodesState([]);
  const [edges, setEdges, onEdgesChange] = useEdgesState([]);
  const [showAccountModal, setShowAccountModal] = useState(false);
  const [showResourceModal, setShowResourceModal] = useState(false);
  const [showDepositModal, setShowDepositModal] = useState(false);
  const [showSupplyActionsModal, setShowSupplyActionsModal] = useState(false);
  const [selectedAccount, setSelectedAccount] = useState(null);
  const [selectedResource, setSelectedResource] = useState(null);
  const [dashboard, setDashboard] = useState(null);
  const [accounts, setAccounts] = useState([]);
  const [canvasStateId, setCanvasStateId] = useState(null);
  const saveTimeoutRef = useRef(null);
  const edgeTriggersRef = useRef(new Map()); // Store edge trigger functions
  const { getViewport, setViewport } = useReactFlow();

  // Save canvas state to backend
  const saveCanvasState = useCallback(async () => {
    if (nodes.length === 0) {
      console.log('No nodes to save yet');
      return;
    }

    console.log('Current edges when saving:', edges);

    try {
      const viewport = getViewport();
      
      const payload = {
        name: CANVAS_NAME,
        viewport: viewport,
        nodes: nodes.map(node => ({
          node_type: node.id === 'total-expenses' ? 'total_expenses' : node.type,  // Use different type for widget
          entity_id: node.id === 'total-expenses' ? null : node.id,
          position: node.position,
          ui_metadata: {
            ...(node.id === 'total-expenses' && { 
              is_total_widget: true 
            })
          }
        })),
        edges: edges.map(edge => {
          const sourceNode = nodes.find(n => n.id === edge.source);
          const targetNode = nodes.find(n => n.id === edge.target);
          
          return {
            source_node_type: sourceNode?.type || 'unknown',
            source_entity_id: edge.source === 'total-expenses' ? null : edge.source,
            target_node_type: targetNode?.type || 'unknown',
            target_entity_id: edge.target === 'total-expenses' ? null : edge.target,
            edge_metadata: {
              animated: edge.animated,
              label: edge.label,
              style: edge.style
            }
          };
        })
      };

      console.log('Saving canvas with', payload.nodes.length, 'nodes and', payload.edges.length, 'edges');
      const response = await api.saveCanvasState(payload);
      setCanvasStateId(response.data.id);
      console.log('Canvas state saved successfully');
    } catch (error) {
      console.error('Failed to save canvas state:', error);
    }
  }, [nodes, edges, getViewport]);

  // Debounced save function
  const debouncedSave = useCallback(() => {
    if (saveTimeoutRef.current) {
      clearTimeout(saveTimeoutRef.current);
    }
    saveTimeoutRef.current = setTimeout(() => {
      saveCanvasState();
    }, SAVE_DEBOUNCE_MS);
  }, [saveCanvasState]);

  const onConnect = useCallback(
    (params) => {
      setEdges((eds) => addEdge({
        ...params,
        data: {
          registerTrigger: (edgeId, triggerFn) => {
            edgeTriggersRef.current.set(edgeId, triggerFn);
          },
          unregisterTrigger: (edgeId) => {
            edgeTriggersRef.current.delete(edgeId);
          }
        }
      }, eds));
    },
    [setEdges]
  );

  // Load canvas state from backend
  const loadCanvasState = async () => {
    try {
      const response = await api.getCanvasState(CANVAS_NAME);
      const canvasData = response.data;
      setCanvasStateId(canvasData.id);
      return canvasData;
    } catch (error) {
      // Canvas doesn't exist yet, will be created on first save
      console.log('No saved canvas state found, will create new one');
      return null;
    }
  };

  // Trigger flow animation from account -> resource -> expense
  const triggerFlowAnimation = useCallback((accountId, resourceId, amount) => {
    // Find edge from account to resource
    const accountToResourceEdge = edges.find(e => 
      e.source === accountId && e.target === resourceId
    );
    
    // Find edge from resource to total expenses
    const resourceToExpenseEdge = edges.find(e => 
      e.source === resourceId && e.target === 'total-expenses'
    );

    if (accountToResourceEdge) {
      const trigger1 = edgeTriggersRef.current.get(accountToResourceEdge.id);
      if (trigger1) {
        trigger1(amount);
        
        // Trigger second animation after first completes
        if (resourceToExpenseEdge) {
          setTimeout(() => {
            const trigger2 = edgeTriggersRef.current.get(resourceToExpenseEdge.id);
            if (trigger2) {
              trigger2(amount);
            }
          }, 2000); // Wait for first animation to complete
        }
      }
    }
  }, [edges]);

  // Load initial data
  useEffect(() => {
    loadData();
  }, []);

  // Auto-save when edges change (for connections)
  useEffect(() => {
    if (edges.length > 0) {
      debouncedSave();
    }
  }, [edges, debouncedSave]);

  const loadData = async () => {
    try {
      const [accountsRes, resourcesRes, expensesRes, dashboardRes, canvasState] = await Promise.all([
        api.getAccounts(),
        api.getResources(),
        api.getExpenses(),
        api.getDashboard(),
        loadCanvasState(),
      ]);

      setDashboard(dashboardRes.data);
      setAccounts(accountsRes.data);

      console.log('Canvas state loaded:', canvasState);
      console.log('Canvas nodes:', canvasState?.nodes);

      // Build a map of saved positions from canvas state
      const savedPositions = new Map();
      if (canvasState?.nodes) {
        canvasState.nodes.forEach(node => {
          // For entity nodes, use entity_id directly as key
          // For widget nodes (no entity_id), use node_type
          const key = node.entity_id !== null && node.entity_id !== undefined
            ? `${node.node_type}-${node.entity_id}`
            : node.node_type;
          savedPositions.set(key, node);
          console.log('Saved position for:', key, node.position);
        });
      }

      // Create account nodes with saved positions
      const accountNodes = accountsRes.data.map((account, index) => {
        const key = `account-${account.id}`;
        const savedNode = savedPositions.get(key);
        const position = savedNode?.position || { x: 100 + index * 250, y: 100 };
        console.log(`Account ${account.id} (key: ${key}) position:`, position, savedNode ? '(from saved)' : '(default)');
        return {
          id: account.id,
          type: 'account',
          position: position,
          data: account,
        };
      });

      // Create resource nodes with saved positions
      const resourceNodes = resourcesRes.data.map((resource, index) => {
        const key = `resource-${resource.id}`;
        const savedNode = savedPositions.get(key);
        const position = savedNode?.position || { x: 100 + index * 220, y: 350 };
        console.log(`Resource ${resource.id} (key: ${key}) position:`, position, savedNode ? '(from saved)' : '(default)');
        return {
          id: resource.id,
          type: 'resource',
          position: position,
          data: resource,
        };
      });

      // Calculate total expenses
      const totalExpenses = expensesRes.data.reduce((sum, expense) => 
        sum + parseFloat(expense.total_amount || 0), 0
      );

      // Create single expense node with saved position
      // This is a widget node, so look it up by node_type only
      const savedExpenseNode = savedPositions.get('total_expenses');  // Changed from 'expense'
      const expensePosition = savedExpenseNode?.position || { x: 100, y: 600 };
      console.log('Expense node (key: total_expenses) position:', expensePosition, savedExpenseNode ? '(from saved)' : '(default)');
      const expenseNode = {
        id: 'total-expenses',
        type: 'expense',
        position: expensePosition,
        data: {
          total_expenses: totalExpenses,
          expense_count: expensesRes.data.length,
        },
      };

      const allNodes = [...accountNodes, ...resourceNodes, expenseNode];
      console.log('Setting nodes:', allNodes.length, 'nodes');
      setNodes(allNodes);

      // Load saved edges if any
      if (canvasState?.edges) {
        const restoredEdges = canvasState.edges.map((edge, index) => ({
          id: `edge-${index}`,
          source: edge.source_entity_id || `widget-${edge.source_node_type}`,
          target: edge.target_entity_id || `widget-${edge.target_node_type}`,
          animated: edge.edge_metadata?.animated,
          label: edge.edge_metadata?.label,
          style: edge.edge_metadata?.style,
        }));
        console.log('Setting edges:', restoredEdges.length, 'edges');
        setEdges(restoredEdges);
      }

      // Restore viewport (zoom/pan) after nodes are set
      if (canvasState?.viewport) {
        console.log('Restoring viewport:', canvasState.viewport);
        // Use setTimeout to ensure nodes are rendered first
        setTimeout(() => {
          setViewport(canvasState.viewport);
        }, 100);
      }
    } catch (error) {
      console.error('Failed to load data:', error);
    }
  };

  const handleCreateAccount = async (formData) => {
    try {
      const response = await api.createAccount(formData);
      const newNode = {
        id: response.data.id,
        type: 'account',
        position: { x: 100 + nodes.filter(n => n.type === 'account').length * 250, y: 100 },
        data: response.data,
      };
      setNodes((nds) => [...nds, newNode]);
      setShowAccountModal(false);
      debouncedSave(); // Save after adding node
    } catch (error) {
      console.error('Failed to create account:', error);
      alert('Failed to create account');
    }
  };

  const handleCreateResource = async (formData) => {
    try {
      const response = await api.createResource(formData);
      const newNode = {
        id: response.data.id,
        type: 'resource',
        position: { x: 100 + nodes.filter(n => n.type === 'resource').length * 220, y: 350 },
        data: response.data,
      };
      setNodes((nds) => [...nds, newNode]);
      setShowResourceModal(false);
      debouncedSave(); // Save after adding node
    } catch (error) {
      console.error('Failed to create resource:', error);
      alert('Failed to create resource');
    }
  };

  const handleDeposit = async (depositData) => {
    try {
      await api.deposit(depositData);
      setShowDepositModal(false);
      setSelectedAccount(null);
      loadData(); // Reload to get updated balances
    } catch (error) {
      console.error('Failed to record deposit:', error);
      alert('Failed to record deposit');
    }
  };

  const handlePurchase = async (purchaseData) => {
    try {
      await api.createExpenseWithPayment(purchaseData);
      
      // Trigger flow animation
      triggerFlowAnimation(
        purchaseData.account_id,
        selectedResource.id,
        purchaseData.amount
      );
      
      setShowSupplyActionsModal(false);
      setSelectedResource(null);
      loadData();
    } catch (error) {
      console.error('Failed to record purchase:', error);
      const errorMsg = error.message || 'Failed to record purchase';
      alert(errorMsg.includes('current_balance') 
        ? 'Insufficient funds in the selected account. Please deposit money first.' 
        : errorMsg);
    }
  };

  const handleUsage = async (usageData) => {
    try {
      await api.recordSupplyUsage(selectedResource.id, usageData);
      setShowSupplyActionsModal(false);
      setSelectedResource(null);
      loadData();
    } catch (error) {
      console.error('Failed to record usage:', error);
      alert('Failed to record usage');
    }
  };

  const onNodeClick = useCallback((event, node) => {
    if (node.type === 'account') {
      setSelectedAccount(node.data);
      setShowDepositModal(true);
    } else if (node.type === 'resource' && node.data.resource_category === 'supply') {
      setSelectedResource(node.data);
      setShowSupplyActionsModal(true);
    }
  }, []);

  // Custom onNodesChange handler to trigger save
  const handleNodesChange = useCallback((changes) => {
    onNodesChange(changes);
    // Check if any change is a position change
    const hasPositionChange = changes.some(change => change.type === 'position' && change.dragging === false);
    if (hasPositionChange) {
      debouncedSave();
    }
  }, [onNodesChange, debouncedSave]);

  // Custom onEdgesChange handler to trigger save
  const handleEdgesChange = useCallback((changes) => {
    onEdgesChange(changes);
    // Save when edges are added or removed
    const hasEdgeChange = changes.some(change => change.type === 'add' || change.type === 'remove');
    if (hasEdgeChange) {
      debouncedSave();
    }
  }, [onEdgesChange, debouncedSave]);

  // Handle viewport changes (zoom/pan)
  const handleMoveEnd = useCallback(() => {
    debouncedSave();
  }, [debouncedSave]);

  return (
    <div className="w-full h-full">
      {/* Toolbar */}
      <div className="absolute top-4 left-4 z-10 flex gap-2">
        <button
          onClick={() => { setShowAccountModal(true); }}
          className="px-4 py-2 bg-blue-500 text-white rounded-lg shadow-lg hover:bg-blue-600 cursor-pointer" 
        >
          + Add Account
        </button>
        <button
          onClick={() => setShowResourceModal(true)}
          className="px-4 py-2 bg-orange-500 text-white rounded-lg shadow-lg hover:bg-orange-600"
        >
          + Add Resource
        </button>
      </div>

      {/* Dashboard Summary */}
      {dashboard && (
        <div className="absolute top-4 right-4 z-10 shadow-lg ">
          <div className="bg-white rounded-lg p-4 min-w-[250px]">
            <h3 className="font-bold text-lg mb-2">💰 Dashboard</h3>
            <div className="space-y-1 text-sm">
              <div className="flex justify-between">
                <span>Total Balance:</span>
                <span className="font-bold">${dashboard.total_balance?.toLocaleString('en-US', { minimumFractionDigits: 2 })}</span>
              </div>
              <div className="flex justify-between text-green-600">
                <span>Cash In:</span>
                <span>+${dashboard.total_cash_in?.toLocaleString()}</span>
              </div>
              <div className="flex justify-between text-red-600">
                <span>Cash Out:</span>
                <span>-${dashboard.total_cash_out?.toLocaleString()}</span>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* React Flow Canvas */}
      <ReactFlow
        nodes={nodes}
        edges={edges}
        onNodesChange={handleNodesChange}
        onEdgesChange={handleEdgesChange}
        onConnect={onConnect}
        onNodeClick={onNodeClick}
        onMoveEnd={handleMoveEnd}
        nodeTypes={nodeTypes}
        edgeTypes={edgeTypes}
        defaultEdgeOptions={{ type: 'animated' }}
      >
        <Background />
        <Controls />
        <MiniMap />
      </ReactFlow>

      {/* Modals */}
      <CreateAccountModal
        isOpen={showAccountModal}
        onClose={() => setShowAccountModal(false)}
        onSubmit={handleCreateAccount}
      />
      <CreateResourceModal
        isOpen={showResourceModal}
        onClose={() => setShowResourceModal(false)}
        onSubmit={handleCreateResource}
      />
      <DepositModal
        isOpen={showDepositModal}
        onClose={() => {
          setShowDepositModal(false);
          setSelectedAccount(null);
        }}
        onSubmit={handleDeposit}
        account={selectedAccount}
      />
      <SupplyActionsModal
        isOpen={showSupplyActionsModal}
        onClose={() => {
          setShowSupplyActionsModal(false);
          setSelectedResource(null);
        }}
        resource={selectedResource}
        accounts={accounts}
        onPurchase={handlePurchase}
        onUsage={handleUsage}
      />
    </div>
  );
}

export default App;
