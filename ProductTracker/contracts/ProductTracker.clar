;; ProductTracker Smart Contract
;; Enables transparent tracking of product lifecycle from production to delivery

(define-trait product-tracking-trait
  (
    (register-product (uint uint) (response bool uint))
    (update-product-status (uint uint uint) (response bool uint))
    (get-product-history (uint) (response (list 10 {status: uint, timestamp: uint}) uint))
  )
)

;; Define product status constants
(define-constant PRODUCT_STATUS_PRODUCED u1)
(define-constant PRODUCT_STATUS_IN_TRANSIT u2)
(define-constant PRODUCT_STATUS_DELIVERED u3)
(define-constant PRODUCT_STATUS_QUALITY_CHECKED u4)

;; Error constants
(define-constant ERR_UNAUTHORIZED (err u1))
(define-constant ERR_INVALID_PRODUCT (err u2))
(define-constant ERR_STATUS_UPDATE_FAILED (err u3))
(define-constant ERR_INVALID_STATUS (err u4))

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

;; Register a new product
(define-public (register-product (product-id uint) (initial-status uint))
  (begin
    ;; Validate product ID is not zero
    (asserts! (> product-id u0) ERR_INVALID_PRODUCT)
    
    ;; Validate initial status
    (asserts! (is-valid-status initial-status) ERR_INVALID_STATUS)
    
    ;; Check authorization
    (asserts! (or (is-contract-owner tx-sender) (is-eq initial-status PRODUCT_STATUS_PRODUCED)) ERR_UNAUTHORIZED)
    
    ;; Register product
    (map-set product-details 
      {product-id: product-id}
      {
        owner: tx-sender,
        current-status: initial-status,
        history: (list {status: initial-status, timestamp: u800})
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
    ;; Validate new status
    (asserts! (is-valid-status new-status) ERR_INVALID_STATUS)
    
    ;; Check authorization
    (asserts! 
      (or 
        (is-contract-owner tx-sender)
        (is-eq (get owner product) tx-sender)
      ) 
      ERR_UNAUTHORIZED
    )
    
    ;; Update product status and history
    (map-set product-details 
      {product-id: product-id}
      (merge product 
        {
          current-status: new-status,
          history: (unwrap-panic 
            (as-max-len? 
              (append (get history product) {status: new-status, timestamp: u800}) 
              u10
            )
          )
        }
      )
    )
    (ok true)
  )
)

;; Retrieve product history
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