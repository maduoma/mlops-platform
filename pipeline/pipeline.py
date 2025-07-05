#!/usr/bin/env python3
"""
MLOps Platform Demo - Music Therapy ML Pipeline

This pipeline demonstrates an end-to-end ML workflow for LUCID Therapeutics'
music therapy model with experiment tracking and model registration.

Features:
- Production-ready error handling and logging
- Flexible execution modes (demo, local, Kubeflow, MLflow)
- Comprehensive model validation and metrics
- Data quality checks and monitoring
- Model versioning and registry integration
- Security best practices and resource management

Execution modes:
1. Demo mode (no dependencies) - Shows pipeline structure with mock data
2. Local mode (with sklearn/pandas) - Runs actual ML workflow locally
3. Kubeflow mode (with KFP SDK) - Compiles for Kubernetes execution
4. MLflow mode (with MLflow) - Full experiment tracking and model registry
"""

from collections import namedtuple
import os
import sys
import logging
import json
import pickle
import random
import warnings
from datetime import datetime
from pathlib import Path
from typing import Dict, Any, List, Tuple, Optional, NamedTuple, Union
from contextlib import contextmanager

# Suppress warnings for cleaner output
warnings.filterwarnings('ignore', category=FutureWarning)
warnings.filterwarnings('ignore', category=UserWarning)

# Configure comprehensive logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(funcName)s:%(lineno)d - %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout),
        logging.FileHandler('pipeline.log') if os.access(
            '.', os.W_OK) else logging.NullHandler()
    ]
)
logger = logging.getLogger(__name__)

# Pipeline configuration
PIPELINE_CONFIG = {
    'name': 'music-therapy-ml-pipeline',
    'version': '2.0.0',
    'author': 'LUCID Therapeutics Platform Team',
    'created': datetime.now().isoformat(),
    'description': 'Production ML pipeline for music therapy model',
    'tags': ['mlops', 'music-therapy', 'healthcare', 'production']
}

# Named tuple types for return values

PreprocessOutput = namedtuple(
    'PreprocessOutput', ['train_samples', 'test_samples'])
TrainingOutput = namedtuple('TrainingOutput', ['accuracy', 'model_version'])
EvaluationOutput = namedtuple(
    'EvaluationOutput', ['test_accuracy', 'precision'])

# Type aliases for better compatibility
PathType = Union[str, 'InputPath', 'OutputPath']

# Try to import KFP types
try:
    from kfp.components import InputPath, OutputPath
    KFP_AVAILABLE = True
except ImportError:
    # Create dummy classes for type hints when KFP is not available
    class InputPath:
        def __init__(self, type_name: str = 'Dataset'):
            self.type_name = type_name

    class OutputPath:
        def __init__(self, type_name: str = 'Dataset'):
            self.type_name = type_name

    KFP_AVAILABLE = False
DEPENDENCIES = {
    'mlflow': {'available': False, 'version': None, 'required': '2.5.0+'},
    'sklearn': {'available': False, 'version': None, 'required': '1.3.0+'},
    'pandas': {'available': False, 'version': None, 'required': '2.0.0+'},
    'numpy': {'available': False, 'version': None, 'required': '1.24.0+'},
    'kfp': {'available': False, 'version': None, 'required': '2.0.0+'}
}

# Graceful dependency loading with version checking


def check_and_import_dependencies():
    """Check and import dependencies with version validation."""
    global DEPENDENCIES

    # MLflow
    try:
        import mlflow
        # Note: mlflow.sklearn is deprecated in MLflow 2.x+
        # Use mlflow.sklearn.log_model() directly instead
        DEPENDENCIES['mlflow']['available'] = True
        DEPENDENCIES['mlflow']['version'] = mlflow.__version__
        logger.info(f"✅ MLflow {mlflow.__version__} available")
    except ImportError as e:
        logger.warning(f"⚠️  MLflow not available: {e}")
        logger.info("   → Experiment tracking will be disabled")

    # Pandas and NumPy
    try:
        import pandas as pd
        import numpy as np
        DEPENDENCIES['pandas']['available'] = True
        DEPENDENCIES['numpy']['available'] = True
        DEPENDENCIES['pandas']['version'] = pd.__version__
        DEPENDENCIES['numpy']['version'] = np.__version__
        logger.info(
            f"✅ Pandas {pd.__version__} and NumPy {np.__version__} available")
    except ImportError as e:
        logger.warning(f"⚠️  Pandas/NumPy not available: {e}")
        logger.info("   → Will use mock data generation")

    # Scikit-learn
    try:
        import sklearn
        from sklearn.model_selection import train_test_split
        from sklearn.ensemble import RandomForestClassifier
        from sklearn.metrics import accuracy_score, classification_report, precision_score, f1_score, roc_auc_score
        from sklearn.preprocessing import StandardScaler, LabelEncoder
        from sklearn.datasets import make_classification
        DEPENDENCIES['sklearn']['available'] = True
        DEPENDENCIES['sklearn']['version'] = sklearn.__version__
        logger.info(f"✅ Scikit-learn {sklearn.__version__} available")
    except ImportError as e:
        logger.warning(f"⚠️  Scikit-learn not available: {e}")
        logger.info("   → Will use mock models")

    # Kubeflow Pipelines
    try:
        import kfp
        from kfp import dsl
        from kfp.components import InputPath, OutputPath, create_component_from_func
        DEPENDENCIES['kfp']['available'] = True
        DEPENDENCIES['kfp']['version'] = kfp.__version__
        logger.info(f"✅ Kubeflow Pipelines SDK {kfp.__version__} available")
    except ImportError as e:
        logger.warning(f"⚠️  KFP SDK not available: {e}")
        logger.info("   → Local execution only")


# Initialize dependencies
check_and_import_dependencies()

# Conditional decorator for KFP compatibility


def conditional_component(func):
    """Decorator that applies KFP component creation if available."""
    if DEPENDENCIES.get('kfp', {}).get('available', False):
        try:
            from kfp.components import create_component_from_func
            return create_component_from_func(func)
        except ImportError:
            pass
    return func


# MLflow configuration with environment-specific settings
MLFLOW_CONFIG = {
    'tracking_uri': os.getenv('MLFLOW_TRACKING_URI', 'http://mlflow-service.mlflow:5000'),
    'experiment_name': os.getenv('MLFLOW_EXPERIMENT', 'music-therapy-model'),
    'model_name': os.getenv('MLFLOW_MODEL_NAME', 'music-therapy-classifier'),
    'artifact_location': os.getenv('MLFLOW_ARTIFACT_LOCATION', None),
    'tags': {
        'pipeline_version': PIPELINE_CONFIG['version'],
        'environment': os.getenv('ENVIRONMENT', 'development'),
        'team': 'lucid-therapeutics',
        'use_case': 'music-therapy'
    }
}

# Data configuration
DATA_CONFIG = {
    'n_samples': int(os.getenv('DATA_SAMPLES', '1000')),
    'n_features': int(os.getenv('DATA_FEATURES', '10')),
    'n_classes': int(os.getenv('DATA_CLASSES', '3')),
    'test_size': float(os.getenv('TEST_SIZE', '0.2')),
    'validation_size': float(os.getenv('VALIDATION_SIZE', '0.1')),
    'random_state': int(os.getenv('RANDOM_STATE', '42'))
}

# Model configuration
MODEL_CONFIG = {
    'n_estimators': int(os.getenv('MODEL_N_ESTIMATORS', '100')),
    'max_depth': int(os.getenv('MODEL_MAX_DEPTH', '10')),
    'min_samples_split': int(os.getenv('MODEL_MIN_SAMPLES_SPLIT', '5')),
    'min_samples_leaf': int(os.getenv('MODEL_MIN_SAMPLES_LEAF', '2')),
    'max_features': os.getenv('MODEL_MAX_FEATURES', 'sqrt'),
    'bootstrap': os.getenv('MODEL_BOOTSTRAP', 'true').lower() == 'true',
    'random_state': DATA_CONFIG['random_state']
}


@contextmanager
def error_handler(step_name: str):
    """Context manager for consistent error handling across pipeline steps."""
    try:
        logger.info(f"🚀 Starting step: {step_name}")
        start_time = datetime.now()
        yield
        duration = (datetime.now() - start_time).total_seconds()
        logger.info(f"✅ Completed step: {step_name} in {duration:.2f}s")
    except Exception as e:
        logger.error(f"❌ Failed step: {step_name} - {str(e)}")
        logger.exception("Full traceback:")
        raise


def setup_mlflow():
    """Setup MLflow tracking with comprehensive error handling."""
    if not DEPENDENCIES['mlflow']['available']:
        logger.warning("MLflow not available - skipping setup")
        return False

    try:
        import mlflow

        # Set tracking URI
        mlflow.set_tracking_uri(MLFLOW_CONFIG['tracking_uri'])
        logger.info(f"MLflow tracking URI: {MLFLOW_CONFIG['tracking_uri']}")

        # Create experiment if it doesn't exist
        try:
            experiment = mlflow.create_experiment(
                name=MLFLOW_CONFIG['experiment_name'],
                artifact_location=MLFLOW_CONFIG['artifact_location'],
                tags=MLFLOW_CONFIG['tags']
            )
            logger.info(
                f"Created new experiment: {MLFLOW_CONFIG['experiment_name']}")
        except mlflow.exceptions.MlflowException:
            logger.info(
                f"Using existing experiment: {MLFLOW_CONFIG['experiment_name']}")

        # Set the experiment
        mlflow.set_experiment(MLFLOW_CONFIG['experiment_name'])
        return True

    except Exception as e:
        logger.error(f"Failed to setup MLflow: {e}")
        return False


def validate_data_quality(df, step_name: str) -> Dict[str, Any]:
    """Validate data quality and return metrics."""
    with error_handler(f"{step_name} - Data Quality Validation"):
        if not DEPENDENCIES['pandas']['available']:
            return {'status': 'skipped', 'reason': 'pandas not available'}

        import pandas as pd
        import numpy as np

        quality_metrics = {
            'n_rows': len(df),
            'n_columns': len(df.columns),
            'missing_values': df.isnull().sum().sum(),
            'duplicate_rows': df.duplicated().sum(),
            'memory_usage_mb': df.memory_usage(deep=True).sum() / 1024 / 1024,
            'dtypes': df.dtypes.value_counts().to_dict(),
            'numeric_columns': df.select_dtypes(include=[np.number]).columns.tolist(),
            'categorical_columns': df.select_dtypes(include=['object', 'category']).columns.tolist(),
        }

        # Check for data quality issues
        issues = []
        if quality_metrics['missing_values'] > 0:
            issues.append(
                f"Missing values: {quality_metrics['missing_values']}")
        if quality_metrics['duplicate_rows'] > 0:
            issues.append(
                f"Duplicate rows: {quality_metrics['duplicate_rows']}")
        if quality_metrics['n_rows'] < 100:
            issues.append(f"Low sample count: {quality_metrics['n_rows']}")

        quality_metrics['issues'] = issues
        quality_metrics['status'] = 'passed' if not issues else 'warning'

        logger.info(
            f"Data quality check - Status: {quality_metrics['status']}")
        if issues:
            logger.warning(f"Data quality issues: {', '.join(issues)}")

        return quality_metrics


# Conditional decorators and type aliases for KFP compatibility
if DEPENDENCIES['kfp']['available']:
    import kfp
    from kfp import dsl
    from kfp.components import InputPath, OutputPath, create_component_from_func

    # Use actual KFP decorators
    component_decorator = create_component_from_func
else:
    # Mock KFP types and decorators for local execution
    class MockPath:
        def __init__(self, path_type):
            self.path_type = path_type

    InputPath = MockPath
    OutputPath = MockPath

    # Mock decorator that just returns the function
    def component_decorator(func):
        func._is_kfp_component = True
        return func

# Type aliases for better compatibility
DatasetPath = str
ModelPath = str
MetricsPath = str


@component_decorator
def generate_synthetic_data(
    output_data_path: str
) -> Tuple[int, int]:
    """Generate synthetic dataset for music therapy ML model with comprehensive validation."""

    with error_handler("Data Generation"):
        if DEPENDENCIES['pandas']['available'] and DEPENDENCIES['sklearn']['available']:
            import pandas as pd
            import numpy as np
            from sklearn.datasets import make_classification

            # Generate synthetic music therapy data with realistic features
            X, y = make_classification(
                n_samples=DATA_CONFIG['n_samples'],
                n_features=DATA_CONFIG['n_features'],
                n_informative=8,
                n_redundant=2,
                n_clusters_per_class=1,
                n_classes=DATA_CONFIG['n_classes'],
                class_sep=0.8,  # Good class separation
                flip_y=0.01,    # Low noise
                random_state=DATA_CONFIG['random_state']
            )

            # Create realistic feature names for music therapy
            feature_names = [
                'tempo_bpm', 'energy_level', 'valence_score', 'danceability',
                'acousticness', 'instrumentalness', 'liveness_factor',
                'speechiness', 'loudness_db', 'duration_seconds'
            ]

            # Normalize features to realistic ranges
            X_normalized = np.copy(X)
            feature_ranges = {
                'tempo_bpm': (60, 200),      # BPM range
                'energy_level': (0, 1),      # 0-1 scale
                'valence_score': (0, 1),     # 0-1 scale (negative to positive)
                'danceability': (0, 1),      # 0-1 scale
                'acousticness': (0, 1),      # 0-1 scale
                'instrumentalness': (0, 1),  # 0-1 scale
                'liveness_factor': (0, 1),   # 0-1 scale
                'speechiness': (0, 1),       # 0-1 scale
                'loudness_db': (-40, 0),     # dB range
                'duration_seconds': (30, 600)  # 30s to 10min
            }

            # Apply realistic scaling
            for i, feature in enumerate(feature_names):
                if feature in feature_ranges:
                    min_val, max_val = feature_ranges[feature]
                    X_normalized[:, i] = (X_normalized[:, i] - X_normalized[:, i].min()) / \
                        (X_normalized[:, i].max() - X_normalized[:, i].min()) * \
                        (max_val - min_val) + min_val

            # Create DataFrame with proper column names
            df = pd.DataFrame(X_normalized, columns=feature_names)

            # Add target with meaningful labels
            therapy_categories = {0: 'relaxation', 1: 'motivation', 2: 'focus'}
            df['therapy_category'] = [therapy_categories[label] for label in y]
            df['therapy_category_encoded'] = y

            # Add metadata columns
            df['data_source'] = 'synthetic'
            df['created_at'] = datetime.now().isoformat()
            df['pipeline_version'] = PIPELINE_CONFIG['version']

            # Ensure output directory exists
            Path(output_data_path).parent.mkdir(parents=True, exist_ok=True)

            # Save dataset with compression
            df.to_csv(output_data_path, index=False,
                      compression='gzip' if output_data_path.endswith('.gz') else None)

            # Validate data quality
            quality_metrics = validate_data_quality(df, "Data Generation")

            # Log data generation metrics
            logger.info(
                f"Generated dataset: {len(df)} samples, {len(feature_names)} features")
            logger.info(
                f"Class distribution: {df['therapy_category'].value_counts().to_dict()}")
            logger.info(f"Data quality status: {quality_metrics['status']}")

            return (len(df), len(feature_names))

        else:
            # Mock data generation
            logger.warning(
                "Using mock data generation - dependencies not available")
            mock_data = {
                'samples': DATA_CONFIG['n_samples'],
                'features': DATA_CONFIG['n_features'],
                'classes': DATA_CONFIG['n_classes'],
                'generated_at': datetime.now().isoformat()
            }

            # Ensure directory exists and save mock data
            Path(output_data_path).parent.mkdir(parents=True, exist_ok=True)
            with open(output_data_path, 'w') as f:
                json.dump(mock_data, f, indent=2)

            return (mock_data['samples'], mock_data['features'])


@component_decorator
def preprocess_data(
    input_data_path: str,
    train_data_path: str,
    test_data_path: str,
    validation_data_path: str,
    scaler_path: str
) -> Tuple[int, int, int]:
    """Preprocess data with comprehensive validation and feature engineering."""

    with error_handler("Data Preprocessing"):
        if DEPENDENCIES['pandas']['available'] and DEPENDENCIES['sklearn']['available']:
            import pandas as pd
            import numpy as np
            from sklearn.model_selection import train_test_split
            from sklearn.preprocessing import StandardScaler, LabelEncoder

            # Load and validate input data
            try:
                if input_data_path.endswith('.gz'):
                    df = pd.read_csv(input_data_path, compression='gzip')
                else:
                    df = pd.read_csv(input_data_path)
            except Exception as e:
                logger.error(f"Failed to load input data: {e}")
                raise

            # Validate data quality
            quality_metrics = validate_data_quality(df, "Preprocessing Input")

            # Feature engineering
            logger.info("Performing feature engineering...")

            # Drop metadata columns for training
            feature_columns = [col for col in df.columns if col not in
                               ['therapy_category', 'therapy_category_encoded', 'data_source',
                                'created_at', 'pipeline_version']]

            X = df[feature_columns].copy()

            # Handle categorical target
            if 'therapy_category' in df.columns:
                y = df['therapy_category_encoded'] if 'therapy_category_encoded' in df.columns else df['therapy_category']
            else:
                raise ValueError(
                    "Target column 'therapy_category' not found in dataset")

            # Create additional engineered features
            if len(feature_columns) >= 4:  # Ensure we have enough features
                X['tempo_energy_ratio'] = X.iloc[:, 0] / \
                    (X.iloc[:, 1] + 1e-8)  # Avoid division by zero
                X['valence_energy_interaction'] = X.iloc[:, 2] * \
                    X.iloc[:, 1] if len(X.columns) > 2 else 0
                X['acoustic_speech_balance'] = (
                    X.iloc[:, 4] - X.iloc[:, 7]) if len(X.columns) > 7 else 0

            # Handle missing values
            if X.isnull().sum().sum() > 0:
                logger.warning(
                    f"Found {X.isnull().sum().sum()} missing values, filling with median")
                X = X.fillna(X.median())

            # Split data into train/validation/test
            X_temp, X_test, y_temp, y_test = train_test_split(
                X, y,
                test_size=DATA_CONFIG['test_size'],
                random_state=DATA_CONFIG['random_state'],
                stratify=y
            )

            # Further split temp into train and validation
            val_size_adjusted = DATA_CONFIG['validation_size'] / \
                (1 - DATA_CONFIG['test_size'])
            X_train, X_val, y_train, y_val = train_test_split(
                X_temp, y_temp,
                test_size=val_size_adjusted,
                random_state=DATA_CONFIG['random_state'],
                stratify=y_temp
            )

            # Fit scaler on training data only
            scaler = StandardScaler()
            X_train_scaled = scaler.fit_transform(X_train)
            X_val_scaled = scaler.transform(X_val)
            X_test_scaled = scaler.transform(X_test)

            # Convert back to DataFrames with proper column names
            feature_names = X.columns.tolist()

            train_df = pd.DataFrame(X_train_scaled, columns=feature_names)
            train_df['therapy_category_encoded'] = y_train.values

            val_df = pd.DataFrame(X_val_scaled, columns=feature_names)
            val_df['therapy_category_encoded'] = y_val.values

            test_df = pd.DataFrame(X_test_scaled, columns=feature_names)
            test_df['therapy_category_encoded'] = y_test.values

            # Add processing metadata
            processing_metadata = {
                'processed_at': datetime.now().isoformat(),
                'pipeline_version': PIPELINE_CONFIG['version'],
                'scaler_type': 'StandardScaler',
                'feature_count': len(feature_names),
                'train_samples': len(train_df),
                'val_samples': len(val_df),
                'test_samples': len(test_df)
            }

            # Save processed datasets
            for df_info in [(train_df, train_data_path, 'train'),
                            (val_df, validation_data_path, 'validation'),
                            (test_df, test_data_path, 'test')]:
                df_to_save, path, split_type = df_info

                # Add split identifier
                df_to_save['split_type'] = split_type
                df_to_save['processing_metadata'] = json.dumps(
                    processing_metadata)

                # Ensure directory exists
                Path(path).parent.mkdir(parents=True, exist_ok=True)

                # Save with compression
                df_to_save.to_csv(
                    path, index=False, compression='gzip' if path.endswith('.gz') else None)

                # Validate saved data
                validate_data_quality(
                    df_to_save, f"Preprocessing Output - {split_type}")

            # Save scaler with metadata
            scaler_data = {
                'scaler': scaler,
                'feature_names': feature_names,
                'metadata': processing_metadata
            }

            Path(scaler_path).parent.mkdir(parents=True, exist_ok=True)
            with open(scaler_path, 'wb') as f:
                pickle.dump(scaler_data, f)

            logger.info(f"Data preprocessing completed:")
            logger.info(f"  - Training samples: {len(train_df)}")
            logger.info(f"  - Validation samples: {len(val_df)}")
            logger.info(f"  - Test samples: {len(test_df)}")
            logger.info(f"  - Features: {len(feature_names)}")

            return (len(train_df), len(val_df), len(test_df))

        else:
            # Mock preprocessing
            logger.warning(
                "Using mock preprocessing - dependencies not available")
            mock_sizes = (800, 100, 100)  # train, val, test

            for path in [train_data_path, validation_data_path, test_data_path, scaler_path]:
                Path(path).parent.mkdir(parents=True, exist_ok=True)
                with open(path, 'w') as f:
                    json.dump({'mock': True, 'samples': mock_sizes[0] if 'train' in path else
                              mock_sizes[1] if 'val' in path else mock_sizes[2]}, f)

            return mock_sizes
    from sklearn.datasets import make_classification

    # Generate synthetic music therapy data
    # Features: tempo, energy, valence, danceability, acousticness, etc.
    X, y = make_classification(
        n_samples=1000,
        n_features=10,
        n_informative=8,
        n_redundant=2,
        n_clusters_per_class=1,
        n_classes=3,  # 3 therapy categories: relaxation, motivation, focus
        random_state=42
    )

    # Create feature names relevant to music therapy
    feature_names = [
        'tempo', 'energy', 'valence', 'danceability',
        'acousticness', 'instrumentalness', 'liveness',
        'speechiness', 'loudness', 'duration_ms'
    ]

    # Create DataFrame
    df = pd.DataFrame(X, columns=feature_names)
    df['therapy_category'] = y  # 0: relaxation, 1: motivation, 2: focus

    # Save dataset
    df.to_csv(output_data_path, index=False)

    return (len(df), len(feature_names))


@conditional_component
def preprocess_data(
    input_data_path: str,
    train_data_path: str,
    test_data_path: str,
    scaler_path: str
) -> PreprocessOutput:
    """Preprocess the data and split into train/test sets."""
    import pandas as pd
    import pickle
    from sklearn.model_selection import train_test_split
    from sklearn.preprocessing import StandardScaler

    # Load data
    df = pd.read_csv(input_data_path)

    # Separate features and target
    X = df.drop('therapy_category', axis=1)
    y = df['therapy_category']

    # Split data
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )

    # Scale features
    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train)
    X_test_scaled = scaler.transform(X_test)

    # Convert back to DataFrame
    X_train_df = pd.DataFrame(X_train_scaled, columns=X.columns)
    X_test_df = pd.DataFrame(X_test_scaled, columns=X.columns)

    # Add target back
    train_df = X_train_df.copy()
    train_df['therapy_category'] = y_train.values

    test_df = X_test_df.copy()
    test_df['therapy_category'] = y_test.values

    # Save processed data
    train_df.to_csv(train_data_path, index=False)
    test_df.to_csv(test_data_path, index=False)

    # Save scaler
    with open(scaler_path, 'wb') as f:
        pickle.dump(scaler, f)

    return (len(train_df), len(test_df))


@conditional_component
def train_model(
    train_data_path: str,
    model_path: str,
    metrics_path: str,
    n_estimators: int = 100,
    max_depth: int = 10,
    random_state: int = 42
) -> TrainingOutput:
    """Train Random Forest model with MLflow tracking."""
    import pandas as pd
    import pickle
    import json
    import mlflow
    from sklearn.ensemble import RandomForestClassifier
    from sklearn.metrics import accuracy_score, classification_report

    # Setup MLflow
    mlflow.set_tracking_uri("http://mlflow-service.mlflow:5000")
    mlflow.set_experiment("music-therapy-model")

    # Load training data
    train_df = pd.read_csv(train_data_path)
    X_train = train_df.drop('therapy_category', axis=1)
    y_train = train_df['therapy_category']

    # Start MLflow run
    with mlflow.start_run() as run:
        # Log parameters
        mlflow.log_param("n_estimators", n_estimators)
        mlflow.log_param("max_depth", max_depth)
        mlflow.log_param("random_state", random_state)

        # Train model
        model = RandomForestClassifier(
            n_estimators=n_estimators,
            max_depth=max_depth,
            random_state=random_state
        )
        model.fit(X_train, y_train)

        # Make predictions
        y_pred = model.predict(X_train)
        accuracy = accuracy_score(y_train, y_pred)

        # Log metrics
        mlflow.log_metric("train_accuracy", accuracy)

        # Log model using modern MLflow approach
        try:
            # Modern way to log sklearn models in MLflow 2.x+
            mlflow.sklearn.log_model(
                model,
                "model",
                registered_model_name="music-therapy-classifier"
            )
        except (AttributeError, ImportError):
            # Fallback for older MLflow versions or missing sklearn integration
            import tempfile
            import os
            with tempfile.NamedTemporaryFile(suffix='.pkl', delete=False) as tmp_file:
                pickle.dump(model, tmp_file)
                tmp_file.flush()
                mlflow.log_artifact(tmp_file.name, "model")
                os.unlink(tmp_file.name)

        # Save model locally
        with open(model_path, 'wb') as f:
            pickle.dump(model, f)

        # Save metrics
        metrics = {
            "accuracy": accuracy,
            "run_id": run.info.run_id,
            "model_version": run.info.run_id
        }

        with open(metrics_path, 'w') as f:
            json.dump(metrics, f)

        return (accuracy, run.info.run_id)


@conditional_component
def evaluate_model(
    test_data_path: str,
    model_path: str,
    evaluation_path: str
) -> EvaluationOutput:
    """Evaluate the trained model on test data."""
    import pandas as pd
    import pickle
    import json
    import mlflow
    from sklearn.metrics import accuracy_score, classification_report, precision_score

    # Load test data and model
    test_df = pd.read_csv(test_data_path)
    X_test = test_df.drop('therapy_category', axis=1)
    y_test = test_df['therapy_category']

    with open(model_path, 'rb') as f:
        model = pickle.load(f)

    # Make predictions
    y_pred = model.predict(X_test)

    # Calculate metrics
    accuracy = accuracy_score(y_test, y_pred)
    precision = precision_score(y_test, y_pred, average='weighted')

    # Log to MLflow
    mlflow.set_tracking_uri("http://mlflow-service.mlflow:5000")
    with mlflow.start_run():
        mlflow.log_metric("test_accuracy", accuracy)
        mlflow.log_metric("test_precision", precision)

    # Save evaluation results
    evaluation = {
        "test_accuracy": accuracy,
        "test_precision": precision,
        "classification_report": classification_report(y_test, y_pred, output_dict=True)
    }

    with open(evaluation_path, 'w') as f:
        json.dump(evaluation, f)

    return (accuracy, precision)


@dsl.pipeline(
    name='music-therapy-ml-pipeline',
    description='End-to-end ML pipeline for music therapy model with MLflow tracking'
)
def music_therapy_pipeline(
    n_estimators: int = 100,
    max_depth: int = 10,
    random_state: int = 42
):
    """Define the complete ML pipeline."""

    # Step 1: Generate synthetic data
    data_gen_op = generate_synthetic_data()

    # Step 2: Preprocess data
    preprocess_op = preprocess_data(
        input_data_path=data_gen_op.outputs['output_data_path']
    )

    # Step 3: Train model
    train_op = train_model(
        train_data_path=preprocess_op.outputs['train_data_path'],
        n_estimators=n_estimators,
        max_depth=max_depth,
        random_state=random_state
    )

    # Step 4: Evaluate model
    evaluate_op = evaluate_model(
        test_data_path=preprocess_op.outputs['test_data_path'],
        model_path=train_op.outputs['model_path']
    )

    # Set dependencies
    preprocess_op.after(data_gen_op)
    train_op.after(preprocess_op)
    evaluate_op.after(train_op)


def main():
    """Main function to compile and optionally run the pipeline."""
    # Compile the pipeline
    pipeline_filename = 'music_therapy_pipeline.yaml'
    kfp.compiler.Compiler().compile(music_therapy_pipeline, pipeline_filename)

    print(f"Pipeline compiled to {pipeline_filename}")

    # Optionally run the pipeline (requires Kubeflow Pipelines endpoint)
    if len(sys.argv) > 1 and sys.argv[1] == '--run':
        # Setup MLflow
        setup_mlflow()

        try:
            # Connect to Kubeflow Pipelines
            # Adjust as needed
            client = kfp.Client(host='http://localhost:8080')

            # Submit pipeline run
            run = client.run_pipeline(
                experiment_id=client.get_experiment(name="Default").id,
                job_name='music-therapy-ml-run',
                pipeline_package_path=pipeline_filename,
                params={
                    'n_estimators': 150,
                    'max_depth': 15,
                    'random_state': 42
                }
            )

            print(f"Pipeline run submitted: {run.id}")
            print(f"Monitor at: http://localhost:8080/#/runs/details/{run.id}")

        except Exception as e:
            print(f"Could not submit pipeline run: {e}")
            print("Make sure Kubeflow Pipelines is accessible")


if __name__ == '__main__':
    main()
