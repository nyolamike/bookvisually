import { useState } from 'react';

export default function SupplyActionsModal({ isOpen, onClose, resource, accounts = [], onPurchase, onUsage }) {
  const [action, setAction] = useState(null);
  const [formData, setFormData] = useState({
    quantity: '',
    unit_cost: '',
    paid_from_account_id: '',
    vendor: '',
    used_by: '',
    description: '',
  });

  if (!isOpen) return null;

  const handleSubmit = (e) => {
    e.preventDefault();
    
    if (action === 'purchase') {
      onPurchase({
        resource_id: resource.id,
        expense_date: new Date().toISOString(),
        unit_cost: parseFloat(formData.unit_cost),
        quantity: parseFloat(formData.quantity),
        unit_of_measure: resource.default_unit_of_measure,
        paid_from_account_id: formData.paid_from_account_id,
        vendor: formData.vendor,
        description: formData.description || `Purchase ${resource.name}`,
      });
    } else if (action === 'usage') {
      onUsage({
        quantity: parseFloat(formData.quantity),
        used_by: formData.used_by,
        description: formData.description,
        movement_date: new Date().toISOString(),
      });
    }

    setAction(null);
    setFormData({
      quantity: '',
      unit_cost: '',
      paid_from_account_id: '',
      vendor: '',
      used_by: '',
      description: '',
    });
  };

  const renderActionMenu = () => (
    <div className="space-y-3">
      <h2 className="text-2xl font-bold mb-4">📦 {resource.name}</h2>
      
      <div className="bg-gray-50 p-3 rounded">
        <div className="text-sm text-gray-600">Current Stock</div>
        <div className="text-2xl font-bold">
          {resource.supply_properties?.current_stock_quantity || 0} {resource.default_unit_of_measure}
        </div>
        <div className="text-sm">
          Status: <span className={`font-medium ${
            resource.supply_properties?.stock_status === 'in_stock' ? 'text-green-600' :
            resource.supply_properties?.stock_status === 'low_stock' ? 'text-yellow-600' :
            'text-red-600'
          }`}>
            {resource.supply_properties?.stock_status?.replace('_', ' ')}
          </span>
        </div>
      </div>

      <button
        onClick={() => setAction('purchase')}
        className="w-full px-4 py-3 bg-green-500 text-white rounded-lg hover:bg-green-600 text-left"
      >
        📥 Purchase More Stock
      </button>
      
      <button
        onClick={() => setAction('usage')}
        className="w-full px-4 py-3 bg-orange-500 text-white rounded-lg hover:bg-orange-600 text-left"
      >
        📤 Record Usage
      </button>
      
      <button
        onClick={onClose}
        className="w-full px-4 py-3 border rounded-lg hover:bg-gray-100"
      >
        Cancel
      </button>
    </div>
  );

  const renderPurchaseForm = () => (
    <form onSubmit={handleSubmit}>
      <h2 className="text-2xl font-bold mb-4">📥 Purchase {resource.name}</h2>
      
      <div className="mb-4">
        <label className="block text-sm font-medium mb-1">Quantity ({resource.default_unit_of_measure})</label>
        <input
          type="number"
          step="0.01"
          value={formData.quantity}
          onChange={(e) => setFormData({ ...formData, quantity: e.target.value })}
          className="w-full border rounded px-3 py-2"
          placeholder="100"
          required
        />
      </div>

      <div className="mb-4">
        <label className="block text-sm font-medium mb-1">Unit Cost</label>
        <input
          type="number"
          step="0.01"
          value={formData.unit_cost}
          onChange={(e) => setFormData({ ...formData, unit_cost: e.target.value })}
          className="w-full border rounded px-3 py-2"
          placeholder="8.50"
          required
        />
      </div>

      {formData.quantity && formData.unit_cost && (
        <div className="mb-4 p-3 bg-blue-50 rounded">
          <div className="text-sm text-gray-600">Total Cost</div>
          <div className="text-xl font-bold">
            ${(parseFloat(formData.quantity) * parseFloat(formData.unit_cost)).toFixed(2)}
          </div>
        </div>
      )}

      <div className="mb-4">
        <label className="block text-sm font-medium mb-1">Pay From Account</label>
        <select
          value={formData.paid_from_account_id}
          onChange={(e) => setFormData({ ...formData, paid_from_account_id: e.target.value })}
          className="w-full border rounded px-3 py-2"
          required
        >
          <option value="">Select account</option>
          {accounts && accounts.length > 0 ? (
            accounts.map(account => {
              const balance = parseFloat(account.current_balance || 0);
              const totalCost = formData.quantity && formData.unit_cost 
                ? parseFloat(formData.quantity) * parseFloat(formData.unit_cost) 
                : 0;
              const insufficient = totalCost > balance;
              
              return (
                <option key={account.id} value={account.id}>
                  {account.name} - Balance: ${balance.toFixed(2)}
                  {insufficient && totalCost > 0 ? ' (Insufficient funds)' : ''}
                </option>
              );
            })
          ) : (
            <option value="" disabled>No accounts available</option>
          )}
        </select>
        {accounts && accounts.length === 0 && (
          <p className="text-sm text-red-500 mt-1">Please create an account first</p>
        )}
        {formData.paid_from_account_id && formData.quantity && formData.unit_cost && (() => {
          const selectedAccount = accounts.find(a => a.id === formData.paid_from_account_id);
          const balance = parseFloat(selectedAccount?.current_balance || 0);
          const totalCost = parseFloat(formData.quantity) * parseFloat(formData.unit_cost);
          return totalCost > balance ? (
            <p className="text-sm text-red-500 mt-1">
              ⚠️ Insufficient funds. Account balance: ${balance.toFixed(2)}, Required: ${totalCost.toFixed(2)}
            </p>
          ) : null;
        })()}
      </div>

      <div className="mb-4">
        <label className="block text-sm font-medium mb-1">Vendor</label>
        <input
          type="text"
          value={formData.vendor}
          onChange={(e) => setFormData({ ...formData, vendor: e.target.value })}
          className="w-full border rounded px-3 py-2"
          placeholder="BuildMart"
        />
      </div>

      <div className="mb-4">
        <label className="block text-sm font-medium mb-1">Notes</label>
        <input
          type="text"
          value={formData.description}
          onChange={(e) => setFormData({ ...formData, description: e.target.value })}
          className="w-full border rounded px-3 py-2"
          placeholder="Optional notes"
        />
      </div>

      <div className="flex gap-2 justify-end">
        <button
          type="button"
          onClick={() => setAction(null)}
          className="px-4 py-2 border rounded hover:bg-gray-100"
        >
          Back
        </button>
        <button
          type="submit"
          className="px-4 py-2 bg-green-500 text-white rounded hover:bg-green-600"
        >
          Record Purchase
        </button>
      </div>
    </form>
  );

  const renderUsageForm = () => (
    <form onSubmit={handleSubmit}>
      <h2 className="text-2xl font-bold mb-4">📤 Record Usage - {resource.name}</h2>
      
      <div className="mb-4">
        <label className="block text-sm font-medium mb-1">Quantity Used ({resource.default_unit_of_measure})</label>
        <input
          type="number"
          step="0.01"
          value={formData.quantity}
          onChange={(e) => setFormData({ ...formData, quantity: e.target.value })}
          className="w-full border rounded px-3 py-2"
          placeholder="30"
          required
        />
      </div>

      <div className="mb-4">
        <label className="block text-sm font-medium mb-1">Used By</label>
        <input
          type="text"
          value={formData.used_by}
          onChange={(e) => setFormData({ ...formData, used_by: e.target.value })}
          className="w-full border rounded px-3 py-2"
          placeholder="Foundation Team"
          required
        />
      </div>

      <div className="mb-4">
        <label className="block text-sm font-medium mb-1">Description</label>
        <input
          type="text"
          value={formData.description}
          onChange={(e) => setFormData({ ...formData, description: e.target.value })}
          className="w-full border rounded px-3 py-2"
          placeholder="Johnson House Foundation"
        />
      </div>

      <div className="flex gap-2 justify-end">
        <button
          type="button"
          onClick={() => setAction(null)}
          className="px-4 py-2 border rounded hover:bg-gray-100"
        >
          Back
        </button>
        <button
          type="submit"
          className="px-4 py-2 bg-orange-500 text-white rounded hover:bg-orange-600"
        >
          Record Usage
        </button>
      </div>
    </form>
  );

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-[9999]">
      <div className="bg-white rounded-lg p-6 w-full max-w-md max-h-[90vh] overflow-y-auto">
        {!action && renderActionMenu()}
        {action === 'purchase' && renderPurchaseForm()}
        {action === 'usage' && renderUsageForm()}
      </div>
    </div>
  );
}
