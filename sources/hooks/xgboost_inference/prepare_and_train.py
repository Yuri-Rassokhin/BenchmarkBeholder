import pandas as pd
import xgboost as xgb
import joblib
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import accuracy_score, classification_report
from imblearn.over_sampling import SMOTE

# Load dataset
df = pd.read_csv('creditcard.csv')

# Drop 'Time' column, keep 'Amount' and normalize it
X = df.drop(columns=['Class', 'Time'])
y = df['Class']
scaler = StandardScaler()
X['Amount'] = scaler.fit_transform(X[['Amount']])

# Save the scaler
joblib.dump(scaler, 'scaler.pkl')
print("Scaler saved as scaler.pkl")

# Split data
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42, stratify=y)

# Handle class imbalance using SMOTE
smote = SMOTE(sampling_strategy=0.5, random_state=42)
X_train_resampled, y_train_resampled = smote.fit_resample(X_train, y_train)

# Train XGBoost model
model = xgb.XGBClassifier(use_label_encoder=False, eval_metric='logloss')
model.fit(X_train_resampled, y_train_resampled)

# Evaluate model
y_pred = model.predict(X_test)
print("Accuracy:", accuracy_score(y_test, y_pred))
print("Classification Report:\n", classification_report(y_test, y_pred))

# Save model
joblib.dump(model, 'xgboost_credit_fraud.pkl')
print("Model saved as xgboost_credit_fraud.pkl")
