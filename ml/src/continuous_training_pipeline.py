import subprocess
import sys
import logging
from pathlib import Path

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

BASE_DIR = Path(__file__).resolve().parent

def run_pipeline(mock=False):
    logger.info("Starting Continuous ML Training Pipeline...")
    
    # Step 1: Fetch Live Disasters
    cmd_fetch = [sys.executable, str(BASE_DIR / "fetch_live_disasters.py")]
    if mock:
        cmd_fetch.append("--mock")
    
    logger.info("Running live disaster API ingestion...")
    res = subprocess.run(cmd_fetch)
    
    if res.returncode == 2:
        logger.info("No new live landslide events. Model retraining skipped.")
        return True
    elif res.returncode != 0:
        logger.error("Error occurred while fetching live disasters.")
        return False
        
    # Step 2: Retrain Model
    logger.info("New events ingested into dataset. Triggering Random Forest model retraining...")
    cmd_train = [sys.executable, str(BASE_DIR / "train_final_model.py")]
    res_train = subprocess.run(cmd_train)
    
    if res_train.returncode == 0:
        logger.info("Pipeline completed successfully. New AI model has been deployed to the artifact directory.")
        return True
    else:
        logger.error("Model retraining failed. Please check the logs.")
        return False

if __name__ == "__main__":
    use_mock = "--mock" in sys.argv
    success = run_pipeline(mock=use_mock)
    sys.exit(0 if success else 1)
