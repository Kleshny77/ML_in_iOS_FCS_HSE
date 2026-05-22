# Данные

Скрипты в `калории/` собирают `CalorieClassificationData` для обучения **CalorieClassifier**:

```bash
cd калории && python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt && python3 run_calorie_pipeline.py
```

Папки `CalorieClassificationData` и `CalorieRegressionData5k` в git не хранятся (генерируются локально).
