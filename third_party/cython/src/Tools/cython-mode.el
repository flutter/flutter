;;; cython-mode.el --- Major mode for editing Cython files

;;; Commentary:

;; This should work with python-mode.el as well as either the new
;; python.el or the old.

;;; Code:

;; Load python-mode if available, otherwise use builtin emacs python package
(when (not (require 'python-mode nil t))
  (require 'python))
(eval-when-compile (require 'rx))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.pyx\\'" . cython-mode))
;;;###autoload
(add-to-list 'auto-mode-alist '("\\.pxd\\'" . cython-mode))
;;;###autoload
(add-to-list 'auto-mode-alist '("\\.pxi\\'" . cython-mode))


(defvar cython-buffer nil
  "Variable pointing to the cython buffer which was compiled.")

(defun cython-compile ()
  "Compile the file via Cython."
  (interactive)
  (let ((cy-buffer (current-buffer)))
    (with-current-buffer
        (compile compile-command)
      (set (make-local-variable 'cython-buffer) cy-buffer)
      (add-to-list (make-local-variable 'compilation-finish-functions)
                   'cython-compilation-finish))))

(defun cython-compilation-finish (buffer how)
  "Called when Cython compilation finishes."
  ;; XXX could annotate source here
  )

(defvar cython-mode-map
  (let ((map (make-sparse-keymap)))
    ;; Will inherit from `python-mode-map' thanks to define-derived-mode.
    (define-key map "\C-c\C-c" 'cython-compile)
    map)
  "Keymap used in `cython-mode'.")

(defvar cython-font-lock-keywords
  `(;; new keywords in Cython language
    (,(regexp-opt '("by" "cdef" "cimport" "cpdef" "ctypedef" "enum" "except?"
                    "extern" "gil" "include" "nogil" "property" "public"
                    "readonly" "struct" "union" "DEF" "IF" "ELIF" "ELSE") 'words)
     1 font-lock-keyword-face)
    ;; C and Python types (highlight as builtins)
    (,(regexp-opt '("NULL" "bint" "char" "dict" "double" "float" "int" "list"
                    "long" "object" "Py_ssize_t" "short" "size_t" "void") 'words)
     1 font-lock-builtin-face)
    ;; cdef is used for more than functions, so simply highlighting the next
    ;; word is problematic. struct, enum and property work though.
    ("\\<\\(?:struct\\|enum\\)[ \t]+\\([a-zA-Z_]+[a-zA-Z0-9_]*\\)"
     1 py-class-name-face)
    ("\\<property[ \t]+\\([a-zA-Z_]+[a-zA-Z0-9_]*\\)"
     1 font-lock-function-name-face))
  "Additional font lock keywords for Cython mode.")

;;;###autoload
(defgroup cython nil "Major mode for editing and compiling Cython files"
  :group 'languages
  :prefix "cython-"
  :link '(url-link :tag "Homepage" "http://cython.org"))

;;;###autoload
(defcustom cython-default-compile-format "cython -a %s"
  "Format for the default command to compile a Cython file.
It will be passed to `format' with `buffer-file-name' as the only other argument."
  :group 'cython
  :type 'string)

;; Some functions defined differently in the different python modes
(defun cython-comment-line-p ()
  "Return non-nil if current line is a comment."
  (save-excursion
    (back-to-indentation)
    (eq ?# (char-after (point)))))

(defun cython-in-string/comment ()
  "Return non-nil if point is in a comment or string."
  (nth 8 (syntax-ppss)))

(defalias 'cython-beginning-of-statement
  (cond
   ;; python-mode.el
   ((fboundp 'py-beginning-of-statement)
    'py-beginning-of-statement)
   ;; old python.el
   ((fboundp 'python-beginning-of-statement)
    'python-beginning-of-statement)
   ;; new python.el
   ((fboundp 'python-nav-beginning-of-statement)
    'python-nav-beginning-of-statement)
   (t (error "Couldn't find implementation for `cython-beginning-of-statement'"))))

(defalias 'cython-beginning-of-block
  (cond
   ;; python-mode.el
   ((fboundp 'py-beginning-of-block)
    'py-beginning-of-block)
   ;; old python.el
   ((fboundp 'python-beginning-of-block)
    'python-beginning-of-block)
   ;; new python.el
   ((fboundp 'python-nav-beginning-of-block)
    'python-nav-beginning-of-block)
   (t (error "Couldn't find implementation for `cython-beginning-of-block'"))))

(defalias 'cython-end-of-statement
  (cond
   ;; python-mode.el
   ((fboundp 'py-end-of-statement)
    'py-end-of-statement)
   ;; old python.el
   ((fboundp 'python-end-of-statement)
    'python-end-of-statement)
   ;; new python.el
   ((fboundp 'python-nav-end-of-statement)
    'python-nav-end-of-statement)
   (t (error "Couldn't find implementation for `cython-end-of-statement'"))))

(defun cython-open-block-statement-p (&optional bos)
  "Return non-nil if statement at point opens a Cython block.
BOS non-nil means point is known to be at beginning of statement."
  (save-excursion
    (unless bos (cython-beginning-of-statement))
    (looking-at (rx (and (or "if" "else" "elif" "while" "for" "def" "cdef" "cpdef"
                             "class" "try" "except" "finally" "with"
                             "EXAMPLES:" "TESTS:" "INPUT:" "OUTPUT:")
                         symbol-end)))))

(defun cython-beginning-of-defun ()
  "`beginning-of-defun-function' for Cython.
Finds beginning of innermost nested class or method definition.
Returns the name of the definition found at the end, or nil if
reached start of buffer."
  (let ((ci (current-indentation))
        (def-re (rx line-start (0+ space) (or "def" "cdef" "cpdef" "class") (1+ space)
                    (group (1+ (or word (syntax symbol))))))
        found lep) ;; def-line
    (if (cython-comment-line-p)
        (setq ci most-positive-fixnum))
    (while (and (not (bobp)) (not found))
      ;; Treat bol at beginning of function as outside function so
      ;; that successive C-M-a makes progress backwards.
      ;;(setq def-line (looking-at def-re))
      (unless (bolp) (end-of-line))
      (setq lep (line-end-position))
      (if (and (re-search-backward def-re nil 'move)
               ;; Must be less indented or matching top level, or
               ;; equally indented if we started on a definition line.
               (let ((in (current-indentation)))
                 (or (and (zerop ci) (zerop in))
                     (= lep (line-end-position)) ; on initial line
                     ;; Not sure why it was like this -- fails in case of
                     ;; last internal function followed by first
                     ;; non-def statement of the main body.
                     ;;(and def-line (= in ci))
                     (= in ci)
                     (< in ci)))
               (not (cython-in-string/comment)))
          (setq found t)))))

(defun cython-end-of-defun ()
  "`end-of-defun-function' for Cython.
Finds end of innermost nested class or method definition."
  (let ((orig (point))
        (pattern (rx line-start (0+ space) (or "def" "cdef" "cpdef" "class") space)))
    ;; Go to start of current block and check whether it's at top
    ;; level.  If it is, and not a block start, look forward for
    ;; definition statement.
    (when (cython-comment-line-p)
      (end-of-line)
      (forward-comment most-positive-fixnum))
    (when (not (cython-open-block-statement-p))
      (cython-beginning-of-block))
    (if (zerop (current-indentation))
        (unless (cython-open-block-statement-p)
          (while (and (re-search-forward pattern nil 'move)
                      (cython-in-string/comment))) ; just loop
          (unless (eobp)
            (beginning-of-line)))
      ;; Don't move before top-level statement that would end defun.
      (end-of-line)
      (beginning-of-defun))
    ;; If we got to the start of buffer, look forward for
    ;; definition statement.
    (when (and (bobp) (not (looking-at (rx (or "def" "cdef" "cpdef" "class")))))
      (while (and (not (eobp))
                  (re-search-forward pattern nil 'move)
                  (cython-in-string/comment)))) ; just loop
    ;; We're at a definition statement (or end-of-buffer).
    ;; This is where we should have started when called from end-of-defun
    (unless (eobp)
      (let ((block-indentation (current-indentation)))
        (python-nav-end-of-statement)
        (while (and (forward-line 1)
                    (not (eobp))
                    (or (and (> (current-indentation) block-indentation)
                             (or (cython-end-of-statement) t))
                        ;; comment or empty line
                        (looking-at (rx (0+ space) (or eol "#"))))))
        (forward-comment -1))
      ;; Count trailing space in defun (but not trailing comments).
      (skip-syntax-forward " >")
      (unless (eobp)			; e.g. missing final newline
        (beginning-of-line)))
    ;; Catch pathological cases like this, where the beginning-of-defun
    ;; skips to a definition we're not in:
    ;; if ...:
    ;;     ...
    ;; else:
    ;;     ...  # point here
    ;;     ...
    ;;     def ...
    (if (< (point) orig)
        (goto-char (point-max)))))

(defun cython-current-defun ()
  "`add-log-current-defun-function' for Cython."
  (save-excursion
    ;; Move up the tree of nested `class' and `def' blocks until we
    ;; get to zero indentation, accumulating the defined names.
    (let ((start t)
          accum)
      (while (or start (> (current-indentation) 0))
        (setq start nil)
        (cython-beginning-of-block)
        (end-of-line)
        (beginning-of-defun)
        (if (looking-at (rx (0+ space) (or "def" "cdef" "cpdef" "class") (1+ space)
                            (group (1+ (or word (syntax symbol))))))
            (push (match-string 1) accum)))
      (if accum (mapconcat 'identity accum ".")))))

;;;###autoload
(define-derived-mode cython-mode python-mode "Cython"
  "Major mode for Cython development, derived from Python mode.

\\{cython-mode-map}"
  (setcar font-lock-defaults
          (append python-font-lock-keywords cython-font-lock-keywords))
  (set (make-local-variable 'outline-regexp)
       (rx (* space) (or "class" "def" "cdef" "cpdef" "elif" "else" "except" "finally"
                         "for" "if" "try" "while" "with")
           symbol-end))
  (set (make-local-variable 'beginning-of-defun-function)
       #'cython-beginning-of-defun)
  (set (make-local-variable 'end-of-defun-function)
       #'cython-end-of-defun)
  (set (make-local-variable 'compile-command)
       (format cython-default-compile-format (shell-quote-argument buffer-file-name)))
  (set (make-local-variable 'add-log-current-defun-function)
       #'cython-current-defun)
  (add-hook 'which-func-functions #'cython-current-defun nil t)
  (add-to-list (make-local-variable 'compilation-finish-functions)
               'cython-compilation-finish))

(provide 'cython-mode)

;;; cython-mode.el ends here
