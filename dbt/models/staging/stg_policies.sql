with source as (
    select * from {{ source('raw', 'policies') }}
),

renamed as (
    select
        policy_id,
        customer_id,
        policy_type,
        cast(premium_amount as numeric) as premium_amount,
        cast(coverage_limit as numeric) as coverage_limit,
        cast(deductible as numeric) as deductible,
        effective_date,
        expiration_date,
        status as policy_status,
        created_at,
        updated_at
    from source
)

select * from renamed
