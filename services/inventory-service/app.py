from flask import Flask, jsonify

app = Flask(__name__)

inventory = {
    "laptop": 10,
    "mouse": 50,
    "keyboard": 25
}

@app.route('/health', methods=['GET'])
def health():
    return jsonify({
        "status": "healthy",
        "service": "inventory-service"
    }), 200

@app.route('/inventory', methods=['GET'])
def get_inventory():
    return jsonify({
        "inventory": inventory
    }), 200

@app.route('/inventory/<item>', methods=['GET'])
def check_item(item):
    quantity = inventory.get(item)

    if quantity is None:
        return jsonify({
            "error": "Item not found"
        }), 404

    return jsonify({
        "item": item,
        "available_quantity": quantity
    }), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)