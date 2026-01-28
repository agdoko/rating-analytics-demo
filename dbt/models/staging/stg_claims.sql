with source as (
    select * from {{ source('raw', 'claims') }}
),

renamed as (
    select
        claim_id,
        policy_id,
        claimant_id,
        claim_type,
        cast(claim_amount as numeric) as claim_amount,
        cast(approved_amount as numeric) as approved_amount,
        incident_date,
        filed_date,
        resolution_date,
        status as claim_status,
        adjuster_id,
        created_at,
        updated_at
    from source
)

select * from renamed
