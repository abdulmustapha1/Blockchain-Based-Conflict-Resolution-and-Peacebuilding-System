;; ceasefire-monitor.clar

;; Define a contract to monitor ceasefire agreements.

(define-constant CONTRACT-OWNER tx-sender)

;; Define data variables

(define-data-var last-ceasefire-id uint u0)

;; Define data maps

(define-map ceasefires
  { id: uint }
  {
    start-date: uint,
    end-date: uint,
    location: (string-ascii 256),
    parties: (list 10 (string-ascii 64)),
    status: (string-ascii 32),
    severity: uint,
    priority: uint,
    details: (string-ascii 1024)
  }
)

;; Define error codes

(define-constant err-unauthorized (err u100))
(define-constant err-ceasefire-not-found (err u101))
(define-constant err-invalid-date-range (err u102))
(define-constant err-invalid-severity (err u103))
(define-constant err-invalid-priority (err u104))

;; Define functions

;; Check if the sender is the contract owner
(define-read-only (is-contract-owner)
  (is-eq tx-sender CONTRACT-OWNER)
)

;; Add a new ceasefire agreement
(define-public (add-ceasefire
  (start-date uint)
  (end-date uint)
  (location (string-ascii 256))
  (parties (list 10 (string-ascii 64)))
  (severity uint)
  (priority uint)
  (details (string-ascii 1024))
)
  (begin
    ;; Validate inputs
    (asserts! (< start-date end-date) err-invalid-date-range)
    (asserts! (and (>= severity u1) (<= severity u10)) err-invalid-severity)
    (asserts! (and (>= priority u1) (<= priority u5)) err-invalid-priority)

    ;; Increment the last ceasefire ID
    (let ((new-id (+ (var-get last-ceasefire-id) u1)))
      (var-set last-ceasefire-id new-id)

      ;; Insert the new ceasefire into the map
      (map-insert ceasefires
        { id: new-id }
        {
          start-date: start-date,
          end-date: end-date,
          location: location,
          parties: parties,
          status: "Active",
          severity: severity,
          priority: priority,
          details: details
        }
      )

      (ok new-id)
    )
  )
)

;; Update the status of a ceasefire agreement
(define-public (update-ceasefire-status (id uint) (new-status (string-ascii 32)))
  (begin
    ;; Check if the sender is the contract owner
    (asserts! (is-contract-owner) err-unauthorized)

    ;; Update the ceasefire status in the map
    (match (map-get? ceasefires { id: id })
      ceasefire
      (begin
        (map-set ceasefires
          { id: id }
          (merge ceasefire { status: new-status })
        )
        (ok true)
      )
      err-ceasefire-not-found
    )
  )
)

;; Get the details of a ceasefire agreement
(define-read-only (get-ceasefire (id uint))
  (map-get? ceasefires { id: id })
)

;; Get the last ceasefire ID
(define-read-only (get-last-ceasefire-id)
  (var-get last-ceasefire-id)
)
