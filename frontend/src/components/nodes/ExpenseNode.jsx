import { Handle, Position } from '@xyflow/react';

export default function ExpenseNode({ data }) {
  return (
    <div className="px-4 py-3 rounded-lg shadow-lg border-2 border-red-500 bg-red-50 min-w-[180px]">
      <Handle type="target" position={Position.Top} className="w-3 h-3" />
      
      <div className="flex items-center gap-2 mb-2">
        <span className="text-2xl">💸</span>
        <div className="flex-1">
          <div className="font-semibold text-gray-800">Total Expenses</div>
          <div className="text-xs text-gray-500">All time</div>
        </div>
      </div>
      
      <div className="text-lg font-bold text-red-600">
        -${parseFloat(data.total_expenses || 0).toLocaleString('en-US', { minimumFractionDigits: 2 })}
      </div>
      
      {data.expense_count > 0 && (
        <div className="text-xs text-gray-600 mt-1">
          {data.expense_count} transaction{data.expense_count !== 1 ? 's' : ''}
        </div>
      )}

      <Handle type="source" position={Position.Bottom} className="w-3 h-3" />
    </div>
  );
}
