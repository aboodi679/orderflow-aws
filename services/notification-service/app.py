from flask import Flask, jsonify

app = Flask(__name__)

notifications = []

@app.route('/health', methods=['GET'])
def health():
    return jsonify({
        "status": "healthy",
        "service": "notification-service"
    }), 200

@app.route('/notifications', methods=['GET'])
def get_notifications():
    return jsonify({
        "notifications": notifications
    }), 200

@app.route('/notifications/test', methods=['POST'])
def send_test_notification():

    notification = {
        "message": "Test notification sent"
    }

    notifications.append(notification)

    return jsonify(notification), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5002)