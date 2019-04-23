;;; core/autoload/message.el -*- lexical-binding: t; -*-

(defvar doom-ansi-alist
  '(;; fx
    (bold       1 :weight bold)
    (dark       2)
    (italic     3 :slant italic)
    (underscore 4 :underline t)
    (blink      5)
    (rapid      6)
    (contrary   7)
    (concealed  8)
    (strike     9 :strike-through t)
    ;; fg
    (black      30 term-color-black)
    (red        31 term-color-red)
    (green      32 term-color-green)
    (yellow     33 term-color-yellow)
    (blue       34 term-color-blue)
    (magenta    35 term-color-magenta)
    (cyan       36 term-color-cyan)
    (white      37 term-color-white)
    ;; bg
    (on-black   40 term-color-black)
    (on-red     41 term-color-red)
    (on-green   42 term-color-green)
    (on-yellow  43 term-color-yellow)
    (on-blue    44 term-color-blue)
    (on-magenta 45 term-color-magenta)
    (on-cyan    46 term-color-cyan)
    (on-white   47 term-color-white))
  "TODO")

;;;###autoload
(defun doom-color-apply (style text)
  "Apply CODE to formatted MESSAGE with ARGS. CODE is derived from any of
`doom-message-fg', `doom-message-bg' or `doom-message-fx'.

In a noninteractive session, this wraps the result in ansi color codes.
Otherwise, it maps colors to a term-color-* face."
  (let ((code (cadr (assq style doom-ansi-alist))))
    (if noninteractive
        (format "\e[%dm%s\e[%dm"
                (cadr (assq style doom-ansi-alist))
                text 0)
      (require 'term)  ; piggyback on term's color faces
      (propertize
       text 'face
       (append (get-text-property 0 'face text)
               (cond ((>= code 40)
                      `(:background ,(caddr (assq style doom-ansi-alist))))
                     ((>= code 30)
                      `(:foreground ,(face-foreground (caddr (assq style doom-ansi-alist)))))
                     ((cddr (assq style doom-ansi-alist)))))))))

(defun doom--short-color-replace (forms)
  "Replace color-name functions with calls to `doom-color-apply'."
  (cond ((null forms) nil)
        ((listp forms)
         (append (cond ((not (symbolp (car forms)))
                        (list (doom--short-color-replace (car forms))))
                       ((assq (car forms) doom-ansi-alist)
                        `(doom-color-apply ',(car forms)))
                       ((eq (car forms) 'color)
                        (pop forms)
                        `(doom-color-apply ,(car forms)))
                       ((list (car forms))))
                 (doom--short-color-replace (cdr forms))
                 nil))
        (forms)))

;;;###autoload
(defmacro format! (message &rest args)
  "An alternative to `format' that understands (color ...) and converts them
into faces or ANSI codes depending on the type of sesssion we're in."
  `(format ,@(doom--short-color-replace `(,message ,@args))))

;;;###autoload
(defmacro print! (message &rest args)
  "Uses `message' in interactive sessions and `princ' otherwise (prints to
standard out).

Can be colored using (color ...) blocks:

  (print! \"Hello %s\" (bold (blue \"How are you?\")))
  (print! \"Hello %s\" (red \"World\"))
  (print! (green \"Great %s!\") \"success\")

Uses faces in interactive sessions and ANSI codes otherwise."
  `(progn (princ (format! ,message ,@args))
          (terpri)))
