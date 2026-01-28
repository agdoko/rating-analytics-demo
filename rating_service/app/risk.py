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

    def _assess_location(self, region: str) -> float:
        """Assess location-based risk factor."""
        return self.REGION_FACTORS.get(region.lower(), 1.0)

    def _assess_claims_history(self, claims_count: int) -> float:
        """Assess risk based on prior claims history."""
        if claims_count == 0:
            return 0.8  # no-claims bonus
        elif claims_count <= 2:
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

        if request.region.lower() in self.HIGH_RISK_REGIONS:
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
