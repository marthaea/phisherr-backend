from flask import Flask, jsonify
import joblib
import numpy as np

app = Flask(__name__)

# Mock model - replace with your actual model later
class MockModel:
    def predict(self, X):
        return [1]  # Always predicts phishing
    def predict_proba(self, X):
        return [[0.3, 0.7]]  # Fake confidence

model = MockModel()

@app.route('/api/predict', methods=['POST'])
def predict():
    try:
        features = request.json['features']
        features = np.array(list(features.values())).reshape(1, -1)
        return jsonify({
            "prediction": int(model.predict(features)[0]),
            "confidence": float(model.predict_proba(features)[0][1])
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run()