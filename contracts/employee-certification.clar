;; Employee Certification Contract
;; Validates food handler training and licenses

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u300))
(define-constant ERR-EMPLOYEE-NOT-FOUND (err u301))
(define-constant ERR-CERTIFICATION-NOT-FOUND (err u302))
(define-constant ERR-CERTIFICATION-EXPIRED (err u303))
(define-constant ERR-INVALID-DATES (err u304))
(define-constant ERR-RESTAURANT-NOT-FOUND (err u305))

;; Data Variables
(define-data-var next-employee-id uint u1)
(define-data-var next-certification-id uint u1)

;; Data Maps
(define-map employees uint {
  name: (string-ascii 100),
  restaurant-id: uint,
  position: (string-ascii 50),
  hire-date: uint,
  status: (string-ascii 20),
  contact-info: (string-ascii 100)
})

(define-map certifications uint {
  employee-id: uint,
  certification-type: (string-ascii 50),
  issuing-authority: (string-ascii 100),
  issue-date: uint,
  expiry-date: uint,
  certificate-number: (string-ascii 50),
  status: (string-ascii 20)
})

(define-map employee-certifications uint (list 20 uint))
(define-map restaurant-employees uint (list 200 uint))

(define-map certification-requirements (string-ascii 50) {
  validity-period: uint,
  required-for-positions: (list 10 (string-ascii 50)),
  description: (string-ascii 200)
})

;; Authorization Maps
(define-map authorized-trainers principal bool)
(define-map restaurant-managers uint principal)

;; Initialize certification requirements
(map-set certification-requirements "food-handler" {
  validity-period: u52560, ;; ~1 year in blocks
  required-for-positions: (list "cook" "server" "prep-cook" "dishwasher"),
  description: "Basic food safety and handling certification"
})

(map-set certification-requirements "manager-certification" {
  validity-period: u105120, ;; ~2 years in blocks
  required-for-positions: (list "manager" "assistant-manager" "shift-supervisor"),
  description: "Food service management certification"
})

(map-set certification-requirements "allergen-awareness" {
  validity-period: u26280, ;; ~6 months in blocks
  required-for-positions: (list "server" "cook" "manager"),
  description: "Food allergen awareness and handling"
})

;; Public Functions

;; Register a new employee
(define-public (register-employee (name (string-ascii 100)) (restaurant-id uint) (position (string-ascii 50)) (contact-info (string-ascii 100)))
  (let ((employee-id (var-get next-employee-id)))
    (asserts! (is-restaurant-manager restaurant-id tx-sender) ERR-NOT-AUTHORIZED)

    (map-set employees employee-id {
      name: name,
      restaurant-id: restaurant-id,
      position: position,
      hire-date: block-height,
      status: "active",
      contact-info: contact-info
    })

    ;; Update restaurant employees list
    (let ((current-employees (default-to (list) (map-get? restaurant-employees restaurant-id))))
      (map-set restaurant-employees restaurant-id
        (unwrap! (as-max-len? (append current-employees employee-id) u200) (err u306)))
    )

    (var-set next-employee-id (+ employee-id u1))
    (ok employee-id)
  )
)

;; Issue a certification
(define-public (issue-certification (employee-id uint) (certification-type (string-ascii 50)) (issuing-authority (string-ascii 100)) (certificate-number (string-ascii 50)))
  (let ((certification-id (var-get next-certification-id))
        (employee (unwrap! (map-get? employees employee-id) ERR-EMPLOYEE-NOT-FOUND))
        (cert-req (map-get? certification-requirements certification-type)))

    (asserts! (is-authorized-trainer tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-some cert-req) (err u307))

    (let ((validity-period (get validity-period (unwrap! cert-req (err u307))))
          (expiry-date (+ block-height validity-period)))

      (map-set certifications certification-id {
        employee-id: employee-id,
        certification-type: certification-type,
        issuing-authority: issuing-authority,
        issue-date: block-height,
        expiry-date: expiry-date,
        certificate-number: certificate-number,
        status: "active"
      })

      ;; Update employee certifications list
      (let ((current-certs (default-to (list) (map-get? employee-certifications employee-id))))
        (map-set employee-certifications employee-id
          (unwrap! (as-max-len? (append current-certs certification-id) u20) (err u308)))
      )

      (var-set next-certification-id (+ certification-id u1))
      (ok certification-id)
    )
  )
)

;; Renew a certification
(define-public (renew-certification (certification-id uint) (new-certificate-number (string-ascii 50)))
  (let ((certification (unwrap! (map-get? certifications certification-id) ERR-CERTIFICATION-NOT-FOUND))
        (cert-req (unwrap! (map-get? certification-requirements (get certification-type certification)) (err u307))))

    (asserts! (is-authorized-trainer tx-sender) ERR-NOT-AUTHORIZED)

    (let ((validity-period (get validity-period cert-req))
          (new-expiry-date (+ block-height validity-period)))

      (map-set certifications certification-id (merge certification {
        issue-date: block-height,
        expiry-date: new-expiry-date,
        certificate-number: new-certificate-number,
        status: "active"
      }))
      (ok true)
    )
  )
)

;; Update employee status
(define-public (update-employee-status (employee-id uint) (status (string-ascii 20)))
  (let ((employee (unwrap! (map-get? employees employee-id) ERR-EMPLOYEE-NOT-FOUND)))
    (asserts! (is-restaurant-manager (get restaurant-id employee) tx-sender) ERR-NOT-AUTHORIZED)

    (map-set employees employee-id (merge employee {status: status}))
    (ok true)
  )
)

;; Revoke certification
(define-public (revoke-certification (certification-id uint))
  (let ((certification (unwrap! (map-get? certifications certification-id) ERR-CERTIFICATION-NOT-FOUND)))
    (asserts! (or (is-authorized-trainer tx-sender) (is-eq tx-sender CONTRACT-OWNER)) ERR-NOT-AUTHORIZED)

    (map-set certifications certification-id (merge certification {status: "revoked"}))
    (ok true)
  )
)

;; Authorization functions
(define-public (add-trainer (trainer principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (map-set authorized-trainers trainer true)
    (ok true)
  )
)

(define-public (set-restaurant-manager (restaurant-id uint) (manager principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (map-set restaurant-managers restaurant-id manager)
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-employee (employee-id uint))
  (map-get? employees employee-id)
)

(define-read-only (get-certification (certification-id uint))
  (map-get? certifications certification-id)
)

(define-read-only (get-employee-certifications (employee-id uint))
  (map-get? employee-certifications employee-id)
)

(define-read-only (get-restaurant-employees (restaurant-id uint))
  (map-get? restaurant-employees restaurant-id)
)

(define-read-only (is-certification-valid (certification-id uint))
  (match (map-get? certifications certification-id)
    certification (and
      (is-eq (get status certification) "active")
      (> (get expiry-date certification) block-height))
    false)
)

(define-read-only (verify-certification (employee-id uint) (restaurant-id uint))
  (let ((employee (map-get? employees employee-id)))
    (match employee
      emp (and
        (is-eq (get restaurant-id emp) restaurant-id)
        (is-eq (get status emp) "active")
        (has-required-certifications employee-id (get position emp)))
      false))
)

(define-read-only (get-certification-requirements (certification-type (string-ascii 50)))
  (map-get? certification-requirements certification-type)
)

(define-read-only (is-authorized-trainer (trainer principal))
  (default-to false (map-get? authorized-trainers trainer))
)

;; Private functions
(define-private (is-restaurant-manager (restaurant-id uint) (user principal))
  (match (map-get? restaurant-managers restaurant-id)
    manager (is-eq manager user)
    false)
)

(define-private (has-required-certifications (employee-id uint) (position (string-ascii 50)))
  (let ((cert-list (default-to (list) (map-get? employee-certifications employee-id))))
    (has-food-handler-cert cert-list)
  )
)

(define-private (has-food-handler-cert (cert-list (list 20 uint)))
  (> (len (filter is-valid-food-handler-cert cert-list)) u0)
)

(define-private (is-valid-food-handler-cert (certification-id uint))
  (match (map-get? certifications certification-id)
    certification (and
      (is-eq (get certification-type certification) "food-handler")
      (is-certification-valid certification-id))
    false)
)
