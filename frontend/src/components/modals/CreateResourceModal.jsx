import { useState } from 'react';

export default function CreateResourceModal({ isOpen, onClose, onSubmit }) {
  const [formData, setFormData] = useState({
    name: '',
    resource_category: 'supply',
    default_unit_of_measure: '',
    // Supply properties
    out_of_stock_alert_quantity: '',
    issues_out_of_stock_alerts: true,
    current_stock_quantity: 0,
    // Asset properties
    purchase_date: '',
    purchase_cost: '',
    current_value: '',
    // Subscription properties
    vendor: '',
    package_name: '',
    // Utility properties
    bill_type: '',
  });

  if (!isOpen) return null;

  const handleSubmit = (e) => {
    e.preventDefault();
    
    const payload = {
      name: formData.name,
      resource_category: formData.resource_category,
      default_unit_of_measure: formData.default_unit_of_measure,
    };

    // Add category-specific properties
    if (formData.resource_category === 'supply') {
      payload.supply_properties = {
        out_of_stock_alert_quantity: parseFloat(formData.out_of_stock_alert_quantity) || 0,
        issues_out_of_stock_alerts: formData.issues_out_of_stock_alerts,
        current_stock_quantity: parseFloat(formData.current_stock_quantity) || 0,
      };
    } else if (formData.resource_category === 'asset') {
      payload.asset_properties = {
        purchase_date: formData.purchase_date,
        purchase_cost: parseFloat(formData.purchase_cost) || 0,
        current_value: parseFloat(formData.current_value) || 0,
        status: 'in_use',
      };
    } else if (formData.resource_category === 'subscription') {
      payload.subscription_properties = {
        vendor: formData.vendor,
        package_name: formData.package_name,
        status: 'active',
      };
    } else if (formData.resource_category === 'utility') {
      payload.utility_properties = {
        bill_type: formData.bill_type,
      };
    }

    onSubmit(payload);
    setFormData({
      name: '',
      resource_category: 'supply',
      default_unit_of_measure: '',
      out_of_stock_alert_quantity: '',
      issues_out_of_stock_alerts: true,
      current_stock_quantity: 0,
      purchase_date: '',
      purchase_cost: '',
      current_value: '',
      vendor: '',
      package_name: '',
      bill_type: '',
    });
  };

  const renderCategoryFields = () => {
    switch (formData.resource_category) {
      case 'supply':
        return (
          <>
            <div className="mb-4">
              <label className="block text-sm font-medium mb-1">Unit of Measure</label>
              <input
                type="text"
                value={formData.default_unit_of_measure}
                onChange={(e) => setFormData({ ...formData, default_unit_of_measure: e.target.value })}
                className="w-full border rounded px-3 py-2"
                placeholder="bags, liters, units"
                required
              />
            </div>
            <div className="mb-4">
              <label className="block text-sm font-medium mb-1">Current Stock</label>
              <input
                type="number"
                step="0.01"
                value={formData.current_stock_quantity}
                onChange={(e) => setFormData({ ...formData, current_stock_quantity: e.target.value })}
                className="w-full border rounded px-3 py-2"
                placeholder="0"
              />
            </div>
            <div className="mb-4">
              <label className="block text-sm font-medium mb-1">Alert When Below</label>
              <input
                type="number"
                step="0.01"
                value={formData.out_of_stock_alert_quantity}
                onChange={(e) => setFormData({ ...formData, out_of_stock_alert_quantity: e.target.value })}
                className="w-full border rounded px-3 py-2"
                placeholder="20"
              />
            </div>
          </>
        );

      case 'asset':
        return (
          <>
            <div className="mb-4">
              <label className="block text-sm font-medium mb-1">Purchase Date</label>
              <input
                type="date"
                value={formData.purchase_date}
                onChange={(e) => setFormData({ ...formData, purchase_date: e.target.value })}
                className="w-full border rounded px-3 py-2"
              />
            </div>
            <div className="mb-4">
              <label className="block text-sm font-medium mb-1">Purchase Cost</label>
              <input
                type="number"
                step="0.01"
                value={formData.purchase_cost}
                onChange={(e) => setFormData({ ...formData, purchase_cost: e.target.value })}
                className="w-full border rounded px-3 py-2"
                placeholder="5000.00"
              />
            </div>
            <div className="mb-4">
              <label className="block text-sm font-medium mb-1">Current Value</label>
              <input
                type="number"
                step="0.01"
                value={formData.current_value}
                onChange={(e) => setFormData({ ...formData, current_value: e.target.value })}
                className="w-full border rounded px-3 py-2"
                placeholder="5000.00"
              />
            </div>
          </>
        );

      case 'subscription':
        return (
          <>
            <div className="mb-4">
              <label className="block text-sm font-medium mb-1">Vendor</label>
              <input
                type="text"
                value={formData.vendor}
                onChange={(e) => setFormData({ ...formData, vendor: e.target.value })}
                className="w-full border rounded px-3 py-2"
                placeholder="Internet Provider"
              />
            </div>
            <div className="mb-4">
              <label className="block text-sm font-medium mb-1">Package Name</label>
              <input
                type="text"
                value={formData.package_name}
                onChange={(e) => setFormData({ ...formData, package_name: e.target.value })}
                className="w-full border rounded px-3 py-2"
                placeholder="Premium Plan"
              />
            </div>
          </>
        );

      case 'utility':
        return (
          <>
            <div className="mb-4">
              <label className="block text-sm font-medium mb-1">Bill Type</label>
              <select
                value={formData.bill_type}
                onChange={(e) => setFormData({ ...formData, bill_type: e.target.value })}
                className="w-full border rounded px-3 py-2"
              >
                <option value="">Select type</option>
                <option value="water">Water</option>
                <option value="electricity">Electricity</option>
                <option value="gas">Gas</option>
                <option value="internet">Internet</option>
                <option value="rent">Rent</option>
                <option value="other">Other</option>
              </select>
            </div>
          </>
        );

      default:
        return null;
    }
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-[9999]">
      <div className="bg-white rounded-lg p-6 w-full max-w-md max-h-[90vh] overflow-y-auto">
        <h2 className="text-2xl font-bold mb-4">Add Resource</h2>
        
        <form onSubmit={handleSubmit}>
          <div className="mb-4">
            <label className="block text-sm font-medium mb-1">Resource Type</label>
            <select
              value={formData.resource_category}
              onChange={(e) => setFormData({ ...formData, resource_category: e.target.value })}
              className="w-full border rounded px-3 py-2"
            >
              <option value="supply">📦 Supply (inventory)</option>
              <option value="asset">🏗️ Asset (equipment)</option>
              <option value="subscription">📅 Subscription (recurring)</option>
              <option value="utility">📄 Utility (bills)</option>
            </select>
          </div>

          <div className="mb-4">
            <label className="block text-sm font-medium mb-1">Resource Name</label>
            <input
              type="text"
              value={formData.name}
              onChange={(e) => setFormData({ ...formData, name: e.target.value })}
              className="w-full border rounded px-3 py-2"
              placeholder="Cement, Concrete Mixer, etc."
              required
            />
          </div>

          {renderCategoryFields()}

          <div className="flex gap-2 justify-end">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 border rounded hover:bg-gray-100"
            >
              Cancel
            </button>
            <button
              type="submit"
              className="px-4 py-2 bg-orange-500 text-white rounded hover:bg-orange-600"
            >
              Create Resource
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
