const API_BASE_URL = 'http://localhost:4000/api';

class ApiClient {
  async request(endpoint, options = {}) {
    const url = `${API_BASE_URL}${endpoint}`;
    const config = {
      headers: {
        'Content-Type': 'application/json',
        ...options.headers,
      },
      ...options,
    };

    if (config.body && typeof config.body === 'object') {
      config.body = JSON.stringify(config.body);
    }

    const response = await fetch(url, config);
    
    if (!response.ok) {
      const error = await response.json().catch(() => ({ errors: { detail: 'Request failed' } }));
      throw new Error(error.errors?.detail || 'Request failed');
    }

    return response.json();
  }

  // Accounts
  getAccounts() {
    return this.request('/accounts');
  }

  createAccount(data) {
    return this.request('/accounts', {
      method: 'POST',
      body: { account: data },
    });
  }

  // Transactions
  deposit(data) {
    return this.request('/transactions/deposit', {
      method: 'POST',
      body: data,
    });
  }

  withdraw(data) {
    return this.request('/transactions/withdrawal', {
      method: 'POST',
      body: data,
    });
  }

  transfer(data) {
    return this.request('/transactions/transfer', {
      method: 'POST',
      body: data,
    });
  }

  // Resources
  getResources(category = null) {
    const query = category ? `?category=${category}` : '';
    return this.request(`/resources${query}`);
  }

  createResource(data) {
    return this.request('/resources', {
      method: 'POST',
      body: { resource: data },
    });
  }

  // Dashboard
  getDashboard() {
    return this.request('/dashboard');
  }

  // Expenses
  getExpenses(params = {}) {
    const query = new URLSearchParams(params).toString();
    return this.request(`/expenses${query ? '?' + query : ''}`);
  }

  createExpenseWithPayment(data) {
    return this.request('/expenses/with-payment', {
      method: 'POST',
      body: data,
    });
  }

  // Supply movements
  recordSupplyUsage(supplyId, data) {
    return this.request(`/supplies/${supplyId}/movements/usage`, {
      method: 'POST',
      body: data,
    });
  }

  // Bills
  payBill(billId, data) {
    return this.request(`/bills/${billId}/pay`, {
      method: 'POST',
      body: data,
    });
  }

  // Canvas State
  getCanvasState(name) {
    return this.request(`/canvas/${name}`);
  }

  saveCanvasState(data) {
    return this.request('/canvas', {
      method: 'POST',
      body: data,
    });
  }

  updateNodePositions(canvasId, nodes) {
    return this.request(`/canvas/${canvasId}/nodes`, {
      method: 'PATCH',
      body: { nodes },
    });
  }
}

export default new ApiClient();
