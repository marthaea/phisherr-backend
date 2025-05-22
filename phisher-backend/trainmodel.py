import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.feature_extraction.text import TfidfVectorizer
from urllib.parse import urlparse
from scipy.sparse import hstack
import re, math, joblib

def calculate_entropy(text):
    entropy = 0
    for x in range(256):
        p_x = float(text.encode('utf-8').count(bytes([x]))) / len(text)
        if p_x > 0:
            entropy += - p_x * math.log(p_x, 2)
    return entropy

def extract_features(url):
    try:
        parsed = urlparse(url)
        netloc = parsed.netloc or ''
        path = parsed.path or ''
        query = parsed.query or ''
        
        return {
            'length': len(url),
            'num_digits': len(re.findall(r'\d', url)),
            'num_params': len(query.split('&')) if query else 0,
            'has_https': int(parsed.scheme == 'https'),
            'has_ip': int(bool(re.match(r'^\d+\.\d+\.\d+\.\d+$', netloc.split(':')[0]))),
            'num_special': len(re.findall(r'[^\w\s-]', url)),
            'domain_len': len(netloc),
            'path_len': len(path),
            'num_subdomains': len(netloc.split('.')) - 2 if netloc.count('.') >= 2 else 0,
            'has_at_symbol': int('@' in url),
            'has_hyphen': int('-' in netloc),
            'url_entropy': calculate_entropy(url),
            'is_shortened': int(any(x in netloc for x in ['bit.ly', 'goo.gl', 'tinyurl'])),
            'path_has_exe': int('.exe' in path.lower()),
            'has_redirect': int('//' in url.replace('://', '')),
        }
    except:
        return {k: 0 for k in [
            'length', 'num_digits', 'num_params', 'has_https', 'has_ip', 'num_special',
            'domain_len', 'path_len', 'num_subdomains', 'has_at_symbol', 'has_hyphen',
            'url_entropy', 'is_shortened', 'path_has_exe', 'has_redirect'
        ]}

# Load and label data
phishing_df = pd.read_csv('phishing_urls.csv')
legit_df = pd.read_csv('legitimate_urls.csv')
phishing_df['type'] = 'phishing'
legit_df['type'] = 'legitimate'
df = pd.concat([phishing_df, legit_df], ignore_index=True)
df = df.dropna(subset=['url', 'type'])
df['label'] = df['type'].map({'phishing': 1, 'legitimate': 0})

# Feature + text extraction
X = pd.DataFrame([extract_features(url) for url in df['url']])
vectorizer = TfidfVectorizer(ngram_range=(1,3), analyzer='char', max_features=500)
text_features = vectorizer.fit_transform(df['url'])
X_combined = hstack([X, text_features])

# Train model
model = RandomForestClassifier(n_estimators=100, max_depth=15, min_samples_split=5, class_weight='balanced', random_state=42)
model.fit(X_combined, df['label'])

# Save model and vectorizer
joblib.dump(model, 'fast_phish_model.joblib')
joblib.dump(vectorizer, 'fast_phish_vectorizer.joblib')
df.to_csv('combined_urls.csv', index=False)

print("Model and vectorizer saved successfully.")