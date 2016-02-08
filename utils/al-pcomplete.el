;;; al-pcomplete.el --- Additional functionality for pcomplete

;; Author: Alex Kost <alezost@gmail.com>
;; Created: 9 Jun 2015

;;; Code:

(defun al/pcomplete-no-space ()
  "Do not terminate a completion with space in the current buffer."
  (setq-local pcomplete-termination-string ""))

(provide 'al-pcomplete)

;;; al-pcomplete.el ends here