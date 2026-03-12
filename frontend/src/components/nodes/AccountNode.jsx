import { Handle, Position } from '@xyflow/react';

export default function AccountNode({ data }) {
  const getIcon = () => {
    switch (data.account_type) {
      case 'bank_account': return '🏦';
      case 'cash_at_hand': return '💵';
      case 'funding_line': return '💰';
      default: return '💳';
    }
  };

  const getStatusColor = () => {
    if (data.status === 'closed') return 'bg-gray-400';
    if (data.status === 'frozen') return 'bg-yellow-400';
    return 'bg-blue-500';
  };

  return (
    <div className={`px-4 py-3 rounded-lg shadow-lg border-2 ${getStatusColor()} border-opacity-50 bg-white min-w-[200px]`}>
      <Handle type="target" position={Position.Top} className="w-3 h-3" />
      
      <div className="flex items-center gap-2 mb-2">
        <span className="text-2xl">{getIcon()}</span>
        <div className="flex-1">
          <div className="font-semibold text-gray-800">{data.name}</div>
          {data.bank_name && (
            <div className="text-xs text-gray-500">{data.bank_name}</div>
          )}
        </div>
      </div>
      
      <div className="text-right">
        <div className="text-2xl font-bold text-gray-900">
          ${(data.current_balance || 0).toLocaleString('en-US', { minimumFractionDigits: 2 })}
        </div>
        <div className="text-xs text-gray-500">
          ↑ ${(data.total_cash_in || 0).toLocaleString()} | ↓ ${(data.total_cash_out || 0).toLocaleString()}
        </div>
      </div>

      <Handle type="source" position={Position.Bottom} className="w-3 h-3" />
    </div>
  );
}
