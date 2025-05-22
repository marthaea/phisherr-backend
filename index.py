from flask import Flask, request, jsonify
import joblib
import numpy as np
import os

app = Flask(__name__)

# Model loading with error handling
try:
    model = joblib.load('fast_phish_model.joblib')
    print("✅ Model loaded successfully")
except Exception as e:
    print(f"❌ Model load failed: {str(e)}")
    model = None

@app.route('/api/predict', methods=['POST'])
def predict():
    if not model:
        return jsonify({"error": "Model not loaded"}), 500
        
    try:
        data = request.json
        # Convert features to ordered list [feature_0, feature_1...feature_46]
        features = [data['features'][f'feature_{i}'] for i in range(47)]
        features = np.array(features).reshape(1, -1)
        
        prediction = int(model.predict(features)[0])
        confidence = float(model.predict_proba(features)[0][prediction])
        
        return jsonify({
            "prediction": prediction,
            "confidence": round(confidence, 4),
            "status": "success"
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 400

# Vercel requires this wrapper
def handler(request):
    with app.app_context():
        response = app.full_dispatch_request()
        return {
            'statusCode': response.status_code,
            'headers': dict(response.headers),
            'body': response.get_data().decode('utf-8')
        }
