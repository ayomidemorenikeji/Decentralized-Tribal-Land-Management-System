;; Cultural Site Protection Contract
;; Identifies and manages heritage locations

(define-data-var admin principal tx-sender)

;; Data structure for cultural sites
(define-map cultural-sites
  { site-id: uint }
  {
    name: (string-utf8 50),
    parcel-id: uint,
    protection-level: uint,
    description: (string-utf8 200),
    registration-date: uint
  }
)

;; Counter for site IDs
(define-data-var next-site-id uint u1)

;; Protection levels
;; u1: Basic protection
;; u2: Moderate protection
;; u3: High protection
;; u4: Sacred site (highest protection)

;; Register a new cultural site
(define-public (register-site
                (name (string-utf8 50))
                (parcel-id uint)
                (protection-level uint)
                (description (string-utf8 200)))
  (let ((site-id (var-get next-site-id)))
    (if (is-authorized)
        (begin
          (map-set cultural-sites
            { site-id: site-id }
            {
              name: name,
              parcel-id: parcel-id,
              protection-level: protection-level,
              description: description,
              registration-date: block-height
            }
          )
          (var-set next-site-id (+ site-id u1))
          (ok site-id))
        (err u403))))

;; Get site information
(define-read-only (get-site (site-id uint))
  (map-get? cultural-sites { site-id: site-id }))

;; Update site protection level
(define-public (update-protection-level (site-id uint) (protection-level uint))
  (let ((current-site (map-get? cultural-sites { site-id: site-id })))
    (if (and (is-authorized) (is-some current-site))
        (begin
          (map-set cultural-sites
            { site-id: site-id }
            {
              name: (get name (unwrap-panic current-site)),
              parcel-id: (get parcel-id (unwrap-panic current-site)),
              protection-level: protection-level,
              description: (get description (unwrap-panic current-site)),
              registration-date: (get registration-date (unwrap-panic current-site))
            }
          )
          (ok true))
        (err u403))))

;; Update site information
(define-public (update-site
                (site-id uint)
                (name (string-utf8 50))
                (description (string-utf8 200)))
  (let ((current-site (map-get? cultural-sites { site-id: site-id })))
    (if (and (is-authorized) (is-some current-site))
        (begin
          (map-set cultural-sites
            { site-id: site-id }
            {
              name: name,
              parcel-id: (get parcel-id (unwrap-panic current-site)),
              protection-level: (get protection-level (unwrap-panic current-site)),
              description: description,
              registration-date: (get registration-date (unwrap-panic current-site))
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

