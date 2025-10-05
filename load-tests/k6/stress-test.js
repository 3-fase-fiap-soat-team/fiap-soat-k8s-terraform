import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

// Custom metrics
export let errorRate = new Rate('errors');

// Test configuration
export let options = {
  stages: [
    { duration: '1m', target: 10 },   // Ramp up to 10 users
    { duration: '3m', target: 50 },   // Stay at 50 users
    { duration: '2m', target: 100 },  // Ramp up to 100 users (stress)
    { duration: '1m', target: 0 },    // Ramp down to 0 users
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'],  // 95% of requests under 500ms
    http_req_failed: ['rate<0.01'],    // Error rate under 1%
    errors: ['rate<0.01'],             // Custom error rate under 1%
  },
};

const BASE_URL = __ENV.TARGET_URL || 'http://localhost:3000';

// Test data
const testCustomers = [
  { cpf: '12345678901', name: 'João Silva', email: 'joao@test.com' },
  { cpf: '98765432100', name: 'Maria Santos', email: 'maria@test.com' },
  { cpf: '11122233344', name: 'Pedro Oliveira', email: 'pedro@test.com' },
];

const productIds = ['1', '2', '3', '4', '5'];

export function setup() {
  console.log('🚀 Starting FIAP SOAT Load Test');
  console.log(`🎯 Target: ${BASE_URL}`);
  
  // Health check before starting
  let healthResponse = http.get(`${BASE_URL}/health`);
  if (healthResponse.status !== 200) {
    console.error('❌ Health check failed - aborting test');
    return {};
  }
  console.log('✅ Health check passed');
  
  return { baseUrl: BASE_URL };
}

export default function(data) {
  let response;
  
  // 1. Health Check (10% of requests)
  if (Math.random() < 0.1) {
    response = http.get(`${data.baseUrl}/health`);
    check(response, {
      'health check status is 200': (r) => r.status === 200,
      'health check has status property': (r) => r.json().hasOwnProperty('status'),
    }) || errorRate.add(1);
  }
  
  // 2. Product browsing (40% of requests)  
  if (Math.random() < 0.4) {
    // List products
    response = http.get(`${data.baseUrl}/products`);
    check(response, {
      'products list status is 200': (r) => r.status === 200,
      'products response has products array': (r) => Array.isArray(r.json().products),
    }) || errorRate.add(1);
    
    sleep(1);
    
    // Get specific product
    let productId = productIds[Math.floor(Math.random() * productIds.length)];
    response = http.get(`${data.baseUrl}/products/${productId}`);
    check(response, {
      'product detail status is 200 or 404': (r) => r.status === 200 || r.status === 404,
    }) || errorRate.add(1);
  }
  
  // 3. Authentication flow (25% of requests)
  if (Math.random() < 0.25) {
    let customer = testCustomers[Math.floor(Math.random() * testCustomers.length)];
    
    let loginPayload = JSON.stringify({
      cpf: customer.cpf
    });
    
    let loginParams = {
      headers: { 'Content-Type': 'application/json' },
    };
    
    response = http.post(`${data.baseUrl}/auth/login`, loginPayload, loginParams);
    let loginCheck = check(response, {
      'login status is 200 or 401': (r) => r.status === 200 || r.status === 401,
    });
    
    if (!loginCheck) errorRate.add(1);
    
    // If login successful, try to get profile
    if (response.status === 200) {
      let token = response.json().token;
      if (token) {
        let profileParams = {
          headers: { 'Authorization': `Bearer ${token}` },
        };
        
        response = http.get(`${data.baseUrl}/auth/profile`, profileParams);
        check(response, {
          'profile status is 200': (r) => r.status === 200,
        }) || errorRate.add(1);
      }
    }
  }
  
  // 4. Order creation flow (20% of requests)
  if (Math.random() < 0.2) {
    let orderPayload = JSON.stringify({
      items: [
        {
          productId: productIds[Math.floor(Math.random() * productIds.length)],
          quantity: Math.floor(Math.random() * 3) + 1
        }
      ],
      customerId: Math.floor(Math.random() * 100) + 1
    });
    
    let orderParams = {
      headers: { 'Content-Type': 'application/json' },
    };
    
    response = http.post(`${data.baseUrl}/orders`, orderPayload, orderParams);
    let orderCheck = check(response, {
      'order creation status is 200, 201, 400 or 401': (r) => 
        r.status === 200 || r.status === 201 || r.status === 400 || r.status === 401,
    });
    
    if (!orderCheck) errorRate.add(1);
    
    // If order created successfully, check status
    if (response.status === 200 || response.status === 201) {
      let orderId = response.json().id;
      if (orderId) {
        sleep(0.5);
        response = http.get(`${data.baseUrl}/orders/${orderId}`);
        check(response, {
          'order status check is 200 or 404': (r) => r.status === 200 || r.status === 404,
        }) || errorRate.add(1);
      }
    }
  }
  
  // 5. Customer management (5% of requests)
  if (Math.random() < 0.05) {
    response = http.get(`${data.baseUrl}/customers`);
    check(response, {
      'customers list status is 200 or 401': (r) => r.status === 200 || r.status === 401,
    }) || errorRate.add(1);
  }
  
  // Random think time between 0.5 and 3 seconds
  sleep(Math.random() * 2.5 + 0.5);
}

export function teardown(data) {
  console.log('📊 Load test completed');
  console.log('🔍 Check the results for performance metrics');
}
