;; Patent Exchange Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-already-registered (err u103))
(define-constant err-price-mismatch (err u104))

;; Data vars
(define-data-var next-patent-id uint u0)

;; Data maps
(define-map patents
  { patent-id: uint }
  {
    owner: principal,
    title: (string-ascii 256),
    description: (string-ascii 1024),
    price: uint,
    is-for-sale: bool
  }
)

;; Public functions
(define-public (register-patent (title (string-ascii 256)) (description (string-ascii 1024)) (price uint))
    (let
        ((patent-id (var-get next-patent-id)))
        (map-insert patents 
            { patent-id: patent-id }
            {
                owner: tx-sender,
                title: title,
                description: description,
                price: price,
                is-for-sale: false
            }
        )
        (var-set next-patent-id (+ patent-id u1))
        (ok patent-id)
    )
)

(define-public (update-patent-price (patent-id uint) (new-price uint))
    (let ((patent (unwrap! (map-get? patents { patent-id: patent-id }) (err err-not-found))))
        (asserts! (is-eq tx-sender (get owner patent)) err-unauthorized)
        (map-set patents
            { patent-id: patent-id }
            (merge patent { price: new-price })
        )
        (ok true)
    )
)

(define-public (list-for-sale (patent-id uint))
    (let ((patent (unwrap! (map-get? patents { patent-id: patent-id }) (err err-not-found))))
        (asserts! (is-eq tx-sender (get owner patent)) err-unauthorized)
        (map-set patents
            { patent-id: patent-id }
            (merge patent { is-for-sale: true })
        )
        (ok true)
    )
)

(define-public (unlist-from-sale (patent-id uint))
    (let ((patent (unwrap! (map-get? patents { patent-id: patent-id }) (err err-not-found))))
        (asserts! (is-eq tx-sender (get owner patent)) err-unauthorized)
        (map-set patents
            { patent-id: patent-id }
            (merge patent { is-for-sale: false })
        )
        (ok true)
    )
)

(define-public (purchase-patent (patent-id uint) (offered-price uint))
    (let ((patent (unwrap! (map-get? patents { patent-id: patent-id }) (err err-not-found))))
        (asserts! (get is-for-sale patent) err-not-found)
        (asserts! (is-eq (get price patent) offered-price) err-price-mismatch)
        (try! (stx-transfer? offered-price tx-sender (get owner patent)))
        (map-set patents
            { patent-id: patent-id }
            (merge patent { 
                owner: tx-sender,
                is-for-sale: false 
            })
        )
        (ok true)
    )
)

;; Read only functions
(define-read-only (get-patent (patent-id uint))
    (map-get? patents { patent-id: patent-id })
)

(define-read-only (get-patent-count)
    (ok (var-get next-patent-id))
)
