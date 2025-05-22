from flask import Flask, request, jsonify
import joblib
import numpy as np
import os

app = Flask(__name__)

# Load model
MODEL_PATH = os.path.join(os.path.dirname(__file__), 'fast_phish_model.joblib')
try:
    model = joblib.load(MODEL_PATH)
    print("✅ Model loaded successfully")
except Exception as e:
    print(f"❌ Model loading failed: {str(e)}")
    model = None

@app.route('/api/predict', methods=['POST'])
def predict():
    if model is None:
        return jsonify({"error": "Model not loaded"}), 500
        
    try:
        data = request.json
        features = data.get('features', {})
        
        # Convert features to array in correct order
        feature_array = np.array([features[f"feature_{i}"] for i in range(47)]).reshape(1, -1)
        
        prediction = int(model.predict(feature_array)[0])
        confidence = float(model.predict_proba(feature_array)[0][prediction])
        
        return jsonify({
            "prediction": prediction,
            "confidence": round(confidence, 4),
            "status": "success"
        })
        
    except Exception as e:
        return jsonify({"error": str(e)}), 400

def handler(req, res):
    with app.app_context():
        response = app.full_dispatch_request()
        res.status(response.status_code)
        for k, v in response.headers:
            res.set_header(k, v)
        return response.data
