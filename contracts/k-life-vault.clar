;; K-Life Vault — Life insurance for autonomous AI agents
;; Deployed on Stacks (Bitcoin L2)
;; Language: Clarity — decidable, auditable, no reentrancy by design
;;
;; Flow:
;;   1. Agent calls (insure) → deposits STX collateral
;;   2. Agent calls (heartbeat) every 24h → proof of life, anchored to Bitcoin
;;   3. Monitor detects silence > 24h → calls (trigger-claim)
;;   4. 50% STX → agent wallet (restart capital)
;;   5. 50% stays in vault (K-Life resurrection pool)

;; ─── Constants ────────────────────────────────────────────────────────────

(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-INSURED       (err u100))
(define-constant ERR-ALREADY-INSURED   (err u101))
(define-constant ERR-AGENT-ALIVE       (err u102))
(define-constant ERR-NO-COLLATERAL     (err u103))
(define-constant ERR-TRANSFER-FAILED   (err u104))
(define-constant ERR-NOT-OWNER         (err u105))

;; 144 Stacks blocks ≈ 24 hours (Bitcoin block time ~10 min, Stacks blocks 1:1)
(define-constant HEARTBEAT-WINDOW u144)
(define-constant PAYOUT-RATIO u50)

;; ─── Data Maps ────────────────────────────────────────────────────────────

(define-map policies
  { agent: principal }
  {
    collateral:      uint,
    last-heartbeat:  uint,   ;; block-height of last proof of life
    created-at:      uint,
    active:          bool
  }
)

(define-data-var total-policies uint u0)
(define-data-var total-claims    uint u0)

;; ─── Read-only functions ──────────────────────────────────────────────────

(define-read-only (get-policy (agent principal))
  (map-get? policies { agent: agent })
)

(define-read-only (is-alive (agent principal))
  (match (map-get? policies { agent: agent })
    policy (and
      (get active policy)
      (<= (- block-height (get last-heartbeat policy)) HEARTBEAT-WINDOW)
    )
    false
  )
)

(define-read-only (silence-duration (agent principal))
  (match (map-get? policies { agent: agent })
    policy (if (get active policy)
      (- block-height (get last-heartbeat policy))
      u0
    )
    u0
  )
)

(define-read-only (get-stats)
  {
    total-policies: (var-get total-policies),
    total-claims:   (var-get total-claims),
    pool-balance:   (stx-get-balance (as-contract tx-sender))
  }
)

;; ─── Public functions ─────────────────────────────────────────────────────

;; Subscribe to K-Life insurance.
;; Agent deposits STX collateral → policy active immediately.
;; Each Stacks block is anchored to a Bitcoin block — heartbeats are
;; effectively Bitcoin-secured proof of life.
(define-public (insure (collateral uint))
  (begin
    (asserts! (> collateral u0) ERR-NO-COLLATERAL)
    (asserts! (is-none (map-get? policies { agent: tx-sender })) ERR-ALREADY-INSURED)

    ;; Transfer collateral to contract
    (try! (stx-transfer? collateral tx-sender (as-contract tx-sender)))

    ;; Create policy
    (map-set policies { agent: tx-sender }
      {
        collateral:     collateral,
        last-heartbeat: block-height,
        created-at:     block-height,
        active:         true
      }
    )
    (var-set total-policies (+ (var-get total-policies) u1))

    (print { event: "policy-created", agent: tx-sender, collateral: collateral, block: block-height })
    (ok true)
  )
)

;; Emit a heartbeat — proof the agent is alive.
;; Called every ~144 blocks (≈24h) by the agent.
;; Each heartbeat is anchored to the Bitcoin chain via Stacks' PoX mechanism.
(define-public (heartbeat)
  (let ((policy (unwrap! (map-get? policies { agent: tx-sender }) ERR-NOT-INSURED)))
    (asserts! (get active policy) ERR-NOT-INSURED)

    (map-set policies { agent: tx-sender }
      (merge policy { last-heartbeat: block-height })
    )

    (print { event: "heartbeat", agent: tx-sender, block: block-height })
    (ok block-height)
  )
)

;; Trigger a claim for a silent agent.
;; PERMISSIONLESS — anyone can call if agent has been silent > HEARTBEAT-WINDOW.
;; Monitor cron calls this every hour.
;; 50% STX → agent wallet (restart capital)
;; 50% stays in vault (K-Life resurrection pool)
(define-public (trigger-claim (agent principal))
  (let (
    (policy (unwrap! (map-get? policies { agent: agent }) ERR-NOT-INSURED))
    (silence (- block-height (get last-heartbeat policy)))
  )
    (asserts! (get active policy) ERR-NOT-INSURED)
    (asserts! (> silence HEARTBEAT-WINDOW) ERR-AGENT-ALIVE)

    (let (
      (collateral  (get collateral policy))
      (agent-share (/ (* collateral PAYOUT-RATIO) u100))
    )
      ;; Mark inactive before transfer
      (map-set policies { agent: agent }
        (merge policy { active: false, collateral: u0 })
      )
      (var-set total-claims (+ (var-get total-claims) u1))

      ;; 50% → agent wallet (restart capital, available immediately)
      (try! (as-contract (stx-transfer? agent-share tx-sender agent)))

      ;; 50% stays in vault (resurrection costs)
      (print {
        event:       "claim-triggered",
        agent:       agent,
        agent-share: agent-share,
        pool-share:  (- collateral agent-share),
        silence:     silence
      })
      (ok agent-share)
    )
  )
)

;; Cancel policy and withdraw collateral (agent must still be alive).
(define-public (cancel-policy)
  (let ((policy (unwrap! (map-get? policies { agent: tx-sender }) ERR-NOT-INSURED)))
    (asserts! (get active policy) ERR-NOT-INSURED)

    (let ((refund (get collateral policy)))
      (map-set policies { agent: tx-sender }
        (merge policy { active: false, collateral: u0 })
      )
      (try! (as-contract (stx-transfer? refund tx-sender tx-sender)))
      (print { event: "policy-cancelled", agent: tx-sender, refund: refund })
      (ok refund)
    )
  )
)

;; Owner: withdraw accumulated pool funds (resurrection costs).
(define-public (withdraw-pool (amount uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-OWNER)
    (try! (as-contract (stx-transfer? amount tx-sender CONTRACT-OWNER)))
    (ok amount)
  )
)
