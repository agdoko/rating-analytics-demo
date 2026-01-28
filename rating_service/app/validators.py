from datetime import date, timedelta
from app.models import QuoteRequest, PolicyType


class QuoteValidator:
    """Validates quote requests against business rules."""

    MAX_COVERAGE = {
        PolicyType.PROPERTY: 100_000_000,
        PolicyType.LIABILITY: 50_000_000,
        PolicyType.MARINE: 200_000_000,
        PolicyType.CYBER: 25_000_000,
    }

    MIN_DEDUCTIBLE = {
        PolicyType.PROPERTY: 1000,
        PolicyType.LIABILITY: 5000,
        PolicyType.MARINE: 10000,
        PolicyType.CYBER: 5000,
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
        return errors
