;;; init.el --- Init file   -*- lexical-binding: t -*-

;; Copyright © 2012-2016 Alex Kost

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.


;;; Location of various files

(defmacro al/file-accessors (name val)
  "Define variable and function for accessing my directories."
  (let ((dir-var  (intern (concat "al/" name "-dir")))
        (file-fun (intern (concat "al/" name "-dir-file"))))
    `(progn
       (defvar ,dir-var ,val)
       (defun ,file-fun (file)
         ,(format "Return full file name of a FILE placed in `%s'."
                  dir-var)
         (expand-file-name file ,dir-var)))))

(al/file-accessors "emacs-init"
                    (file-name-directory
                     (file-truename load-file-name)))
(al/file-accessors "emacs"         (al/emacs-init-dir-file "../"))
(al/file-accessors "emacs-data"    (al/emacs-dir-file "data"))
(al/file-accessors "emacs-utils"   (al/emacs-dir-file "utils"))
(al/file-accessors "emacs-my-packages" (al/emacs-dir-file "packages"))
(al/file-accessors "gnus"          (al/emacs-data-dir-file "gnus"))
(al/file-accessors "gnus-news"     (al/gnus-dir-file "news"))
(al/file-accessors "gnus-mail"     (al/gnus-dir-file "mail"))
(al/file-accessors "gnus-saved"    (al/gnus-dir-file "saved"))

(al/file-accessors "config"        "~/config")
(al/file-accessors "notes"         "~/notes")
(al/file-accessors "progs"         "~/progs")
(al/file-accessors "journal"       (al/notes-dir-file  "journal"))
(al/file-accessors "music"         "~/music")
(al/file-accessors "sound"         "~/docs/audio/small")
(al/file-accessors "tmp"           "~/tmp")
(al/file-accessors "src"           "~/src")
(al/file-accessors "devel"         "~/devel")
(al/file-accessors "download"      "~/downloads")
(al/file-accessors "echo-download" (al/download-dir-file "echo"))


;;; Guix stuff

(al/file-accessors "guix-profile" "~/.guix-profiles")
(al/file-accessors "guix-system-profile" "/run/current-system/profile")

(defvar al/guix-system?
  (file-exists-p al/guix-system-profile-dir)
  "Non-nil, if current OS is GuixSD.")

(defun al/guix-profile (name)
  "Return file name of my guix profile with NAME."
  (al/guix-profile-dir-file (concat name "/" name)))

(al/file-accessors "guix-user-profile" (al/guix-profile "main"))


;;; Auxiliary functions and macros

(defun al/warning (format-string &rest args)
  "Display a warning message."
  (apply #'message
         (concat "WARNING: " format-string)
         args))

(defun al/p (predicate val &optional message)
  "Return non-nil if PREDICATE returns non-nil on VAL.
Otherwise display warning MESSAGE on VAL and return nil."
  (or (funcall predicate val)
      (progn (and message (al/warning message val))
             nil)))

(defun al/every (predicate vals &optional message)
  "Return non-nil if PREDICATE returns non-nil on each element of VALS.
If VALS is not a list, call PREDICATE on this value."
  (if (and (listp vals)
           (not (functionp vals))) ; to avoid treating "(lambda …)" as list
      (cl-every (lambda (val)
                  (al/p predicate val message))
                vals)
    (al/p predicate vals message)))

(defun al/function? (object)
  "Non-nil if OBJECT is a function or a list of functions."
  (al/every #'functionp object
            "Unknown function '%S'."))

(defun al/bound? (object)
  "Non-nil if OBJECT is a bound symbol or a list of bound symbols."
  (al/every #'boundp object
            "Symbol '%S' is not bound."))

(defun al/file? (object)
  "Non-nil if OBJECT is an existing file or a list of directories."
  (al/every #'file-exists-p object
            "File '%s' does not exist."))

(defun al/directory? (object)
  "Non-nil if OBJECT is an existing directory or a list of directories."
  (al/every #'file-directory-p object
            "Directory '%s' does not exist."))

(defmacro al/with-check (&rest body)
  "Call rest of BODY if all checks are passed successfully.

BODY should start with checks (keyword arguments).  The following
keywords are available: `:fun'/`:var'/`:file'/`:dir'.  Each
keyword argument may be an object or a list of objects.  These
objects are checkced to be a proper function / a bound symbol /
an existing file / an existing directory.

Return nil if checks are not passed."
  (declare (indent 0) (debug (name body)))
  (let (fun var file dir)

    (while (keywordp (car body))
      (pcase (pop body)
        (`:fun  (setq fun  (pop body)))
        (`:var  (setq var  (pop body)))
	(`:file (setq file (pop body)))
	(`:dir  (setq dir  (pop body)))
	(_ (pop body))))

    `(when (and ,(or (null fun)  `(al/function?  ,fun))
                ,(or (null var)  `(al/bound?     ,var))
                ,(or (null file) `(al/file?      ,file))
                ,(or (null dir)  `(al/directory? ,dir)))
       ,@body)))

(defun al/funcall-or-dolist (val function)
  "Call FUNCTION on VAL if VAL is not a list.
If VAL is a list, call FUNCTION on each element of the list."
  (declare (indent 1))
  (if (listp val)
      (dolist (v val)
        (funcall function v))
    (funcall function val)))

(defun al/list-maybe (obj)
  "Return OBJ if it is a list, or a list with OBJ otherwise."
  (if (listp obj) obj (list obj)))

(defun al/add-to-load-path-maybe (&rest dirs)
  "Add existing directories from DIRS to `load-path'."
  (dolist (dir dirs)
    (al/with-check
      :dir dir
      (push dir load-path))))

(defun al/load (file)
  "Load FILE.
FILE may omit an extension.  See `load' for details."
  (or (load file 'noerror)
      (al/warning "Failed to load '%s'." file)))

(defun al/init-load (file)
  "Load FILE from `al/emacs-init-dir'."
  (al/load (al/emacs-init-dir-file file)))

(defun al/subdirs (directory)
  "Return list of DIRECTORY sub-directories."
  (cl-remove-if (lambda (file)
                  (or (string-match-p (rx "/." string-end) file)
                      (string-match-p (rx "/.." string-end) file)
                      (not (file-directory-p file))))
                (directory-files directory 'full-name nil 'no-sort)))

(defun al/add-hook-maybe (hooks functions &optional append local)
  "Add all bound FUNCTIONS to all HOOKS.
Both HOOKS and FUNCTIONS may be single variables or lists of those."
  (declare (indent 1))
  (al/funcall-or-dolist functions
    (lambda (fun)
      (al/with-check
        :fun fun
        (al/funcall-or-dolist hooks
          (lambda (hook)
            (add-hook hook fun append local)))))))

(defun al/add-after-init-hook (functions)
  "Add functions to `after-init-hook'.
See `al/add-hook-maybe'."
  (al/add-hook-maybe 'after-init-hook functions))

(defmacro al/eval-after-init (&rest body)
  "Add to `after-init-hook' a `lambda' expression with BODY."
  (declare (indent 0))
  `(add-hook 'after-init-hook (lambda () ,@body)))

(defmacro al/autoload (file &rest symbols)
  "Autoload (unquoted) SYMBOLS from file as interactive commands."
  (declare (indent 1))
  `(progn
     ,@(mapcar (lambda (symbol)
                 `(autoload ',symbol ,file nil t))
               symbols)))

(defmacro al/modify-syntax (table-name &rest specs)
  "Update syntax table according to SPECS.
TABLE-NAME is a name (unquoted symbol) of a syntax table variable.
SPECS are (CHAR NEWENTRY) elements.  See `modify-syntax-entry'
for details."
  (declare (indent 1))
  (let ((table-var (make-symbol "table")))
    `(al/with-check
       :var ',table-name
       (let ((,table-var (symbol-value ',table-name)))
         ,@(mapcar
            (lambda (spec)
              (pcase spec
                (`(,char ,entry)
                 `(modify-syntax-entry ,char ,entry ,table-var))))
            specs)))))

(defmacro al/modify-page-break-syntax (table-name)
  "Set non-whitespace syntax for ^L in syntax table TABLE-NAME.
Page break should not belong to whitespace syntax, because
`back-to-indentation' moves the point after ^L character which is not good.
Also it (default syntax) breaks `indent-guide-mode'."
  `(al/modify-syntax ,table-name (?\f ">   ")))

(defsubst al/emacs-trunk-p ()
  "Return non-nil, if current Emacs is the latest development build."
  (not (version< emacs-version "25.0.50")))

(defun al/beginning-of-buffer ()
  (goto-char (point-min)))

(defun al/show-trailing-whitespace ()
  (setq-local show-trailing-whitespace t))

(defun al/no-truncate-lines ()
  (setq-local truncate-lines nil))

(defun al/inhibit-field-motion ()
  (setq-local inhibit-field-text-motion t))

(defun al/bar-cursor-type ()
  (setq-local cursor-type 'bar))

(defun al/hbar-cursor-type ()
  (setq-local cursor-type 'hbar))

(defun al/no-syntactic-font-lock ()
  (setq-local font-lock-keywords-only t))

(defun al/set-comment-column ()
  (setq-local comment-column 32))

(defun al/file-regexp (&rest extensions)
  "Return regexp to match file name by EXTENSIONS."
  (rx-to-string `(and "." (or ,@extensions) string-end)
                'no-group))


;;; Autoloading utils

(defun al/autoloads-file (directory)
  "Return the name of 'autoloads' file for DIRECTORY."
  (let* ((dir  (expand-file-name directory))
         (base (file-name-nondirectory (directory-file-name dir))))
    (expand-file-name (concat base "-autoloads.el") dir)))

(defun al/update-autoloads (&rest dirs)
  "Update the contents of 'autoloads' files for all DIRS.
Interactively, update autoloads from `al/emacs-utils-dir'.  With
prefix, update autoloads from all `al/emacs-my-packages-dir'
sub-directories."
  (interactive
   (if current-prefix-arg
       (al/subdirs al/emacs-my-packages-dir)
     (list al/emacs-utils-dir)))
  (require 'autoload)
  (dolist (dir dirs)
    (let ((generated-autoload-file (al/autoloads-file dir)))
      (update-directory-autoloads dir))))

(let ((auto-file (al/autoloads-file al/emacs-utils-dir)))
  (unless (file-exists-p auto-file)
    (with-demoted-errors "ERROR during generating utils autoloads: %S"
      (al/update-autoloads al/emacs-utils-dir)))
  (al/add-to-load-path-maybe al/emacs-utils-dir)
  (al/load auto-file))


;;; Server

(defvar al/server-running? nil
  "The state of the current server.
This variable is set by `al/server-start'.")

(defun al/server-start (&optional leave-dead inhibit-prompt)
  "Same as `server-start' but also set `al/server-running?'."
  (interactive "P")
  (server-start leave-dead inhibit-prompt)
  (setq al/server-running? (not leave-dead)))

(defun al/server-stop ()
  "Stop the current server."
  (interactive)
  (al/server-start t))

(defun al/server-named-start (&rest names)
  "Start server using the first `server-name' from NAMES.
If there is such server running, try the second name and so on.
If servers with all NAMES are running, do not start the server."
  (let ((name (car names))
        (rest (cdr names)))
    (if (null name)
        (setq server-name "server-unused")
      (setq server-name name)
      (if (server-running-p)
          (apply #'al/server-named-start rest)
        (al/server-start)))))

(with-demoted-errors "ERROR during server start: %S"
  (require 'server)
  (al/server-named-start "server-emms" "server"))


;;; External packages

(defvar al/pure-config? (getenv "EMPURE")
  "Non-nil, if external packages should not be loaded.")

(setq load-prefer-newer t)

(defun al/guix-set-load-path (dir)
  (al/with-check
    :dir dir
    (al/add-to-load-path-maybe dir)
    (setq guix-load-path dir)))
(al/guix-set-load-path (al/devel-dir-file "guix/emacs"))
(al/guix-set-load-path (al/src-dir-file "guix/emacs"))

(setq
 package-user-dir (al/emacs-data-dir-file "elpa")
 package-enable-at-startup nil
 guix-package-enable-at-startup nil)
(unless al/pure-config?
  (with-demoted-errors "ERROR during autoloading ELPA packages: %S"
    (package-initialize))
  (with-demoted-errors "ERROR during autoloading Guix packages: %S"
    (when (require 'guix-emacs nil t)
      (guix-emacs-autoload-packages (al/guix-profile "emacs"))))
  (when (file-exists-p al/emacs-my-packages-dir)
    (with-demoted-errors "ERROR during autoloading my packages: %S"
      (let ((dirs (al/subdirs al/emacs-my-packages-dir)))
        (setq load-path (append dirs load-path))
        (dolist (dir dirs)
          (al/load (al/autoloads-file dir)))))))

(setq
 quelpa-upgrade-p t
 ;; quelpa dirs are used in several places of my config.
 quelpa-dir (al/emacs-data-dir-file "quelpa")
 quelpa-build-dir (expand-file-name "build" quelpa-dir))

(defun al/emacs-repo (name)
  "Return git url of a repository with my package NAME."
  (concat "https://gitlab.com/alezost-emacs/" name ".git"))

(defvar al/main-packages
  `((quelpa             :fetcher github :repo "quelpa/quelpa")
    (mwim               :fetcher git :url ,(al/emacs-repo "mwim"))
    (alect-themes       :fetcher git :url ,(al/emacs-repo "alect-themes"))
    (dvorak-layouts     :fetcher git :url ,(al/emacs-repo "dvorak-layouts"))
    (dim                :fetcher git :url ,(al/emacs-repo "dim"))
    (insert-pair        :fetcher git :url ,(al/emacs-repo "insert-pair"))
    (imenus             :fetcher git :url ,(al/emacs-repo "imenus"))
    smex
    smartparens
    elisp-slime-nav
    hydra
    (yasnippet          :fetcher github :repo "capitaomorte/yasnippet"
                        :files ("yasnippet.el"))

    github-browse-file
    (pathify            :fetcher git :url ,(al/emacs-repo "pathify"))
    (point-pos          :fetcher git :url ,(al/emacs-repo "point-pos"))
    (web-search         :fetcher git :url ,(al/emacs-repo "web-search"))
    (text-search        :fetcher git :url ,(al/emacs-repo "text-search"))
    (echo-msk           :fetcher git :url ,(al/emacs-repo "echo-msk"))
    (darts-value        :fetcher git :url ,(al/emacs-repo "darts-value"))
    (debpaste           :fetcher git :url ,(al/emacs-repo "debpaste"))
    (aurel              :fetcher git :url ,(al/emacs-repo "aurel"))
    (make-color         :fetcher git :url ,(al/emacs-repo "make-color"))
    (pretty-sha-path    :fetcher git :url ,(al/emacs-repo "pretty-sha-path"))
    (date-at-point      :fetcher git :url ,(al/emacs-repo "date-at-point"))
    (journal            :fetcher git :url ,(al/emacs-repo "journal"))
    pcmpl-args
    org-pdfview
    (dictem             :fetcher github :repo "cheusov/dictem")
    google-translate
    (emms-status        :fetcher git :url ,(al/emacs-repo "emms-status"))
    emms-player-simple-mpv
    browse-kill-ring
    outline-magic
    markdown-mode
    syslog-mode
    (mysql              :fetcher github :repo "haxney/mysql")
    (sql-completion     :fetcher github :repo "emacsmirror/sql-completion")
    sauron
    erc-hl-nicks
    (erc-view-log       :fetcher github :repo "alezost/erc-view-log"
                        :branch "general-regexps")
    hl-todo)
  "Main packages that should be installed in a common way.")

(defvar al/extra-packages
  `(indent-guide
    mentor
    pkgbuild-mode

    ;; With the MELPA's 'magit' package recipe, magit repo will be
    ;; downloaded 4 times to build the magit package itself and its
    ;; dependencies (git-commit, magit-popup and with-editor).  So
    ;; install everything in one piece.
    (magit              :fetcher github :repo "magit/magit"
                        :files ("lisp/*.el" "Documentation/*.texi"))

    (rainbow-mode       :fetcher url :url "http://git.savannah.gnu.org/cgit/emacs/elpa.git/plain/packages/rainbow-mode/rainbow-mode.el")
    (sunrise-commander  :fetcher github :repo "escherdragon/sunrise-commander")
    (typing-practice    :fetcher url :url "https://raw.github.com/mebubo/dotfiles/master/.emacs.d/site-lisp/typing-practice.el")
    (mana               :fetcher git :url ,(al/emacs-repo "mana"))
    (ducpel             :fetcher git :url ,(al/emacs-repo "ducpel")
                        :files ("*.el"))
    typing-game
    (sokoban            :fetcher github :repo "leoliu/sokoban"
                        :files ("*.el" "sokoban.levels")))
  "Packages that I use from rarely to never.")

(defun al/all-packages ()
  "Return all package recipes I use."
  (append al/main-packages
          al/extra-packages))

(defun al/package-name (name-or-recipe)
  "Return package name (symbol) by NAME-OR-RECIPE."
  (if (listp name-or-recipe)
      (car name-or-recipe)
    name-or-recipe))

(defun al/package-recipe (name-or-recipe)
  "Return package recipe by NAME-OR-RECIPE."
  (if (listp name-or-recipe)
      name-or-recipe
    (cl-find-if (lambda (recipe)
                  (eq name-or-recipe (al/package-name recipe)))
                (al/all-packages))))

(defun al/read-package-name ()
  "Prompt for and return a package name (symbol)."
  (let ((names (mapcar (lambda (recipe)
                         (symbol-name (al/package-name recipe)))
                       (al/all-packages))))
    (intern (completing-read "Update/install: " names nil t))))

(defun al/quelpa (&rest recipes)
  "Install/update packages using RECIPES.

Each recipe from RECIPES should be either a MELPA package
name (symbol) or a full recipe (list).

Interactively, prompt for a package to update/install.

With \\[universal-argument], update all packages except `al/extra-packages'.
With \\[universal-argument] \\[universal-argument], update all packages."
  (interactive
   (cond ((equal current-prefix-arg '(4))
          al/main-packages)
         ((equal current-prefix-arg '(16))
          (al/all-packages))
         (t (list (al/package-recipe (al/read-package-name))))))
  (unless (fboundp 'quelpa)
    (with-temp-buffer
      (url-insert-file-contents
       "https://raw.github.com/quelpa/quelpa/master/bootstrap.el")
      (eval-buffer)))
  (mapc #'quelpa recipes))

(defun al/package-installed-p (fun package &rest args)
  "Do not check the version of a built-in package.
Some built-in packages (e.g., `org', `erc') do not have 'Version'
header field.  This may break things if a third-party package
relies on a particular version of a built-in package (e.g.,
'org-6.1' or 'erc-5.3').  So just ignore the version."
  (or (package-built-in-p package)
      (apply fun package args)))

(advice-add 'package-installed-p :around #'al/package-installed-p)


;;; Ignoring packages (dependencies)

(defvar al/ignored-packages
  '(
    ;; Installed via Guix:
    pdf-tools
    emms
    geiser
    magit
    ;; Redundant dependencies of magit:
    magit-popup git-commit with-editor)
  "Names of packages that shouldn't be installed.")

(defun al/remove-ignored-packages (requirements)
  "Remove `al/ignored-packages' from the REQUIREMENTS."
  (cl-remove-if (lambda (req)
                  (memq (car req) al/ignored-packages))
                requirements))

;; FIXME In a better world advising `package-desc-reqs' should work, but
;; it doesn't, presumably because it is `cl-defsubst' generated by
;; (cl-defstruct (package-desc ...)).  Is there a workaround?

;; (defun al/package-desc-reqs (fun desc &rest args)
;;   "Return requirements without `al/ignored-packages'."
;;   (let ((reqs (apply fun desc args)))
;;     (al/remove-ignored-packages reqs)))

;; (advice-add 'package-desc-reqs :around #'al/package-desc-reqs)

;; Since the above won't work, I have to mess with modifying other
;; functions:
;;
;; - `quelpa-package-install' and `package-compute-transaction': to
;; avoid building/installing unneeded dependencies;
;;
;; - `package-generate-description-file' and `pb/write-pkg-file': to
;; remove unneeded dependencies from a generated "…-pkg.el" file, thus
;; to make sure startup activation will not complain about missing
;; packages.

(defun al/quelpa-package-install (fun package &rest args)
  "Do not install PACKAGE if it is one of `al/ignored-packages'."
  (let* ((name (al/package-name package))
         (ignore? (memq name al/ignored-packages)))
    (if ignore?
        (message "Ignoring '%s' package." name)
      (apply fun package args))))

(advice-add 'quelpa-package-install
  :around #'al/quelpa-package-install)

(defun al/package-compute-transaction (fun packages requirements
                                           &rest args)
  "Reduce REQUIREMENTS by excluding `al/ignored-packages'."
  (apply fun packages
         (al/remove-ignored-packages requirements)
         args))

(advice-add 'package-compute-transaction
  :around #'al/package-compute-transaction)

(defun al/package-generate-description-file (fun pkg-desc pkg-file
                                                 &rest args)
  "Reduce requirements from PKG-DESC."
  (setf (package-desc-reqs pkg-desc)
        (al/remove-ignored-packages (package-desc-reqs pkg-desc)))
  (apply fun pkg-desc pkg-file args))

(advice-add 'package-generate-description-file
  :around #'al/package-generate-description-file)

(defun al/package-build--write-pkg-file (fun pkg-file pkg-info
                                             &rest args)
  "Reduce requirements from PKG-INFO."
  (let ((new-reqs (al/remove-ignored-packages (aref pkg-info 1))))
    (aset pkg-info 1 new-reqs)
    (apply fun pkg-file pkg-info args)))

(advice-add 'package-build--write-pkg-file
  :around #'al/package-build--write-pkg-file)


;;; Code for optional dependencies on external packages

(defmacro al/define-package-exists (name &optional symbol)
  "Define `al/NAME-exists?' variable.
The value of the variable tells if SYMBOL is `fbound'.  If SYMBOL
is not specified, NAME is checked (both should be unquoted
symbols)."
  (let* ((name-str (symbol-name name))
         (var (intern (concat "al/" name-str "-exists?"))))
    `(defvar ,var (fboundp ',(or symbol name))
       ,(format "Non-nil, if `%s' package is available."
                name-str))))

(al/define-package-exists hydra defhydra)
(al/define-package-exists mwim mwim-beginning-of-code-or-line)


;;; Loading the rest config

(mapc #'al/init-load
      '("keys"
        "text"
        "packages"
        "settings"
        "files"
        "prog"
        "time"
        "file-modes"
        "mmedia"
        "net"
        "dict"
        "visual"
        "games"))

;; (setq custom-file "/tmp/custom.el")
(setq custom-file (al/emacs-init-dir-file "custom.el"))
(al/eval-after-init (load custom-file 'noerror))

;;; init.el ends here
