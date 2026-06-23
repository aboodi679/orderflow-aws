# API Reference

Base URL:
```
http://orderflow-alb-1358729812.us-east-1.elb.amazonaws.com
```

---

## Order Service — port 5000

### GET /health

Health check endpoint.

**Response:**
```json
{
  "service": "order-service",
  "status": "healthy"
}
```

### POST /orders

Create a new order. Fires an `order.created` event to EventBridge.

**Request:**
```json
{
  "order_id": "ORD-001",
  "item": "laptop",
  "qty": 1
}
```

**Response:**
```json
{
  "message": "Order created",
  "order_id": "ORD-001"
}
```

---

## Inventory Service — port 5001

### GET /health

Health check endpoint.

**Response:**
```json
{
  "service": "inventory-service",
  "status": "healthy"
}
```

### GET /inventory

Returns current inventory status.

**Response:**
```json
{
  "service": "inventory-service",
  "items": []
}
```

---

## Notification Service — port 5002

### GET /health

Health check endpoint.

**Response:**
```json
{
  "service": "notification-service",
  "status": "healthy"
}
```

### GET /notify

Returns notification queue status.

**Response:**
```json
{
  "service": "notification-service",
  "notifications": []
}
```

---

## Event Flow Test

Manually fire an `order.created` event:

```bash
aws events put-events --entries file://test-event.json --region us-east-1
```

`test-event.json`:
```json
[
  {
    "Source": "orderflow.order-service",
    "DetailType": "order.created",
    "Detail": "{\"order_id\":\"ORD-001\",\"item\":\"laptop\",\"qty\":1}",
    "EventBusName": "default"
  }
]
```

Verify message in inventory queue:

```bash
aws sqs receive-message \
  --queue-url https://sqs.us-east-1.amazonaws.com/026243800492/orderflow-inventory-queue \
  --region us-east-1
```

