import { useState } from 'react';

export default function CreateAccountModal({ isOpen, onClose, onSubmit }) {
  const [formData, setFormData] = useState({
    name: '',
    account_type: 'bank_account',
    bank_name: '',
    account_number: '',
  });

  if (!isOpen) return null;

  const handleSubmit = (e) => {
    e.preventDefault();
    onSubmit(formData);
    setFormData({ name: '', account_type: 'bank_account', bank_name: '', account_number: '' });
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-[9999]">
      <div className="bg-white rounded-lg p-6 w-full max-w-md">
        <h2 className="text-2xl font-bold mb-4">Add Account</h2>
        
        <form onSubmit={handleSubmit}>
          <div className="mb-4">
            <label className="block text-sm font-medium mb-1">Account Type</label>
            <select
              value={formData.account_type}
              onChange={(e) => setFormData({ ...formData, account_type: e.target.value })}
              className="w-full border rounded px-3 py-2"
            >
              <option value="bank_account">🏦 Bank Account</option>
              <option value="cash_at_hand">💵 Cash at Hand</option>
              <option value="funding_line">💰 Funding Line</option>
            </select>
          </div>

          <div className="mb-4">
            <label className="block text-sm font-medium mb-1">Account Name</label>
            <input
              type="text"
              value={formData.name}
              onChange={(e) => setFormData({ ...formData, name: e.target.value })}
              className="w-full border rounded px-3 py-2"
              placeholder="Main Business Account"
              required
            />
          </div>

          {formData.account_type === 'bank_account' && (
            <>
              <div className="mb-4">
                <label className="block text-sm font-medium mb-1">Bank Name</label>
                <input
                  type="text"
                  value={formData.bank_name}
                  onChange={(e) => setFormData({ ...formData, bank_name: e.target.value })}
                  className="w-full border rounded px-3 py-2"
                  placeholder="First National Bank"
                />
              </div>

              <div className="mb-4">
                <label className="block text-sm font-medium mb-1">Account Number</label>
                <input
                  type="text"
                  value={formData.account_number}
                  onChange={(e) => setFormData({ ...formData, account_number: e.target.value })}
                  className="w-full border rounded px-3 py-2"
                  placeholder="1234567890"
                />
              </div>
            </>
          )}

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
              className="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600"
            >
              Create Account
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
