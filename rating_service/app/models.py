from pydantic import BaseModel, Field
from enum import Enum
from typing import Optional
from datetime import date


class PolicyType(str, Enum):
    PROPERTY = "property"
    LIABILITY = "liability"
    MARINE = "marine"
    CYBER = "cyber"
    AVIATION = "aviation"


class CustomerType(str, Enum):
    INDIVIDUAL = "individual"
    SME = "sme"
    CORPORATE = "corporate"


class QuoteRequest(BaseModel):
    customer_id: str
    customer_type: CustomerType
    policy_type: PolicyType
    coverage_amount: float = Field(gt=0)
    deductible: float = Field(ge=0)
    start_date: date
    end_date: date
    region: Optional[str] = None
    industry: Optional[str] = None
    claims_history: int = Field(ge=0, default=0)
    years_in_business: Optional[int] = None


class RiskProfile(BaseModel):
    base_risk_score: float
    location_factor: float
    claims_factor: float
    industry_factor: float
    overall_risk: str  # "low", "medium", "high", "critical"
    flags: list[str] = []


class QuoteResponse(BaseModel):
    quote_id: str
    customer_id: str
    policy_type: PolicyType
    annual_premium: float
    monthly_premium: float
    coverage_amount: float
    deductible: float
    risk_grade: str
    valid_until: date
    exclusions: list[str] = []
    surcharges: list[dict] = []
