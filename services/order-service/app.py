from flask import Flask, jsonify, request
import uuid
import datetime

app = Flask(__name__)

# In-memory store (DynamoDB baad mein add karenge)
orders = {}

@app.route('/health', methods=['GET'])
def health():
    return jsonify({"status": "healthy", "service": "order-service"}), 200

@app.route('/orders', methods=['GET'])
def get_orders():
    return jsonify({"orders": list(orders.values())}), 200

@app.route('/orders', methods=['POST'])
def create_order():
    data = request.get_json()
    order_id = str(uuid.uuid4())
    order = {
        "order_id": order_id,
        "item": data.get("item"),
        "quantity": data.get("quantity"),
        "status": "pending",
        "created_at": datetime.datetime.utcnow().isoformat()
    }
    orders[order_id] = order
    return jsonify({"message": "Order created", "order": order}), 201

@app.route('/orders/<order_id>', methods=['GET'])
def get_order(order_id):
    order = orders.get(order_id)
    if not order:
        return jsonify({"error": "Order not found"}), 404
    return jsonify(order), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)