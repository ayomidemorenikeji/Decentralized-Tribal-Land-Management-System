;; Land Parcel Registration Contract
;; Records boundaries and characteristics of tribal land parcels

(define-data-var admin principal tx-sender)

;; Data structure for land parcels
(define-map land-parcels
  { parcel-id: uint }
  {
    owner: principal,
    north-boundary: uint,
    east-boundary: uint,
    south-boundary: uint,
    west-boundary: uint,
    land-type: (string-utf8 20),
    registration-date: uint
  }
)

;; Counter for parcel IDs
(define-data-var next-parcel-id uint u1)

;; Register a new land parcel
(define-public (register-parcel
                (north-boundary uint)
                (east-boundary uint)
                (south-boundary uint)
                (west-boundary uint)
                (land-type (string-utf8 20)))
  (let ((parcel-id (var-get next-parcel-id)))
    (if (is-authorized)
        (begin
          (map-set land-parcels
            { parcel-id: parcel-id }
            {
              owner: tx-sender,
              north-boundary: north-boundary,
              east-boundary: east-boundary,
              south-boundary: south-boundary,
              west-boundary: west-boundary,
              land-type: land-type,
              registration-date: block-height
            }
          )
          (var-set next-parcel-id (+ parcel-id u1))
          (ok parcel-id))
        (err u403))))

;; Get parcel information
(define-read-only (get-parcel (parcel-id uint))
  (map-get? land-parcels { parcel-id: parcel-id }))

;; Update parcel information
(define-public (update-parcel
                (parcel-id uint)
                (north-boundary uint)
                (east-boundary uint)
                (south-boundary uint)
                (west-boundary uint)
                (land-type (string-utf8 20)))
  (let ((current-parcel (map-get? land-parcels { parcel-id: parcel-id })))
    (if (and (is-authorized) (is-some current-parcel))
        (begin
          (map-set land-parcels
            { parcel-id: parcel-id }
            {
              owner: (get owner (unwrap-panic current-parcel)),
              north-boundary: north-boundary,
              east-boundary: east-boundary,
              south-boundary: south-boundary,
              west-boundary: west-boundary,
              land-type: land-type,
              registration-date: (get registration-date (unwrap-panic current-parcel))
            }
          )
          (ok true))
        (err u403))))

;; Transfer parcel ownership
(define-public (transfer-parcel (parcel-id uint) (new-owner principal))
  (let ((current-parcel (map-get? land-parcels { parcel-id: parcel-id })))
    (if (and (is-some current-parcel)
             (is-eq tx-sender (get owner (unwrap-panic current-parcel))))
        (begin
          (map-set land-parcels
            { parcel-id: parcel-id }
            {
              owner: new-owner,
              north-boundary: (get north-boundary (unwrap-panic current-parcel)),
              east-boundary: (get east-boundary (unwrap-panic current-parcel)),
              south-boundary: (get south-boundary (unwrap-panic current-parcel)),
              west-boundary: (get west-boundary (unwrap-panic current-parcel)),
              land-type: (get land-type (unwrap-panic current-parcel)),
              registration-date: (get registration-date (unwrap-panic current-parcel))
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

