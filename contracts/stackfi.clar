;; stackfi.clar
;; A basic decentralized lending & borrowing protocol on the Stacks blockchain
;; Built in Clarity - secure, predictable, transparent

;; ----------------------------
;; CONSTANTS & ERRORS
;; ----------------------------
(define-constant ERR_INSUFFICIENT_BALANCE u100)
(define-constant ERR_NO_COLLATERAL u101)
(define-constant ERR_UNAUTHORIZED u102)
(define-constant ERR_INVALID_AMOUNT u103)
(define-constant ERR_NOT_BORROWER u104)
(define-constant ERR_OVER_COLLATERALIZED u105)
(define-constant ERR_UNDER_COLLATERALIZED u106)

(define-constant COLLATERAL_RATIO u150) ;; must maintain 150% collateral
(define-constant INTEREST_RATE u5) ;; 5% simple interest per repayment

;; ----------------------------
;; DATA STORAGE
;; ----------------------------
(define-data-var total-supply uint u0)
(define-data-var total-borrowed uint u0)

;; Each lender's deposits
(define-map lenders principal uint)

;; Each borrower's active loan data
(define-map loans
  principal
  (tuple
    (borrowed uint)
    (collateral uint)
    (active bool)
  )
)

;; ----------------------------
;; EVENTS
;; ----------------------------
;; Note: Events are emitted using print statements in Clarity

;; ----------------------------
;; PUBLIC FUNCTIONS
;; ----------------------------

;; 1. Deposit STX into lending pool
(define-public (deposit (amount uint))
  (if (> amount u0)
      (begin
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        (map-set lenders tx-sender (+ (default-to u0 (map-get? lenders tx-sender)) amount))
        (var-set total-supply (+ (var-get total-supply) amount))
        (ok (tuple (deposited amount) (lender tx-sender))))
      (err ERR_INVALID_AMOUNT))
)

;; 2. Borrow STX by locking collateral
(define-public (borrow (collateral uint) (borrow-amount uint))
  (if (and (> collateral u0) (> borrow-amount u0))
      (let ((max-borrow (/ (* collateral u100) COLLATERAL_RATIO)))
        (if (<= borrow-amount max-borrow)
            (begin
              ;; Transfer collateral to contract
              (try! (stx-transfer? collateral tx-sender (as-contract tx-sender)))
              ;; Update storage
              (map-set loans tx-sender
                (tuple
                  (borrowed borrow-amount)
                  (collateral collateral)
                  (active true)))
              (var-set total-borrowed (+ (var-get total-borrowed) borrow-amount))
              ;; Send borrowed amount to borrower
              (try! (stx-transfer? borrow-amount (as-contract tx-sender) tx-sender))
              (ok (tuple (borrowed borrow-amount) (collateral collateral))))
            (err ERR_UNDER_COLLATERALIZED)))
      (err ERR_INVALID_AMOUNT))
)

;; 3. Repay loan (includes 5% interest)
(define-public (repay)
  (let ((loan (map-get? loans tx-sender)))
    (match loan
      l
        (if (get active l)
            (let (
                  (borrowed (get borrowed l))
                  (interest (/ (* borrowed INTEREST_RATE) u100))
                  (total (+ borrowed interest))
                )
              (try! (stx-transfer? total tx-sender (as-contract tx-sender)))
              ;; Return collateral
              (try! (stx-transfer? (get collateral l) (as-contract tx-sender) tx-sender))
              (map-set loans tx-sender (tuple (borrowed u0) (collateral u0) (active false)))
              (var-set total-borrowed (- (var-get total-borrowed) borrowed))
              (ok (tuple (paid total) (returned-collateral (get collateral l)))))
            (err ERR_NOT_BORROWER))
      (err ERR_NOT_BORROWER))
  )
)

;; 4. Liquidate under-collateralized loans
(define-public (liquidate (borrower principal))
  (let ((loan (map-get? loans borrower)))
    (match loan
      l
        (if (get active l)
            (let ((borrowed (get borrowed l))
                  (coll (get collateral l))
                  (current-ratio (/ (* (get collateral l) u100) (get borrowed l))))
              (if (< current-ratio COLLATERAL_RATIO)
                  (begin
                    ;; Transfer collateral to liquidator
                    (try! (stx-transfer? coll (as-contract tx-sender) tx-sender))
                    ;; Close the loan
                    (map-set loans borrower (tuple (borrowed u0) (collateral u0) (active false)))
                    (var-set total-borrowed (- (var-get total-borrowed) borrowed))
                    (ok (tuple (liquidated borrower) (collateral coll))))
                  (err ERR_OVER_COLLATERALIZED)))
            (err ERR_NOT_BORROWER))
      (err ERR_NOT_BORROWER))
  )
)

;; 5. Withdraw your lending deposit
(define-public (withdraw (amount uint))
  (let ((balance (default-to u0 (map-get? lenders tx-sender))))
    (if (>= balance amount)
        (begin
          (try! (stx-transfer? amount (as-contract tx-sender) tx-sender))
          (map-set lenders tx-sender (- balance amount))
          (var-set total-supply (- (var-get total-supply) amount))
          (ok (tuple (withdrawn amount) (lender tx-sender))))
        (err ERR_INSUFFICIENT_BALANCE)))
)

;; ----------------------------
;; READ-ONLY FUNCTIONS
;; ----------------------------

(define-read-only (get-lender-balance (user principal))
  (default-to u0 (map-get? lenders user))
)

(define-read-only (get-loan (user principal))
  (map-get? loans user)
)

(define-read-only (get-total-supply)
  (var-get total-supply)
)

(define-read-only (get-total-borrowed)
  (var-get total-borrowed)
)

(define-read-only (get-collateral-ratio (user principal))
  (let ((loan (map-get? loans user)))
    (match loan
      l
        (if (get active l)
            (/ (* (get collateral l) u100) (get borrowed l))
            u0)
      u0))
)
