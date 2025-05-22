from flask import Flask, request, jsonify
import joblib
import numpy as np
import os
import sys

app = Flask(__name__)

# Configure model path for Vercel
MODEL_PATH = os.path.join(os.path.dirname(__file__), 'fast_phish_model.joblib')

# Enhanced model loading
try:
    model = joblib.load(MODEL_PATH)
    print("✅ Model loaded successfully", file=sys.stderr)
    print(f"Model classes: {model.classes_}", file=sys.stderr)  # Debug output
except Exception as e:
    print(f"❌ Model load failed: {str(e)}", file=sys.stderr)
    print(f"Current directory: {os.listdir()}", file=sys.stderr)  # Debug directory contents
    model = None

@app.route('/')
def home():
    return jsonify({
        "status": "Phishing Detection API",
        "model_loaded": bool(model),
        "endpoint": "POST /api/predict"
    })

@app.route('/api/predict', methods=['POST'])
def predict():
    if not model:
        return jsonify({
            "error": "Model not loaded",
            "debug": {"files": os.listdir()}
        }), 500
        
    try:
        data = request.get_json()
        if not data or 'features' not in data:
            return jsonify({"error": "Missing features in request"}), 400
        
        # Validate features
        features = []
        for i in range(47):
            feature_name = f'feature_{i}'
            if feature_name not in data['features']:
                return jsonify({
                    "error": f"Missing feature: {feature_name}",
                    "required_features": [f"feature_{x}" for x in range(47)]
                }), 400
            features.append(float(data['features'][feature_name]))
        
        features = np.array(features).reshape(1, -1)
        
        # Debug output
        print(f"Input features: {features}", file=sys.stderr)
        
        prediction = int(model.predict(features)[0])
        proba = model.predict_proba(features)[0]
        confidence = float(proba[prediction])
        
        return jsonify({
            "prediction": prediction,
            "confidence": round(confidence, 4),
            "class_probabilities": {
                str(cls): float(prob) for cls, prob in zip(model.classes_, proba)
            },
            "status": "success"
        })
        
    except Exception as e:
        print(f"Prediction error: {str(e)}", file=sys.stderr)
        return jsonify({
            "error": "Prediction failed",
            "details": str(e),
            "traceback": str(sys.exc_info())
        }), 500

# Vercel serverless handler
def handler(req, res):
    with app.app_context():
        try:
            response = app.full_dispatch_request()
            return {
                'statusCode': response.status_code,
                'headers': dict(response.headers),
                'body': response.get_data().decode('utf-8')
            }
        except Exception as e:
            print(f"Handler error: {str(e)}", file=sys.stderr)
            return {
                'statusCode': 500,
                'body': jsonify({
                    "error": "Internal server error",
                    "details": str(e)
                }).get_data().decode('utf-8')
            }
