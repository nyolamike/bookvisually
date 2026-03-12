import { Handle, Position } from '@xyflow/react';

export default function ResourceNode({ data }) {
  const getIcon = () => {
    switch (data.resource_category) {
      case 'supply': return '📦';
      case 'asset': return '🏗️';
      case 'subscription': return '📅';
      case 'utility': return '📄';
      default: return '📋';
    }
  };

  const getStatusColor = () => {
    const status = data.supply_properties?.stock_status || 
                   data.asset_properties?.status ||
                   data.subscription_properties?.status;
    
    if (status === 'out_of_stock' || status === 'retired' || status === 'expired') return 'border-red-500 bg-red-50';
    if (status === 'low_stock' || status === 'maintenance' || status === 'expiring_soon') return 'border-yellow-500 bg-yellow-50';
    return 'border-green-500 bg-green-50';
  };

  const getStatusIndicator = () => {
    const status = data.supply_properties?.stock_status;
    if (status === 'out_of_stock') return '🔴';
    if (status === 'low_stock') return '🟡';
    if (status === 'in_stock') return '🟢';
    return '';
  };

  const getDetails = () => {
    if (data.supply_properties) {
      return `${data.supply_properties.current_stock_quantity || 0} ${data.default_unit_of_measure || 'units'}`;
    }
    if (data.asset_properties) {
      return `$${(data.asset_properties.current_value || 0).toLocaleString()}`;
    }
    return '';
  };

  return (
    <div className={`px-4 py-3 rounded-lg shadow-lg border-2 ${getStatusColor()} bg-white min-w-[180px]`}>
      <Handle type="target" position={Position.Top} className="w-3 h-3" />
      
      <div className="flex items-center gap-2 mb-2">
        <span className="text-2xl">{getIcon()}</span>
        <div className="flex-1">
          <div className="font-semibold text-gray-800">{data.name}</div>
          <div className="text-xs text-gray-500 capitalize">{data.resource_category}</div>
        </div>
        {getStatusIndicator() && (
          <span className="text-lg">{getStatusIndicator()}</span>
        )}
      </div>
      
      {getDetails() && (
        <div className="text-sm text-gray-700 font-medium">
          {getDetails()}
        </div>
      )}

      <Handle type="source" position={Position.Bottom} className="w-3 h-3" />
    </div>
  );
}
