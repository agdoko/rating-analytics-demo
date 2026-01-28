import pytest
from datetime import date, timedelta
from app.models import QuoteRequest, PolicyType, CustomerType


@pytest.fixture
def sample_quote_request():
    """Create a standard quote request for testing."""
    return QuoteRequest(
        customer_id="CUST-001",
        customer_type=CustomerType.CORPORATE,
        policy_type=PolicyType.PROPERTY,
        coverage_amount=5_000_000,
        deductible=10000,
        start_date=date.today() + timedelta(days=1),
        end_date=date.today() + timedelta(days=366),
        region="london",
        industry="manufacturing",
        claims_history=1,
        years_in_business=15,
    )


@pytest.fixture
def high_risk_quote_request():
    """Create a high-risk quote request for testing."""
    return QuoteRequest(
        customer_id="CUST-002",
        customer_type=CustomerType.INDIVIDUAL,
        policy_type=PolicyType.CYBER,
        coverage_amount=20_000_000,
        deductible=5000,
        start_date=date.today() + timedelta(days=1),
        end_date=date.today() + timedelta(days=366),
        region="flood_plain",
        industry="healthcare",
        claims_history=7,
        years_in_business=3,
    )
