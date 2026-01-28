from fastapi import FastAPI, HTTPException
from app.pricing import PricingEngine
from app.risk import RiskAssessor
from app.models import QuoteRequest, QuoteResponse, RiskProfile
from app.validators import QuoteValidator

app = FastAPI(title="Rating Analytics Service", version="1.0.0")

pricing_engine = PricingEngine()
risk_assessor = RiskAssessor()
validator = QuoteValidator()


@app.post("/quote", response_model=QuoteResponse)
async def generate_quote(request: QuoteRequest):
    """Generate an insurance quote based on risk assessment."""
    errors = validator.validate(request)
    if errors:
        raise HTTPException(status_code=422, detail=errors)

    risk_profile = risk_assessor.assess(request)
    quote = pricing_engine.calculate_premium(request, risk_profile)
    return quote


@app.get("/health")
async def health_check():
    return {"status": "healthy"}


@app.post("/bulk-quote")
async def bulk_quote(requests: list[QuoteRequest]):
    """Generate quotes for multiple policies at once."""
    results = []
    for req in requests:
        try:
            errors = validator.validate(req)
            if errors:
                results.append({"status": "error", "errors": errors})
                continue
            risk_profile = risk_assessor.assess(req)
            quote = pricing_engine.calculate_premium(req, risk_profile)
            results.append({"status": "success", "quote": quote})
        except Exception as e:
            results.append({"status": "error", "error": str(e)})
    return results
