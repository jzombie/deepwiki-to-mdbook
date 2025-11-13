import importlib.util
import pathlib

import pytest


@pytest.fixture(scope="session")
def scraper_module():
    """Load the scraper module directly from python/deepwiki-scraper.py."""
    repo_root = pathlib.Path(__file__).resolve().parents[2]
    scraper_path = repo_root / "python" / "deepwiki-scraper.py"
    spec = importlib.util.spec_from_file_location("scraper", scraper_path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module
