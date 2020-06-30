(module rewind-ports
  (read char-ready? read-char peek-char port? port->rewind-port
   save-rewind-port rewind-port-seek! rewind-port-lookbehind)
  (import
    (rename scheme
      (read r5rs-read)
      (char-ready? r5rs-char-ready?)
      (read-char r5rs-read-char)
      (peek-char r5rs-peek-char))
    (rename chicken
      ; What? This is an r5rs procedure
      (port? r5rs-port?))
    ports)

(define-record-type rewind-port
  (make-rewind-port port rewind)
  rewind-port?
  (port get-port)
  (rewind get-rewind set-rewind!))
(define-record-type rewind-cursor
  (make-rewind-cursor port rewind)
  rewind-cursor?
  (port get-port-cursor)
  (rewind get-rewind-cursor))

(define (read-char-rewind port)
  (if (null? (cdr (get-rewind port)))
      (let ((char (read-char (get-port port))))
        (set-cdr! (get-rewind port) (cons char '()))
        (set-rewind! port (cdr (get-rewind port)))
        char)
      (begin
        (set-rewind! port (cdr (get-rewind port)))
        (car (get-rewind port)))))

(define (peek-char-rewind port)
  (if (null? (cdr (get-rewind port)))
      (peek-char (get-port port))
      (cadr (get-rewind port))))

(define (port->rewind-port port)
  (make-rewind-port port (cons #f '())))

(define (save-rewind-port port)
  (make-rewind-cursor (get-port port) (get-rewind port)))

(define (rewind-port-seek! port cursor)
  (if (eq? (get-port-cursor cursor) (get-port port))
      (set-rewind! port (get-rewind-cursor cursor))
      (error "seek-rewind-port!: Cursor isn't for this port.")))

(define (rewind-port-lookbehind port)
  (car (get-rewind port)))

(define port? (lambda (x) (or (r5rs-port? x) (rewind-port? x))))

(define (char-ready? port)
  (if (rewind-port? port)
      (or (pair? (cdr (get-rewind port))) (r5rs-char-ready? (get-port port)))
      (r5rs-char-ready? port)))

(define read-char
  (case-lambda
    (() (read-char (current-input-port)))
    ((port)
     (if (rewind-port? port)
         (read-char-rewind port)
         (r5rs-read-char port)))))

(define peek-char
  (case-lambda
    (() (peek-char (current-input-port)))
    ((port)
     (if (rewind-port? port)
         (peek-char-rewind port)
         (r5rs-peek-char port)))))

; It feels bad that I have to implement this.
; I was hoping that I could rely on sufficiently
; providing an interface but it looks like the
; compiled chicken scheme doesn't respond adequetly
; to my reflected 'port?'. But of course it doesn't.
; It's compiled with optimization, and everyone loves
; a good inlinin'. One man's reflection is another's indirection
(define read
  (case-lambda
    (() (read (current-input-port)))
    ((port)
     (if (rewind-port? port)
         ; It would probably be better to copy Chicken source code
         ; I hoped this would work out of the box but that stupid
         ; type-check gets in the way.
         (r5rs-read
           (make-input-port
             (lambda () (read-char port))
             (lambda () (char-ready? port))
             (lambda () 'nothing-to-close)
             (lambda () (peek-char port))))
         (r5rs-read port)))))
)
