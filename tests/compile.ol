
(require (comp "../compiler"))

(define (disambiguate exp)
  (comp.walk
   exp
   (lambda (e)
     (if (symbol? e)
         (let ((s (symbol->string e)))
           (cond
            ((== (s.indexOf "return-o") 0) 'return-x)
            ((== (s.indexOf "alt-o") 0) 'alt-x)
            ((== (s.indexOf "exit-o") 0) 'exit-x)
            (else #f)))
         #f))))

(define-macro (assert src res)
  `(let ((code (disambiguate (comp.compile ',src 'linearize #f))))
     (if (not (= code ',res))
         (throw (str "assert failed for " ',src ": \n"
                     code
                     " does not equal \n"
                     ',res)))))

(assert (define a 4)
        (global-entry
         (SET A 4)
         (SET PC POP)))

(assert (begin (define a 4) a)
        (global-entry
         (SET A 4)
         (SET J A)
         (SET PC POP)))

(assert (begin
          (define (foo x y)
            x)
          (foo 1 2))
        (global-entry
         (SET PUSH return-x)
         (SET PUSH 1)
         (SET PC global-entry-foo)
         return-x
         (SET PC POP)
         global-entry-foo
         (SET A POP)
         (SET J A)
         (SET PC POP)))

(assert (begin
          (define (bar x) x)
          (define (foo x y)
            (bar x)
            (bar y))
          (foo 4 5))
        (global-entry
         (SET PUSH return-x)
         (SET PUSH 4)
         (SET PUSH 5)
         (SET PC global-entry-foo)
         return-x
         (SET PC POP)
         global-entry-bar
         (SET A POP)
         (SET J A)
         (SET PC POP)
         global-entry-foo
         (SET B POP)
         (SET A POP)
         (SET PUSH B)
         (SET PUSH A)
         (SET PUSH return-x)
         (SET PUSH A)
         (SET PC global-entry-bar)
         return-x
         (SET A POP)
         (SET B POP)
         (SET PUSH B)
         (SET PUSH A)
         (SET PUSH return-x)
         (SET PUSH B)
         (SET PC global-entry-bar)
         return-x
         (SET A POP)
         (SET B POP)
         (SET PC POP)))

(assert (begin
          (define (add x y)
            (ADD x y)
            x)
          (add 1 2))
        (global-entry
         (SET PUSH return-x)
         (SET PUSH 1)
         (SET PUSH 2)
         (SET PC global-entry-add)
         return-x
         (SET PC POP)
         global-entry-add
         (SET B POP)
         (SET A POP)
         (ADD A B)
         (SET J A)
         (SET PC POP)))

(assert (begin
          (SET J 0)
          (if J 4 5))
        (global-entry
         (SET J 0)
         (IFE J 0)
         (SET PC alt-x)
         (SET J 4)
         (SET PC exit-x)
         alt-x
         (SET J 5)
         exit-x
         (SET PC POP)))

(assert (begin
          (define (result)
            0)
          (if (result) 4 5))
        (global-entry
         (SET PUSH return-x)
         (SET PC global-entry-result)
         return-x
         (IFE J 0)
         (SET PC alt-x)
         (SET J 4)
         (SET PC exit-x)
         alt-x
         (SET J 5)
         exit-x
         (SET PC POP)
         global-entry-result
         (SET J 0)
         (SET PC POP)))

(assert (begin
          (define-inline (+ t x y)
            (SET t x)
            (ADD t y))
          
          (define (foo x)
            (define (bar y)
              (+ x y))
            (bar 4))
          (foo 5))
        (global-entry
         (SET PUSH return-x)
         (SET PUSH 5)
         (SET PC global-entry-foo)
         return-x
         (SET PC POP)
         global-entry-foo
         (SET B POP)
         (SET PUSH B)
         (SET PUSH return-x)
         (SET PUSH 4)
         (SET PC global-entry-foo-bar)
         return-x
         (SET B POP)
         (SET PC POP)
         global-entry-foo-bar
         (SET A POP)
         (SET J B)
         (ADD J A)
         (SET PC POP)))

(assert (begin
          (DAT 1 2 3 4 5 6 7 8 9 100))
        (global-entry
          (DAT 1 2 3 4 5 6 7 8 9 100)
         (SET PC POP)))

(assert (begin
          (define a 4)
          (set! a 5))
        (global-entry
         (SET A 4)
         (SET A 5)
         (SET PC POP)))

(assert (begin
          (define a 4)
          (define b 10)
          (set! b (+ a 4)))
        (global-entry
         (SET A 4)
         (SET B 10)
         (SET B A)
         (ADD B 4)
         (SET PC POP)))
