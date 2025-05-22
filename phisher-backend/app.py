from flask import Flask, request, jsonify
from flask_cors import CORS
import pandas as pd
import numpy as np
from joblib import load
import logging
from typing import Dict
import os

app = Flask(__name__)
CORS(app)

# Configuration
MODEL_PATH = 'models/fast_phish_model.joblib'
DATASET_PATH = 'data/url_features.csv'  # Your CSV with features
FEATURE_NAMES = [
    'feature_0', 'feature_1', 'feature_2', 'feature_3', 'feature_4',
    'feature_5', 'feature_6', 'feature_7', 'feature_8', 'feature_9',
    'feature_10', 'feature_11', 'feature_12', 'feature_13', 'feature_14',
    'feature_15', 'feature_16', 'feature_17', 'feature_18', 'feature_19',
    'feature_20', 'feature_21', 'feature_22', 'feature_23', 'feature_24',
    'feature_25', 'feature_26', 'feature_27', 'feature_28', 'feature_29',
    'feature_30', 'feature_31', 'feature_32', 'feature_33', 'feature_34',
    'feature_35', 'feature_36', 'feature_37', 'feature_38', 'feature_39',
    'feature_40', 'feature_41', 'feature_42', 'feature_43', 'feature_44',
    'feature_45', 'feature_46'
]

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def load_resources():
    """Load model and dataset resources"""
    try:
        os.makedirs('models', exist_ok=True)
        os.makedirs('data', exist_ok=True)
        
        model = load(MODEL_PATH)
        dataset = pd.read_csv(DATASET_PATH)
        
        logger.info(f"Model loaded from {MODEL_PATH}")
        logger.info(f"Dataset loaded with {len(dataset)} samples")
        return model, dataset
        
    except Exception as e:
        logger.error(f"Resource loading failed: {str(e)}")
        raise

model, dataset = load_resources()

@app.route('/predict', methods=['POST'])
def predict():
    """Handle prediction requests from frontend"""
    try:
        data = request.get_json()
        
        # Validate input
        if not data or 'features' not in data:
            return jsonify({"error": "Missing features in request"}), 400
            
        # Prepare feature array
        features = []
        for name in FEATURE_NAMES:
            if name in data['features']:
                features.append(float(data['features'][name]))
            else:
                features.append(0.0)  # Default value if feature missing
                
        features = np.array(features).reshape(1, -1)
        
        # Make prediction
        prediction = int(model.predict(features)[0])
        proba = model.predict_proba(features)[0]
        confidence = float(max(proba))
        
        return jsonify({
            "prediction": prediction,
            "confidence": confidence,
            "features_used": {name: val for name, val in zip(FEATURE_NAMES, features[0])}
        })
        
    except Exception as e:
        logger.error(f"Prediction error: {str(e)}")
        return jsonify({"error": "Prediction failed", "details": str(e)}), 500

@app.route('/sample', methods=['GET'])
def get_sample():
    """Return a sample feature vector for testing"""
    try:
        sample = dataset.iloc[0][FEATURE_NAMES].to_dict()
        return jsonify({
            "sample_features": sample,
            "description": "Sample feature vector from dataset"
        })
    except Exception as e:
        logger.error(f"Sample error: {str(e)}")
        return jsonify({"error": "Cannot get sample"}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)