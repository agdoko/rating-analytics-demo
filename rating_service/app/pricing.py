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
