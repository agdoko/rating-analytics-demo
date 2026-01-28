#!/bin/bash
# Set up the feature branch with planted bugs for demo 4 (PR Review).
# Creates feature/add-aviation-lob branch with:
#   - Aviation added to PolicyType enum (correct change)
#   - 3 planted bugs across pricing.py and risk.py:
#     1. Off-by-one in risk.py _assess_claims_history: claims_count < 2 should be <= 2
#     2. Wrong variable in pricing.py _get_deductible_discount: deductible/deductible instead of deductible/coverage_amount
#     3. Missing null check in pricing.py _determine_exclusions: request.region.lower() crashes when region is None

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

# Initialize git repo if needed
if [ ! -d .git ]; then
    echo "Initializing git repository..."
    git init
    git add .
    git commit -m "Initial commit: rating analytics platform"
fi

# Ensure we're on main
MAIN_BRANCH=$(git branch --list main master | head -1 | tr -d '* ')
if [ -z "$MAIN_BRANCH" ]; then
    MAIN_BRANCH="main"
    git checkout -b main 2>/dev/null || true
fi
git checkout "$MAIN_BRANCH"

# Delete feature branch if it exists
git branch -D feature/add-aviation-lob 2>/dev/null || true

# Create feature branch
echo "Creating feature/add-aviation-lob branch..."
git checkout -b feature/add-aviation-lob

# --- Modify models.py: Add aviation to PolicyType enum (correct change) ---
cat > "$PROJECT_DIR/rating_service/app/models.py" << 'MODELS_EOF'
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
MODELS_EOF

# --- Modify pricing.py: Add aviation base rate + 3 planted bugs ---
cat > "$PROJECT_DIR/rating_service/app/pricing.py" << 'PRICING_EOF'
import uuid
from datetime import date, timedelta
from app.models import QuoteRequest, QuoteResponse, RiskProfile, PolicyType


class PricingEngine:
    """Calculates insurance premiums based on risk profiles and policy parameters."""

    BASE_RATES = {
        PolicyType.PROPERTY: 0.003,
        PolicyType.LIABILITY: 0.005,
        PolicyType.MARINE: 0.008,
        PolicyType.CYBER: 0.012,
        PolicyType.AVIATION: 0.015,
    }

    DEDUCTIBLE_DISCOUNTS = {
        1000: 0.0,
        5000: 0.05,
        10000: 0.10,
        25000: 0.15,
        50000: 0.20,
    }

    def calculate_premium(self, request: QuoteRequest, risk_profile: RiskProfile) -> QuoteResponse:
        """Calculate the premium for a given quote request and risk profile."""
        base_rate = self.BASE_RATES[request.policy_type]
        base_premium = request.coverage_amount * base_rate

        # Apply risk multiplier
        risk_multiplier = self._get_risk_multiplier(risk_profile)
        adjusted_premium = base_premium * risk_multiplier

        # Apply deductible discount
        deductible_discount = self._get_deductible_discount(request.deductible, request.coverage_amount)
        adjusted_premium *= (1 - deductible_discount)

        # Apply duration factor
        duration_days = (request.end_date - request.start_date).days
        duration_factor = duration_days / 365
        annual_premium = adjusted_premium / duration_factor if duration_factor != 1 else adjusted_premium

        # Apply minimum premium
        annual_premium = max(annual_premium, 500.0)

        # Calculate surcharges
        surcharges = self._calculate_surcharges(request, risk_profile)
        surcharge_total = sum(s["amount"] for s in surcharges)
        annual_premium += surcharge_total

        # Determine exclusions
        exclusions = self._determine_exclusions(request, risk_profile)

        return QuoteResponse(
            quote_id=str(uuid.uuid4()),
            customer_id=request.customer_id,
            policy_type=request.policy_type,
            annual_premium=round(annual_premium, 2),
            monthly_premium=round(annual_premium / 12, 2),
            coverage_amount=request.coverage_amount,
            deductible=request.deductible,
            risk_grade=risk_profile.overall_risk,
            valid_until=date.today() + timedelta(days=30),
            exclusions=exclusions,
            surcharges=surcharges,
        )

    def _get_risk_multiplier(self, risk_profile: RiskProfile) -> float:
        """Map risk profile to premium multiplier."""
        multipliers = {
            "low": 1.0,
            "medium": 1.5,
            "high": 2.5,
            "critical": 4.0,
        }
        return multipliers.get(risk_profile.overall_risk, 2.0)

    def _get_deductible_discount(self, deductible: float, coverage_amount: float) -> float:
        """Get discount percentage based on deductible-to-coverage ratio."""
        # BUG 2: Wrong variable - divides deductible by itself instead of coverage_amount
        ratio = deductible / deductible
        if ratio > 0.1:
            return 0.20
        applicable_discount = 0.0
        for threshold, discount in sorted(self.DEDUCTIBLE_DISCOUNTS.items()):
            if deductible >= threshold:
                applicable_discount = discount
        return applicable_discount

    def _calculate_surcharges(self, request: QuoteRequest, risk_profile: RiskProfile) -> list[dict]:
        """Calculate any applicable surcharges."""
        surcharges = []

        if "flood_zone" in risk_profile.flags:
            surcharges.append({
                "reason": "Flood zone location",
                "amount": request.coverage_amount * 0.002
            })

        if request.claims_history > 3:
            surcharges.append({
                "reason": "Adverse claims history",
                "amount": request.coverage_amount * 0.001 * request.claims_history
            })

        if request.policy_type == PolicyType.CYBER and request.coverage_amount > 5_000_000:
            surcharges.append({
                "reason": "High-value cyber coverage",
                "amount": 10000.0
            })

        if request.policy_type == PolicyType.AVIATION:
            surcharges.append({
                "reason": "Aviation hull war risk",
                "amount": request.coverage_amount * 0.003
            })

        return surcharges

    def _determine_exclusions(self, request: QuoteRequest, risk_profile: RiskProfile) -> list[str]:
        """Determine policy exclusions based on risk and coverage."""
        exclusions = []

        if risk_profile.overall_risk == "critical":
            exclusions.append("Acts of war and terrorism")
            exclusions.append("Pre-existing conditions")

        if request.policy_type == PolicyType.PROPERTY:
            if "flood_zone" in risk_profile.flags:
                exclusions.append("Flood damage (separate policy required)")
            exclusions.append("Normal wear and tear")

        if request.policy_type == PolicyType.CYBER:
            exclusions.append("Nation-state attacks")
            exclusions.append("Unpatched known vulnerabilities (>90 days)")

        if request.policy_type == PolicyType.AVIATION:
            exclusions.append("Manufacturer defects under recall")
            # BUG 3: Missing null check - request.region can be None with aviation
            # This will crash with AttributeError: 'NoneType' object has no attribute 'lower'
            if request.region.lower() in ["conflict_zone", "sanctioned_territory"]:
                exclusions.append("Operations in conflict zones")

        return exclusions
PRICING_EOF

# --- Modify risk.py: Add aviation support ---
cat > "$PROJECT_DIR/rating_service/app/risk.py" << 'RISK_EOF'
from app.models import QuoteRequest, RiskProfile, PolicyType, CustomerType


class RiskAssessor:
    """Assesses risk for insurance applications using a multi-factor scoring model."""

    HIGH_RISK_REGIONS = ["flood_plain", "earthquake_zone", "hurricane_coast"]
    HIGH_RISK_INDUSTRIES = ["mining", "construction", "oil_gas", "aviation"]

    REGION_FACTORS = {
        "london": 1.2,
        "manchester": 1.0,
        "edinburgh": 0.9,
        "birmingham": 1.0,
        "bristol": 0.95,
        "flood_plain": 2.0,
        "earthquake_zone": 2.5,
        "hurricane_coast": 2.2,
    }

    def assess(self, request: QuoteRequest) -> RiskProfile:
        """Perform comprehensive risk assessment for a quote request."""
        base_score = self._calculate_base_score(request)
        location_factor = self._assess_location(request.region)
        claims_factor = self._assess_claims_history(request.claims_history)
        industry_factor = self._assess_industry(request.industry, request.policy_type)

        composite_score = base_score * location_factor * claims_factor * industry_factor
        overall_risk = self._score_to_grade(composite_score)
        flags = self._identify_flags(request)

        return RiskProfile(
            base_risk_score=round(base_score, 3),
            location_factor=round(location_factor, 3),
            claims_factor=round(claims_factor, 3),
            industry_factor=round(industry_factor, 3),
            overall_risk=overall_risk,
            flags=flags,
        )

    def _calculate_base_score(self, request: QuoteRequest) -> float:
        """Calculate base risk score from coverage and customer profile."""
        score = 1.0

        # Coverage amount impact
        if request.coverage_amount > 10_000_000:
            score *= 1.5
        elif request.coverage_amount > 1_000_000:
            score *= 1.2

        # Customer type impact
        if request.customer_type == CustomerType.INDIVIDUAL:
            score *= 1.1
        elif request.customer_type == CustomerType.CORPORATE:
            score *= 0.9  # corporates tend to have better risk management

        # Tenure discount
        if request.years_in_business and request.years_in_business > 10:
            score *= 0.85

        # Deductible impact (higher deductible = lower risk to insurer)
        if request.deductible >= 25000:
            score *= 0.8
        elif request.deductible >= 10000:
            score *= 0.9

        return score

    def _assess_location(self, region: str | None) -> float:
        """Assess location-based risk factor."""
        if not region:
            return 1.0
        return self.REGION_FACTORS.get(region.lower(), 1.0)

    def _assess_claims_history(self, claims_count: int) -> float:
        """Assess risk based on prior claims history."""
        if claims_count == 0:
            return 0.8  # no-claims bonus
        # BUG 1: Off-by-one - should be <= 2, not < 2
        # Customers with exactly 2 claims get incorrectly penalized
        elif claims_count < 2:
            return 1.0
        elif claims_count <= 5:
            return 1.5
        else:
            return 2.5

    def _assess_industry(self, industry: str | None, policy_type: PolicyType) -> float:
        """Assess industry-specific risk."""
        if not industry:
            return 1.0

        if industry.lower() in self.HIGH_RISK_INDUSTRIES:
            return 1.8

        # Cyber policies have industry-specific factors
        if policy_type == PolicyType.CYBER:
            cyber_risk_industries = ["healthcare", "finance", "retail"]
            if industry.lower() in cyber_risk_industries:
                return 1.4

        return 1.0

    def _score_to_grade(self, score: float) -> str:
        """Convert numeric risk score to risk grade."""
        if score <= 1.0:
            return "low"
        elif score <= 2.0:
            return "medium"
        elif score <= 3.5:
            return "high"
        else:
            return "critical"

    def _identify_flags(self, request: QuoteRequest) -> list[str]:
        """Identify risk flags that need special attention."""
        flags = []

        if request.region and request.region.lower() in self.HIGH_RISK_REGIONS:
            flags.append("flood_zone")

        if request.claims_history > 5:
            flags.append("excessive_claims")

        if request.coverage_amount > 50_000_000:
            flags.append("high_value_policy")

        if request.industry and request.industry.lower() in self.HIGH_RISK_INDUSTRIES:
            flags.append("high_risk_industry")

        duration = (request.end_date - request.start_date).days
        if duration > 730:
            flags.append("long_term_policy")

        return flags
RISK_EOF

# --- Update validators.py: Add aviation support ---
cat > "$PROJECT_DIR/rating_service/app/validators.py" << 'VALIDATORS_EOF'
from datetime import date, timedelta
from app.models import QuoteRequest, PolicyType


class QuoteValidator:
    """Validates quote requests against business rules."""

    MAX_COVERAGE = {
        PolicyType.PROPERTY: 100_000_000,
        PolicyType.LIABILITY: 50_000_000,
        PolicyType.MARINE: 200_000_000,
        PolicyType.CYBER: 25_000_000,
        PolicyType.AVIATION: 500_000_000,
    }

    MIN_DEDUCTIBLE = {
        PolicyType.PROPERTY: 1000,
        PolicyType.LIABILITY: 5000,
        PolicyType.MARINE: 10000,
        PolicyType.CYBER: 5000,
        PolicyType.AVIATION: 25000,
    }

    def validate(self, request: QuoteRequest) -> list[str]:
        """Validate a quote request. Returns list of validation errors."""
        errors = []

        errors.extend(self._validate_dates(request))
        errors.extend(self._validate_coverage(request))
        errors.extend(self._validate_deductible(request))
        errors.extend(self._validate_business_rules(request))

        return errors

    def _validate_dates(self, request: QuoteRequest) -> list[str]:
        errors = []
        if request.start_date < date.today():
            errors.append("Start date cannot be in the past")
        if request.end_date <= request.start_date:
            errors.append("End date must be after start date")
        if (request.end_date - request.start_date).days > 1095:
            errors.append("Policy duration cannot exceed 3 years")
        if request.start_date > date.today() + timedelta(days=90):
            errors.append("Start date cannot be more than 90 days in the future")
        return errors

    def _validate_coverage(self, request: QuoteRequest) -> list[str]:
        errors = []
        max_cov = self.MAX_COVERAGE.get(request.policy_type)
        if max_cov and request.coverage_amount > max_cov:
            errors.append(
                f"Coverage amount exceeds maximum for {request.policy_type.value}: "
                f"\u00a3{request.coverage_amount:,.0f} > \u00a3{max_cov:,.0f}"
            )
        return errors

    def _validate_deductible(self, request: QuoteRequest) -> list[str]:
        errors = []
        min_ded = self.MIN_DEDUCTIBLE.get(request.policy_type)
        if min_ded and request.deductible < min_ded:
            errors.append(
                f"Deductible below minimum for {request.policy_type.value}: "
                f"\u00a3{request.deductible:,.0f} < \u00a3{min_ded:,.0f}"
            )
        if request.deductible > request.coverage_amount * 0.5:
            errors.append("Deductible cannot exceed 50% of coverage amount")
        return errors

    def _validate_business_rules(self, request: QuoteRequest) -> list[str]:
        errors = []
        if request.customer_type.value == "individual" and request.coverage_amount > 10_000_000:
            errors.append("Individual customers limited to \u00a310M coverage")
        if request.policy_type == PolicyType.MARINE and not request.industry:
            errors.append("Marine policies require industry specification")
        if request.policy_type == PolicyType.AVIATION and not request.industry:
            errors.append("Aviation policies require industry specification")
        return errors
VALIDATORS_EOF

# Commit the feature branch changes
git add -A
git commit -m "feat: add aviation line of business

- Add AVIATION to PolicyType enum
- Add aviation base rate (1.5%) to PricingEngine
- Add aviation hull war risk surcharge
- Add aviation exclusions for manufacturer defects
- Update validators with aviation coverage limits and deductible minimums
- Update risk assessor to handle optional region for aviation policies"

# Switch back to main
git checkout "$MAIN_BRANCH"

echo ""
echo "Feature branch 'feature/add-aviation-lob' created successfully."
echo "The branch contains 3 planted bugs:"
echo "  1. Off-by-one in risk.py: claims_count < 2 should be <= 2 in _assess_claims_history"
echo "  2. Wrong variable in pricing.py: deductible/deductible instead of deductible/coverage_amount"
echo "  3. Missing null check in pricing.py: request.region.lower() when region can be None"
echo ""
echo "To create a PR: git push -u origin feature/add-aviation-lob"
