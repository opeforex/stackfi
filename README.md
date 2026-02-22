# StackFi - Decentralized Lending & Borrowing Protocol

A secure, transparent decentralized lending and borrowing protocol built on the **Stacks blockchain** using **Clarity smart contracts**.

## Overview

StackFi enables users to:
- **Deposit STX** into a lending pool and earn returns
- **Borrow STX** by locking collateral at a 150% ratio
- **Repay loans** with 5% simple interest
- **Liquidate** under-collateralized positions to maintain protocol health

## Features

### Core Functionality
-  **Deposits** - Lenders lock STX to earn from protocol activity
-  **Borrowing** - Borrowers can take loans by depositing 150% collateral
-  **Interest** - 5% simple interest per loan repayment
-  **Liquidations** - Automatic liquidation of under-collateralized loans
-  **Withdrawals** - Lenders can withdraw deposits anytime

### Security
- On-chain verification of collateral requirements
- Principal-based authorization checks
- Error handling for invalid operations
- Read-only queries for transparency

## Smart Contract Functions

### Public Functions

#### `deposit (amount: uint) -> Response`
Deposit STX into the lending pool.
```clarity
(deposit u1000000) ;; Deposit 1 STX (in microSTX)
```

#### `borrow (collateral: uint, borrow-amount: uint) -> Response`
Borrow STX by locking collateral (minimum 150% ratio required).
```clarity
(borrow u150000000 u100000000) ;; Lock 150 STX, borrow 100 STX
```

#### `repay () -> Response`
Repay your loan with 5% interest and unlock collateral.
```clarity
(repay) ;; Automatically calculates interest and returns collateral
```

#### `liquidate (borrower: principal) -> Response`
Liquidate a borrower's position if collateral ratio falls below 150%.
```clarity
(liquidate 'SP2JKKNZ6EB7VXJ2C4VVK7ZXJG7MXNX7X7X7X7X7X)
```

#### `withdraw (amount: uint) -> Response`
Withdraw your STX deposits from the lending pool.
```clarity
(withdraw u500000) ;; Withdraw 0.5 STX
```

### Read-Only Functions

#### `get-lender-balance (user: principal) -> uint`
Check your lending deposit balance.

#### `get-loan (user: principal) -> Loan (optional)`
Retrieve active loan details (borrowed amount, collateral, status).

#### `get-total-supply () -> uint`
View total STX locked in the lending pool.

#### `get-total-borrowed () -> uint`
View total STX currently borrowed from the protocol.

#### `get-collateral-ratio (user: principal) -> uint`
Check your collateral-to-borrowed ratio (should be ≥ 150).

## Constants

- **COLLATERAL_RATIO**: `150` - Minimum 150% collateral requirement
- **INTEREST_RATE**: `5` - 5% simple interest per repayment

## Error Codes

| Code | Error | Description |
|------|-------|-------------|
| 100 | `ERR_INSUFFICIENT_BALANCE` | Insufficient funds for withdrawal |
| 101 | `ERR_NO_COLLATERAL` | No collateral provided |
| 102 | `ERR_UNAUTHORIZED` | Unauthorized access |
| 103 | `ERR_INVALID_AMOUNT` | Invalid amount (must be > 0) |
| 104 | `ERR_NOT_BORROWER` | User is not a borrower |
| 105 | `ERR_OVER_COLLATERALIZED` | Collateral ratio is too high |
| 106 | `ERR_UNDER_COLLATERALIZED` | Insufficient collateral |

## Data Structures

### Loan
```clarity
(tuple
  (borrowed uint)      ;; Amount borrowed in microSTX
  (collateral uint)    ;; Collateral locked in microSTX
  (active bool)        ;; Loan status
)
```

## Usage Example

### Scenario: Alice deposits, Bob borrows

```clarity
;; Alice deposits 1000 STX
(contract-call? .stackfi deposit u1000000000)

;; Bob borrows 100 STX with 150 STX collateral
(contract-call? .stackfi borrow u150000000 u100000000)

;; Bob's collateral ratio: (150 * 100) / 100 = 150% 

;; Bob repays loan + 5% interest (105 STX total)
(contract-call? .stackfi repay)
;; Collateral returned, interest distributed to lenders
```

## Deployment

### Prerequisites
- Stacks CLI installed
- Bitcoin wallet with testnet funds
- Clarity development environment

### Deploy to Testnet
```bash
stx deploy --network testnet stackfi.clar
```

## Security Considerations

 **Audit Status**: Pre-audit
- This is a basic implementation for educational purposes
- Do not deploy to mainnet without professional audit
- Recommended: Third-party smart contract audit before production use

## Future Enhancements

- [ ] Variable interest rates based on utilization
- [ ] Multiple collateral asset support
- [ ] Governance token (sFI)
- [ ] Flash loans
- [ ] Staking rewards
- [ ] Oracle price feeds for dynamic collateral valuation

---

**Built with ❤️ on Stacks Blockchain**
