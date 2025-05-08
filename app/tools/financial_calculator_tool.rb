# frozen_string_literal: true

class FinancialCalculatorTool < PaidTool
  description "Calculate mortgage payments and other financial metrics"
  arguments do
    required(:principal).filled(:integer).description("The principal amount of the loan")
    required(:interest_rate).filled(:integer).description("Annual interest rate (in percentage, e.g., 5.25)")
    required(:term_years).filled(:integer).description("Loan term in years")
  end

  def call(principal:, interest_rate:, term_years:)
    return { error: "User has no active subscription" } unless charge_user

    # Calculate monthly mortgage payment
    monthly_rate = (interest_rate / 100) / 12
    num_payments = term_years * 12
    
    monthly_payment = principal * 
                     (monthly_rate * (1 + monthly_rate)**num_payments) / 
                     ((1 + monthly_rate)**num_payments - 1)
    
    total_payment = monthly_payment * num_payments
    total_interest = total_payment - principal
    
    {
      monthly_payment: monthly_payment.round(2),
      total_payment: total_payment.round(2),
      total_interest: total_interest.round(2)
    }
  end
  
  # Override default price in cents (optional)
  def price_cents
    # This is a complex calculation, so we charge more
    80 # $0.08 per call
  end
end 