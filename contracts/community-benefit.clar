;; Community Benefit Contract
;; Ensures fair distribution of land use revenues

(define-data-var admin principal tx-sender)

;; Data structure for benefit allocations
(define-map benefit-allocations
  { allocation-id: uint }
  {
    parcel-id: uint,
    revenue-amount: uint,
    education-fund: uint,
    healthcare-fund: uint,
    infrastructure-fund: uint,
    cultural-preservation-fund: uint,
    general-fund: uint,
    allocation-date: uint
  }
)

;; Counter for allocation IDs
(define-data-var next-allocation-id uint u1)

;; Register a new benefit allocation
(define-public (register-allocation
                (parcel-id uint)
                (revenue-amount uint))
  (let ((allocation-id (var-get next-allocation-id))
        (education-amount (/ (* revenue-amount u20) u100))       ;; 20%
        (healthcare-amount (/ (* revenue-amount u20) u100))      ;; 20%
        (infrastructure-amount (/ (* revenue-amount u20) u100))  ;; 20%
        (cultural-amount (/ (* revenue-amount u20) u100))        ;; 20%
        (general-amount (/ (* revenue-amount u20) u100)))        ;; 20%
    (if (is-authorized)
        (begin
          (map-set benefit-allocations
            { allocation-id: allocation-id }
            {
              parcel-id: parcel-id,
              revenue-amount: revenue-amount,
              education-fund: education-amount,
              healthcare-fund: healthcare-amount,
              infrastructure-fund: infrastructure-amount,
              cultural-preservation-fund: cultural-amount,
              general-fund: general-amount,
              allocation-date: block-height
            }
          )
          (var-set next-allocation-id (+ allocation-id u1))
          (ok allocation-id))
        (err u403))))

;; Get allocation information
(define-read-only (get-allocation (allocation-id uint))
  (map-get? benefit-allocations { allocation-id: allocation-id }))

;; Get total funds by category
(define-read-only (get-education-fund)
  (fold + (map get-education-amount (get-all-allocations)) u0))

(define-read-only (get-healthcare-fund)
  (fold + (map get-healthcare-amount (get-all-allocations)) u0))

(define-read-only (get-infrastructure-fund)
  (fold + (map get-infrastructure-amount (get-all-allocations)) u0))

(define-read-only (get-cultural-preservation-fund)
  (fold + (map get-cultural-amount (get-all-allocations)) u0))

(define-read-only (get-general-fund)
  (fold + (map get-general-amount (get-all-allocations)) u0))

;; Helper functions for fund calculations
(define-private (get-education-amount (allocation-id uint))
  (default-to u0 (get education-fund (map-get? benefit-allocations { allocation-id: allocation-id }))))

(define-private (get-healthcare-amount (allocation-id uint))
  (default-to u0 (get healthcare-fund (map-get? benefit-allocations { allocation-id: allocation-id }))))

(define-private (get-infrastructure-amount (allocation-id uint))
  (default-to u0 (get infrastructure-fund (map-get? benefit-allocations { allocation-id: allocation-id }))))

(define-private (get-cultural-amount (allocation-id uint))
  (default-to u0 (get cultural-preservation-fund (map-get? benefit-allocations { allocation-id: allocation-id }))))

(define-private (get-general-amount (allocation-id uint))
  (default-to u0 (get general-fund (map-get? benefit-allocations { allocation-id: allocation-id }))))

;; Get all allocation IDs (simplified for clarity)
(define-private (get-all-allocations)
  (list u1 u2 u3)) ;; In a real implementation, this would be more dynamic

;; Update allocation percentages (for a specific allocation)
(define-public (update-allocation-percentages
                (allocation-id uint)
                (education-percent uint)
                (healthcare-percent uint)
                (infrastructure-percent uint)
                (cultural-percent uint)
                (general-percent uint))
  (let ((current-allocation (map-get? benefit-allocations { allocation-id: allocation-id })))
    (if (and (is-authorized)
             (is-some current-allocation)
             (is-eq (+ education-percent healthcare-percent infrastructure-percent cultural-percent general-percent) u100))
        (let ((revenue (get revenue-amount (unwrap-panic current-allocation))))
          (map-set benefit-allocations
            { allocation-id: allocation-id }
            {
              parcel-id: (get parcel-id (unwrap-panic current-allocation)),
              revenue-amount: revenue,
              education-fund: (/ (* revenue education-percent) u100),
              healthcare-fund: (/ (* revenue healthcare-percent) u100),
              infrastructure-fund: (/ (* revenue infrastructure-percent) u100),
              cultural-preservation-fund: (/ (* revenue cultural-percent) u100),
              general-fund: (/ (* revenue general-percent) u100),
              allocation-date: (get allocation-date (unwrap-panic current-allocation))
            }
          )
          (ok true))
        (err u403))))

;; Check if caller is authorized
(define-private (is-authorized)
  (is-eq tx-sender (var-get admin)))

;; Set a new admin
(define-public (set-admin (new-admin principal))
  (if (is-eq tx-sender (var-get admin))
      (begin
        (var-set admin new-admin)
        (ok true))
      (err u403)))
