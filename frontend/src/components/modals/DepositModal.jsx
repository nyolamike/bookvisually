import { useState } from 'react';

export default function DepositModal({ isOpen, onClose, onSubmit, account }) {
  const [formData, setFormData] = useState({
    amount: '',
    description: '',
  });

  if (!isOpen) return null;

  const handleSubmit = (e) => {
    e.preventDefault();
    onSubmit({
      to_account_id: account.id,
      amount: parseFloat(formData.amount),
      description: formData.description,
      transaction_date: new Date().toISOString(),
    });
    setFormData({ amount: '', description: '' });
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-[9999]">
      <div className="bg-white rounded-lg p-6 w-full max-w-md">
        <h2 className="text-2xl font-bold mb-4">💰 Deposit to {account?.name}</h2>
        
        <form onSubmit={handleSubmit}>
          <div className="mb-4">
            <label className="block text-sm font-medium mb-1">Amount</label>
            <input
              type="number"
              step="0.01"
              value={formData.amount}
              onChange={(e) => setFormData({ ...formData, amount: e.target.value })}
              className="w-full border rounded px-3 py-2"
              placeholder="0.00"
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
              placeholder="Initial investment"
              required
            />
          </div>

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
              className="px-4 py-2 bg-green-500 text-white rounded hover:bg-green-600"
            >
              Record Deposit
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
