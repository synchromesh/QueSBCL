;;;; QueSBCL/lisp/interface.lisp - Declare/define FFI to QueSBCL GDExtension plugin.
;;;; File Created: 24 September 2025
;;;; Author: John Pallister <john@synchromesh.com>
;;;;
;;;; We define *CALLABLE-EXPORTS* that will be passed to SAVE-LISP-AND-DIE in
;;;; QueSBCL/etc/make-libcore.sh.

(defparameter *clicks* 0)

(define-alien-callable hello sb-alien:c-string ()
  (format nil "Hello alien world! [clicks: ~a]" (incf *clicks*)))

(defvar *callable-exports* '(hello))

;;;; End of interface.lisp
