;; ProductTracker Smart Contract
;; Enables transparent tracking of product lifecycle and certifications

(define-trait product-tracking-trait
  (
    (register-product (uint uint) (response bool uint))
    (update-product-status (uint uint) (response bool uint))
    (get-product-history (uint) (response (list 10 {status: uint, timestamp: uint}) uint))
    (add-certification (uint uint principal) (response bool uint))
    (verify-certification (uint uint) (response bool uint))
  )
)

;; Define product status constants
(define-constant PRODUCT_STATUS_PRODUCED u1)
(define-constant PRODUCT_STATUS_IN_TRANSIT u2)
(define-constant PRODUCT_STATUS_DELIVERED u3)
(define-constant PRODUCT_STATUS_QUALITY_CHECKED u4)

;; Define certification type constants
(define-constant CERT_TYPE_ORGANIC u1)
(define-constant CERT_TYPE_FAIR_TRADE u2)
(define-constant CERT_TYPE_SUSTAINABLE u3)
(define-constant CERT_TYPE_QUALITY_ASSURED u4)

;; Error constants
(define-constant ERR_UNAUTHORIZED (err u1))
(define-constant ERR_INVALID_PRODUCT (err u2))
(define-constant ERR_STATUS_UPDATE_FAILED (err u3))
(define-constant ERR_INVALID_STATUS (err u4))
(define-constant ERR_INVALID_CERTIFICATION (err u5))
(define-constant ERR_CERTIFICATION_EXISTS (err u6))

;; Contract owner
(define-data-var contract-owner principal tx-sender)

;; Product tracking map
(define-map product-details 
  {product-id: uint} 
  {
    owner: principal,
    current-status: uint,
    history: (list 10 {status: uint, timestamp: uint})
  }
)

;; Certification tracking map
(define-map product-certifications
  {product-id: uint, cert-type: uint}
  {
    issuer: principal,
    timestamp: uint,
    valid: bool
  }
)

;; Approved certification authorities
(define-map certification-authorities
  {authority: principal, cert-type: uint}
  {approved: bool}
)

;; Only contract owner can perform certain actions
(define-read-only (is-contract-owner (sender principal))
  (is-eq sender (var-get contract-owner))
)

;; Validate status
(define-private (is-valid-status (status uint))
  (or 
    (is-eq status PRODUCT_STATUS_PRODUCED)
    (is-eq status PRODUCT_STATUS_IN_TRANSIT)
    (is-eq status PRODUCT_STATUS_DELIVERED)
    (is-eq status PRODUCT_STATUS_QUALITY_CHECKED)
  )
)

;; Validate certification type
(define-private (is-valid-certification-type (cert-type uint))
  (or
    (is-eq cert-type CERT_TYPE_ORGANIC)
    (is-eq cert-type CERT_TYPE_FAIR_TRADE)
    (is-eq cert-type CERT_TYPE_SUSTAINABLE)
    (is-eq cert-type CERT_TYPE_QUALITY_ASSURED)
  )
)

;; Validate product ID
(define-private (is-valid-product-id (product-id uint))
  (and (> product-id u0) (<= product-id u1000000))
)

;; Check if sender is approved certification authority
(define-private (is-certification-authority (authority principal) (cert-type uint))
  (default-to 
    false
    (get approved (map-get? certification-authorities {authority: authority, cert-type: cert-type}))
  )
)

;; Register a new product
(define-public (register-product (product-id uint) (initial-status uint))
  (begin
    (asserts! (is-valid-product-id product-id) ERR_INVALID_PRODUCT)
    (asserts! (is-valid-status initial-status) ERR_INVALID_STATUS)
    (asserts! (or (is-contract-owner tx-sender) (is-eq initial-status PRODUCT_STATUS_PRODUCED)) ERR_UNAUTHORIZED)
    
    (map-set product-details 
      {product-id: product-id}
      {
        owner: tx-sender,
        current-status: initial-status,
        history: (list {status: initial-status, timestamp: stacks-block-height})
      }
    )
    (ok true)
  )
)

;; Update product status
(define-public (update-product-status (product-id uint) (new-status uint))
  (let 
    (
      (product (unwrap! (map-get? product-details {product-id: product-id}) ERR_INVALID_PRODUCT))
    )
    (asserts! (is-valid-product-id product-id) ERR_INVALID_PRODUCT)
    (asserts! (is-valid-status new-status) ERR_INVALID_STATUS)
    (asserts! 
      (or 
        (is-contract-owner tx-sender)
        (is-eq (get owner product) tx-sender)
      ) 
      ERR_UNAUTHORIZED
    )
    
    (map-set product-details 
      {product-id: product-id}
      (merge product 
        {
          current-status: new-status,
          history: (unwrap-panic 
            (as-max-len? 
              (append (get history product) {status: new-status, timestamp: stacks-block-height}) 
              u10
            )
          )
        }
      )
    )
    (ok true)
  )
)

;; Add certification authority
(define-public (add-certification-authority (authority principal) (cert-type uint))
  (begin
    (asserts! (is-contract-owner tx-sender) ERR_UNAUTHORIZED)
    (asserts! (is-valid-certification-type cert-type) ERR_INVALID_CERTIFICATION)
    
    (let
      ((validated-authority authority)
       (validated-cert-type cert-type))
      (map-set certification-authorities
        {authority: validated-authority, cert-type: validated-cert-type}
        {approved: true}
      )
      (ok true)
    )
  )
)

;; Add certification to product
(define-public (add-certification (product-id uint) (cert-type uint))
  (begin
    (asserts! (is-valid-product-id product-id) ERR_INVALID_PRODUCT)
    (asserts! (is-valid-certification-type cert-type) ERR_INVALID_CERTIFICATION)
    (asserts! (is-certification-authority tx-sender cert-type) ERR_UNAUTHORIZED)
    
    ;; Check if certification already exists
    (asserts! 
      (is-none 
        (map-get? product-certifications {product-id: product-id, cert-type: cert-type})
      )
      ERR_CERTIFICATION_EXISTS
    )
    
    (let
      ((validated-product-id product-id)
       (validated-cert-type cert-type))
      (map-set product-certifications
        {product-id: validated-product-id, cert-type: validated-cert-type}
        {
          issuer: tx-sender,
          timestamp: stacks-block-height,
          valid: true
        }
      )
      (ok true)
    )
  )
)

;; Verify product certification
(define-read-only (verify-certification (product-id uint) (cert-type uint))
  (let
    (
      (certification (unwrap! 
        (map-get? product-certifications {product-id: product-id, cert-type: cert-type})
        ERR_INVALID_CERTIFICATION
      ))
    )
    (ok (get valid certification))
  )
)

;; Revoke certification
(define-public (revoke-certification (product-id uint) (cert-type uint))
  (begin
    (asserts! (is-valid-product-id product-id) ERR_INVALID_PRODUCT)
    (asserts! (is-valid-certification-type cert-type) ERR_INVALID_CERTIFICATION)
    
    (let
      (
        (certification (unwrap! 
          (map-get? product-certifications {product-id: product-id, cert-type: cert-type})
          ERR_INVALID_CERTIFICATION
        ))
        (validated-product-id product-id)
        (validated-cert-type cert-type)
      )
      (asserts! 
        (or
          (is-contract-owner tx-sender)
          (is-eq (get issuer certification) tx-sender)
        )
        ERR_UNAUTHORIZED
      )
      
      (map-set product-certifications
        {product-id: validated-product-id, cert-type: validated-cert-type}
        (merge certification {valid: false})
      )
      (ok true)
    )
  )
)

;; Get product history
(define-read-only (get-product-history (product-id uint))
  (let 
    (
      (product (unwrap! (map-get? product-details {product-id: product-id}) ERR_INVALID_PRODUCT))
    )
    (ok (get history product))
  )
)

;; Get current product status
(define-read-only (get-product-status (product-id uint))
  (let 
    (
      (product (unwrap! (map-get? product-details {product-id: product-id}) ERR_INVALID_PRODUCT))
    )
    (ok (get current-status product))
  )
)

;; Get certification details
(define-read-only (get-certification-details (product-id uint) (cert-type uint))
  (ok (map-get? product-certifications {product-id: product-id, cert-type: cert-type}))
)