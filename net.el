;;; net.el --- Browsing, mail, chat, network utils; w3m, wget, …

;; Copyright © 2014-2015 Alex Kost

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


;;; Global keys

(bind-keys
 :prefix-map al/net-map
 :prefix-docstring "Map for net utils."
 :prefix "C-w"
 ("p" . utl-ping)
 ("t" . utl-traceroute)
 ("w" . wget)
 ("m" . utl-url-wget-mp3))

(bind-keys*
 :prefix-map al/web-search-map
 :prefix-docstring "Map for web-search commands and browsing URLs."
 :prefix "M-S"
 ("M-S" . web-search)
 ("d"   . web-search-duckduckgo)
 ("y"   . web-search-yandex)
 ("g"   . web-search-github)
 ("G"   . web-search-google)
 ("w e" . web-search-wikipedia-en)
 ("w r" . web-search-wikipedia-ru)
 ("W"   . web-search-wiktionary-en)
 ("m"   . web-search-multitran)
 ("a"   . web-search-archwiki)
 ("A"   . web-search-arch-package)
 ("e"   . web-search-emacswiki)
 ("i"   . web-search-ipduh)
 ("I"   . web-search-ip-address)
 ("b"   . web-search-debbugs)
 ("`"   . web-search-ej)
 ("t"   . (lambda () (interactive)
            (w3m-browse-url "http://m.tv.yandex.ru/4")))
 ("l"   . utl-browse-irc-log)
 ("L"   . (lambda () (interactive)
            (utl-browse-irc-log
             "guix"
             (format-time-string
              "%Y-%m-%d"
              (time-subtract (current-time)
                             (seconds-to-time (* 24 60 60))))))))


;;; Browsing

(use-package w3m
  :defer t
  :config
  (setq
   w3m-confirm-leaving-secure-page nil
   w3m-use-title-buffer-name t  ; don't duplicate title in the mode-line
   w3m-show-graphic-icons-in-mode-line nil
   w3m-modeline-image-status-on "🌼"
   w3m-modeline-status-off ""
   w3m-modeline-separator "")

  (defconst al/w3m-keys
    '("c" "u" "k"
      ("C-ь a"       (emms-add-url (w3m-anchor)))
      ("C-ь p"       (emms-play-url (w3m-anchor)))
      ("i"         . w3m-toggle-inline-images)
      ("I"         . w3m-toggle-inline-image)
      ("b"         . w3m-bookmark-view)
      ("y"         . w3m-history)
      (","         . w3m-view-previous-page)
      ("p"         . w3m-view-next-page)
      ("h"         . utl-w3m-previous-url)
      ("n"         . utl-w3m-next-url)
      ("<backtab>" . w3m-previous-form)
      ("<tab>"     . w3m-next-form)
      ("r"         . w3m-redisplay-this-page)
      ("g"         . w3m-reload-this-page)
      ("j"         . w3m-goto-url)
      ("."         . w3m-previous-anchor)
      ("e"         . w3m-next-anchor)
      ("o"         . w3m-view-parent-page)
      ("O"           (w3m-view-parent-page 0))
      ("U"         . w3m-view-this-url-new-session)
      ("u 0"         (browse-url w3m-current-url))
      ("u u"         (browse-url (w3m-anchor)))
      ("u RET"       (browse-url (w3m-anchor)))
      ("u v"         (browse-url-default-browser
                      (echo-msk-program-video-url (w3m-anchor))))
      ("c 0"       . w3m-print-current-url)
      ("c RET"     . w3m-print-this-url)
      ("s"         . utl-w3m-wget)
      ("w"         . utl-w3m-wget)
      ("C-w w"     . utl-w3m-wget)
      ("C-w m"       (utl-url-wget-mp3 (w3m-anchor)))
      ("C-c C-f"   . w3m-next-buffer)
      ("C-c C-b"   . w3m-previous-buffer))
    "Alist of auxiliary keys for `w3m-mode-map'.")
  (al/bind-keys-from-vars 'w3m-mode-map 'al/w3m-keys)

  (when (require 'utl-w3m nil t)
    (utl-w3m-bind-number-keys 'utl-w3m-switch-to-buffer)
    (utl-w3m-bind-number-keys 'utl-w3m-kill-buffer "k")))

(use-package w3m-form
  :defer t
  :config
  (defconst al/w3m-form-keys
    '(("u" . w3m-form-input-select-set))
    "Alist of auxiliary keys for `w3m-form-input-select-keymap'.")
  (al/bind-keys-from-vars 'w3m-form-input-select-keymap
    '(al/lazy-moving-keys al/w3m-form-keys)))

(use-package utl-w3m
  :defer t
  :config
  (setq
   utl-w3m-search-link-depth 20
   utl-w3m-search-re "[^[:alnum:]]*\\<%s\\>"))

(use-package browse-url
  :defer t
  :config
  (when (require 'utl-browse-url nil t)
    (setq browse-url-browser-function 'utl-choose-browser)
    (advice-add 'browse-url-default-browser
      :override 'utl-browse-url-conkeror)))

(use-package utl-browse-url
  :defer t
  :config
  (setcar (cl-find-if (lambda (spec)
                        (string= "conkeror" (cadr spec)))
                      utl-browser-choices)
          '(?c ?u ?\C-m)))


;;; Mail, news, gnus

(setq
 user-full-name "Alex Kost"
 user-mail-address (concat "alezost" '(?@ ?g) "mail" '(?.) "com"))

(setq
 gnus-home-directory al/gnus-dir
 gnus-directory      al/gnus-news-dir
 message-directory   al/gnus-mail-dir
 ;; gnus-message-archive-group "sent"
 gnus-update-message-archive-method t)

(setq mail-user-agent 'gnus-user-agent)

(use-package gnus
  :defer t
  :init
  (bind-keys*
   :prefix-map al/gnus-map
   :prefix-docstring "Map for Gnus."
   :prefix "M-g"
   ("M-g" . utl-gnus-switch-win-config)
   ("g"   . utl-gnus-switch-to-group-buffer)
   ("b"   . utl-gnus-ido-switch-buffer)
   ("m"   . gnus-msg-mail)
   ("n"   . gnus-msg-mail))

  :config
  (require 'utl-gnus nil t)
  (setq
   gnus-select-method '(nnml "")
   gnus-secondary-select-methods
   '((nnimap "gmail"
             (nnimap-address "imap.gmail.com")
             (nnimap-server-port 993)
             (nnimap-stream ssl))
     (nntp "gmane" (nntp-address "news.gmane.org"))))

  (setq
   gnus-group-mode-line-format "Gnus:"
   gnus-article-mode-line-format "Gnus: %m"
   gnus-summary-mode-line-format "Gnus: %p %Z"
   gnus-summary-line-format "%U%R%z %(%&user-date; %B%-3L %[%f%]%) %s\n"
   gnus-ignored-newsgroups "^to\\.\\|^[0-9. ]+\\( \\|$\\)\\|^[\"]\"[#'()]"
   gnus-visible-headers "^From:\\|^Newsgroups:\\|^Subject:\\|^Date:\\|^Followup-To:\\|^Reply-To:\\|^Organization:\\|^Summary:\\|^Keywords:\\|^To:\\|^[BGF]?Cc:\\|^Posted-To:\\|^Mail-Copies-To:\\|^Mail-Followup-To:\\|^Apparently-To:\\|^Gnus-Warning:\\|^Resent-From:\\|^User-Agent:"
   gnus-user-date-format-alist
   '(((gnus-seconds-today)           . "Today  %H:%M")
     ((+ 86400 (gnus-seconds-today)) . "Yest.  %H:%M")
     ((* 86400 365)                  . "%d %b %H:%M")
     (t                              . "%Y-%m-%d  "))
   gnus-subthread-sort-functions '(gnus-thread-sort-by-number
                                   gnus-thread-sort-by-date))

  (setq
   gnus-activate-level 3
   gnus-activate-foreign-newsgroups gnus-activate-level)

  (setq
   gnus-treat-display-smileys nil
   mm-text-html-renderer 'gnus-w3m
   mm-inline-text-html-with-images t
   gnus-gcc-mark-as-read t)

  ;; Wrap text in gnus-article buffers by words.
  (add-hook 'gnus-article-mode-hook 'visual-line-mode)
  (setq gnus-article-truncate-lines nil)

  (add-hook 'gnus-group-mode-hook 'gnus-topic-mode)
  (al/add-hook-maybe 'dired-mode-hook 'turn-on-gnus-dired-mode))

(use-package gnus-srvr
  :defer t
  :config
  (defconst al/gnus-server-keys
    '(("u"   . gnus-server-read-server)
      ("M-d" . gnus-server-edit-server))
    "Alist of auxiliary keys for `gnus-server-mode-map'.")
  (al/bind-keys-from-vars 'gnus-server-mode-map
    '(al/lazy-moving-keys al/gnus-server-keys)
    t)
  (bind-keys
   :map gnus-browse-mode-map
   ("." . gnus-browse-prev-group)
   ("e" . gnus-browse-next-group)
   ("u" . gnus-browse-select-group)
   ("U" . gnus-browse-unsubscribe-current-group)
   ("^" . gnus-browse-exit)))

;; `gnus-group-mode-map'/`gnus-summary-mode-map'/`gnus-article-mode-map'
;; are defined in "gnus.el" but are filled in
;; "gnus-group.el"/"gnus-sum.el"/"gnus-art.el".

(use-package gnus-group
  :defer t
  :config
  (bind-keys
   :map gnus-group-mode-map
   ("." . gnus-group-prev-group)
   ("e" . gnus-group-next-group)
   (">" . gnus-group-prev-unread-group)
   ("E" . gnus-group-next-unread-group)
   ("u" . gnus-group-read-group)
   ("U" . gnus-group-unsubscribe-current-group)
   ("m" . gnus-group-mark-group)
   ("z" . gnus-group-unmark-group)
   ("Z" . gnus-group-unmark-all-groups)
   ("M-U" . gnus-group-unsubscribe-group)
   ("H i" . gnus-info-find-node)

   ("C-k" . gnus-group-kill-group)
   ("C-t" . gnus-group-kill-region)
   ("H-u" . gnus-undo)
   ("<backtab>" . gnus-topic-unindent)
   ("M-." . gnus-topic-goto-previous-topic)
   ("M-e" . gnus-topic-goto-next-topic))
  (add-hook 'gnus-group-mode-hook 'hl-line-mode))

(use-package gnus-sum
  :defer t
  :config
  (defvar al/ej-url-re "www\\.ej\\.ru.+id=\\([0-9]+\\)"
    "Regexp matching 'ej.ru' arcticles.")

  (setq
   gnus-sum-thread-tree-root            "●─► "
   gnus-sum-thread-tree-false-root      "○─► "
   gnus-sum-thread-tree-vertical        "│"
   gnus-sum-thread-tree-leaf-with-other "├─► "
   gnus-sum-thread-tree-single-leaf     "└─► "
   gnus-sum-thread-tree-indent          " "
   gnus-sum-thread-tree-single-indent   "■ "
   gnus-summary-newsgroup-prefix        "⇒ "
   gnus-summary-to-prefix               "→ ")

  (setq
   gnus-score-over-mark ?↑
   gnus-score-below-mark ?↓
   gnus-unseen-mark ?n
   gnus-read-mark ?✓
   gnus-killed-mark ?✗)

  (defconst al/gnus-summary-keys
    '(("."     . gnus-summary-prev-article)
      ("e"     . gnus-summary-next-article)
      (">"     . gnus-summary-prev-unread-article)
      ("E"     . gnus-summary-next-unread-article)
      ("n"     . gnus-summary-reply)
      ("r"     . gnus-summary-mark-as-read-forward)
      ("z"     . gnus-summary-clear-mark-forward)
      ("u"     . gnus-summary-scroll-up)
      ("C-t"   . gnus-summary-mark-region-as-read)
      ("b"     . gnus-summary-display-buttonized)
      ("v"     . gnus-article-view-part)
      ("s"     . gnus-article-save-part)
      ("i"     . gnus-article-show-images)
      ("U"     . utl-gnus-summary-browse-link-url)
      ("a"     . utl-gnus-summary-emms-add-url)
      ("p"     . utl-gnus-summary-emms-play-url)
      ("C-ь a" . utl-gnus-summary-emms-add-url)
      ("C-ь p" . utl-gnus-summary-emms-play-url)
      ("w"       (wget (utl-gnus-summary-find-mm-url)))
      ("`"       (web-search-ej (utl-gnus-summary-find-url-by-re
                                 al/ej-url-re 1))))
    "Alist of auxiliary keys for `gnus-summary-mode'.")
  (al/bind-keys-from-vars 'gnus-summary-mode-map 'al/gnus-summary-keys)

  (al/add-hook-maybe 'gnus-summary-mode-hook
    '(hl-line-mode al/hbar-cursor-type)))

(use-package gnus-draft
  :defer t
  :config
  (bind-key "M-d" 'gnus-draft-edit-message gnus-draft-mode-map))

(use-package gnus-art
  :defer t
  :config
  (setq
   gnus-unbuttonized-mime-types '("text/plain")
   gnus-prompt-before-saving t
   gnus-default-article-saver 'gnus-summary-save-in-mail
   ;; `gnus-article-save-directory' is placed in "gnus.el" actually, but
   ;; I don't care.
   gnus-article-save-directory al/gnus-saved-dir)

  (defconst al/gnus-article-keys
    '("C-d")
    "Alist of auxiliary keys for `gnus-article-mode-map'.")
  (defconst al/gnus-url-button-keys
    '(("c" . gnus-article-copy-string))
    "Alist of auxiliary keys for `gnus-url-button-map'.")
  (defconst al/gnus-mime-button-keys
    '(("u" . gnus-mime-action-on-part)
      ("s" . gnus-mime-save-part)
      ("v" . gnus-mime-view-part-internally)
      ("V" . gnus-mime-view-part))
    "Alist of auxiliary keys for `gnus-mime-button-map'.")
  (al/bind-keys-from-vars 'gnus-article-mode-map
    '(al/widget-button-keys al/gnus-article-keys))
  (al/bind-keys-from-vars 'gnus-url-button-map
    '(al/widget-button-keys al/gnus-url-button-keys))
  (al/bind-keys-from-vars 'gnus-mime-button-map
    '(al/widget-button-keys al/gnus-mime-button-keys))

  (add-hook 'gnus-article-mode-hook
            (lambda () (setq-local widget-button-face nil))))

(use-package gnus-topic
  :defer t
  :diminish " T"
  :config
  (setq
   gnus-topic-display-empty-topics nil
   gnus-topic-line-format "%i%(%{%n%}%) – %A %v\n"))

(use-package gnus-dired
  :defer t
  :diminish " 𝗚"
  :config
  (bind-keys
   :map gnus-dired-mode-map
   ("C-c a" . gnus-dired-attach)))

(use-package message
  :defer t
  :config
  (setq
   message-signature "Alex"
   message-send-mail-function 'smtpmail-send-it
   message-citation-line-function 'message-insert-formatted-citation-line
   message-citation-line-format "%N (%Y-%m-%d %H:%M %z) wrote:\n"))

(use-package mml
  :defer t
  :config
  (defconst al/mml-keys
    '(("C-c a" . mml-attach-file)
      ("C-c f" . mml-attach-file)
      ("C-c b" . mml-attach-buffer)
      ("C-c P" . mml-preview))
    "Alist of auxiliary keys for `mml-mode-map'.")
  (al/bind-keys-from-vars 'mml-mode-map 'al/mml-keys))

(use-package smtpmail
  :defer t
  :config
  (setq
   smtpmail-smtp-server "smtp.gmail.com"
   smtpmail-smtp-service 587))

(use-package shr
  :defer t
  :config
  (bind-keys
   :map shr-map
   ("u" . shr-browse-url)
   ("c" . shr-copy-url)))

(use-package utl-gnus
  :defer t
  :config
  (setq utl-atom2rss-file (al/emacs-data-dir-file "atom2rss.xsl"))
  (advice-add 'mm-url-insert
    :after #'utl-convert-atom-to-rss)
  (advice-add 'gnus-agent-make-mode-line-string
    :around #'utl-gnus-agent-mode-line-string))


;;; ERC

(use-package erc
  :defer t
  :init
  (setq erc-modules
        '(truncate keep-place log pcomplete netsplit button match
          notifications track completion readonly networks ring autojoin
          noncommands irccontrols move-to-prompt stamp menu list))
  (setq erc-log-channels-directory (al/emacs-data-dir-file "erc-log"))

  (bind-keys*
   :prefix-map al/erc-map
   :prefix-docstring "Map for ERC."
   :prefix "M-c"
   ("M-c" . utl-erc-track-switch-buffer)
   ("M-n" . utl-erc-cycle)
   ("b"   . utl-erc-switch-buffer)
   ("M-s" . utl-erc-switch-to-server-buffer)
   ;; Interactive erc - compute everything without prompting:
   ("c"   . (lambda () (interactive) (erc)))
   ("R"   . utl-erc-server-buffer-rename)
   ("d"   . utl-erc-quit-server)
   ("j"   . utl-erc-join-channel)
   ("a"   . utl-erc-away)
   ("m"   . erc-track-mode)
   ("n"   . erc-notifications-mode)
   ("p"   . (lambda () (interactive) (erc-part-from-channel "")))
   ("e"   . (lambda () (interactive) (switch-to-buffer "#emacs")))
   ("x"   . (lambda () (interactive) (switch-to-buffer "#guix")))
   ("s"   . (lambda () (interactive) (switch-to-buffer "#stumpwm")))
   ("M-z" . (lambda () (interactive) (switch-to-buffer "*status"))))

  :config
  (setq
   erc-server "chat.freenode.net"
   erc-port 7000
   erc-nick "alezost"
   erc-user-full-name user-full-name
   erc-server-reconnect-timeout 60
   erc-server-connect-function 'erc-open-tls-stream
   ;; erc-join-buffer 'bury
   erc-track-showcount t
   erc-prompt-for-password nil
   erc-hide-list '("JOIN" "QUIT")
   erc-track-exclude-types
   '("JOIN" "NICK" "PART" "QUIT" "MODE"
     "305" "306"                        ; away messages
     "324"                              ; channel modes
     "328"
     "329"                              ; channel was created on
     "332"                              ; welcome/topic messages
     "333"                              ; set topic
     "353" "477")
   erc-mode-line-format "%t"
   erc-mode-line-away-status-format " (AWAY %a %H:%M)"
   erc-header-line-format "%n%a on %S [%m,%l] %o"
   erc-timestamp-format-left "\n[%d %B %Y, %A]\n"
   erc-timestamp-intangible nil
   erc-keywords '("theme" "color" "dvorak" "sql" "guix" "game")
   erc-log-file-coding-system 'utf-8
   erc-paranoid t
   erc-autojoin-channels-alist
   '(("freenode.net" "#emacs" "#erc" "#gnus" "#scheme" "#guile" "#guix"
      "#geiser" "#conkeror" "#stumpwm" "#org-mode")))

  (defun al/erc-quit-part-reason (&rest _)
    "I use GNU Guix <http://www.gnu.org/software/guix/>")
  (setq
   erc-quit-reason 'al/erc-quit-part-reason
   erc-part-reason 'al/erc-quit-part-reason)

  (defconst al/erc-keys
    '(("<tab>" . pcomplete)
      ("M-." . erc-previous-command)
      ("M-e" . erc-next-command)
      ("C-a" . erc-bol)
      ("C-l" . utl-erc-view-log-file)
      ("<s-kanji>" . utl-recenter-end-of-buffer-top)
      ("C-H-3" . utl-recenter-end-of-buffer-top))
    "Alist of auxiliary keys for erc mode.")
  (defun al/erc-bind-keys ()
    (al/bind-keys-from-vars 'erc-mode-map 'al/erc-keys))
  (al/add-hook-maybe 'erc-ring-mode-hook 'al/erc-bind-keys)

  (al/add-hook-maybe 'erc-mode-hook
    '(visual-line-mode abbrev-mode))

  ;; Do not consider "'" a part of a symbol, so that `symbol-at-point'
  ;; (used by `elisp-slime-nav' functions) returns a proper symbol.
  (modify-syntax-entry ?' "'   " erc-mode-syntax-table)

  (defun al/erc-channel-config ()
    "Define additional settings depending on a channel."
    (let ((buf (buffer-name (current-buffer))))
      (cond
       ((or (string-match "#scheme" buf)
            (string-match "#guile" buf))
        ;; Some hacks to make it possible to use guile process in erc
        ;; buffer.
        (setq-local geiser-impl--implementation 'guile)
        (setq-local geiser-eval--get-module-function
                    (lambda (module) :f))
        (setq-local geiser-eval--geiser-procedure-function
                    'geiser-guile--geiser-procedure)
        (al/bind-local-keys-from-vars 'al/geiser-keys))
       ((string-match "#lisp" buf)
        (al/bind-local-keys-from-vars 'al/slime-keys))
       ((string-match "#stumpwm" buf)
        (setq-local slime-buffer-package :stumpwm)
        (al/bind-local-keys-from-vars 'al/slime-keys)))))
  (al/add-hook-maybe 'erc-join-hook 'al/erc-channel-config)

  (when (require 'utl-erc nil t)
    (when (utl-znc-running-p)
      (setq erc-server "localhost"
            erc-port 32456))
    (setq-default erc-enable-logging 'utl-erc-log-all-but-some-buffers)
    (setq
     erc-insert-timestamp-function 'utl-erc-insert-timestamp
     erc-view-log-timestamp-position 'left
     erc-generate-log-file-name-function
     'utl-erc-log-file-name-network-channel)
    (setq
     erc-ctcp-query-FINGER-hook  '(utl-erc-ctcp-query-FINGER)
     erc-ctcp-query-ECHO-hook    '(utl-erc-ctcp-query-ECHO)
     erc-ctcp-query-TIME-hook    '(utl-erc-ctcp-query-TIME)
     erc-ctcp-query-VERSION-hook '(utl-erc-ctcp-query-VERSION))
    (al/add-hook-maybe 'erc-after-connect 'utl-erc-ghost-maybe))

  (when (require 'sauron nil t)
    (setq sauron-watch-patterns
          (append sauron-watch-patterns
                  '("theme" "color" "debpaste" "guix\\.el"
                    "game" "ducpel" "sokoban")))
    (add-to-list 'sauron-modules 'sauron-erc))
  ;; ERC is loaded twice somehow (why??); so clear erc assoc of
  ;; `after-load-alist' to prevent the second loading of these settings.
  (setq after-load-alist
        (assq-delete-all 'erc after-load-alist)))

(use-package erc-desktop-notifications
  :defer t
  :diminish (erc-notifications-mode . " 🗩")
  :config
  (setq erc-notifications-icon "erc")
  (defun al/play-erc-sound (&rest _)
    (utl-play-sound (al/sound-dir-file "chimes.wav")))
  (al/with-check
    :fun #'utl-play-sound
    (advice-add 'erc-notifications-notify
      :before #'al/play-erc-sound)))

(use-package erc-button
  :defer t
  :config
  (bind-keys
   :map erc-button-keymap
   ("u" . erc-button-press-button)
   ("e" . utl-next-link)
   ("." . utl-previous-link)
   ("c" . (lambda () (interactive)
            (kill-new (car (get-text-property (point) 'erc-data)))))
   ("w" . (lambda () (interactive)
            (wget (car (get-text-property (point) 'erc-data)))))))

(use-package erc-list
  :defer t
  :config
  (bind-keys
   :map erc-list-menu-mode-map
   ("u"   . erc-list-join)
   ("RET" . erc-list-join))
  (define-key erc-list-menu-sort-button-map
    [header-line mouse-2] 'erc-list-menu-sort-by-column))

(use-package utl-erc
  :defer t
  :config
  (setq
   utl-erc-log-excluded-regexps
   '("\\`#archlinux\\'" "\\`#emacs\\'" "\\`#freenode\\'" "\\`#znc\\'")
   utl-erc-away-msg-list
   '("just away" "watching athletics" "watching darts"
     "eating" "i'm not ready to chat" "time to sleep")
   utl-erc-channel-list
   '("#emacs" "#archlinux" "#archlinux-classroom" "#trivialand" "##latin"
     "#lisp" "#lispgames" "#git" "#github" "#netfilter" "#wesnoth"
     "#themanaworld" "##french" "##english" "##programming")))

(use-package erc-view-log
  :defer t
  :commands erc-view-log-mode
  :init
  (al/with-check
    :var 'erc-log-channels-directory
    (push (cons (concat "^" (regexp-quote (expand-file-name
                                           erc-log-channels-directory)))
                'erc-view-log-mode)
          auto-mode-alist)))


;;; Misc settings and packages

(use-package url
  :defer t
  :config
  (setq url-configuration-directory (al/emacs-data-dir-file "url")))

(use-package wget
  :defer t
  :config
  (setq
   wget-debug-buffer "*wget-log*"
   wget-download-directory-filter 'wget-download-dir-filter-regexp
   wget-download-log-file (al/emacs-data-dir-file "emacs-wget.log")
   wget-download-directory
   `(("onlinetv" . ,(al/download-dir-file "onlinetv"))
     ("beatles" . ,(al/echo-download-dir-file "beatles"))
     ("classicrock" . ,(al/echo-download-dir-file "classicrock"))
     (,(regexp-quote "echo.msk.ru") . ,al/echo-download-dir)
     ("." . ,al/download-dir))))

(use-package mentor
  :defer t
  :config
  (setq mentor-rtorrent-url "scgi://127.0.0.1:5000"))

(use-package net-utils
  :defer t
  :config
  (setq ping-program-options '("-c" "3")))

(use-package utl-net
  :defer t
  :config
  (setq
   utl-net-hosts '("zeus" "hyperion" "192.168.1.1" "10.11.149.1"
                   "10.10.0.1" "google.com" "ya.ru")
   utl-router-log-path "~/docs/net/RT_G32.log/"))

(use-package debpaste
  :defer t
  :init
  (al/add-my-package-to-load-path-maybe "debpaste")
  (bind-keys
   :prefix-map al/debpaste-map
   :prefix-docstring "Map for debpaste."
   :prefix "C-H-p"
   ("s" . debpaste-paste-region)
   ("r" . debpaste-display-paste)
   ("S" . debpaste-display-posted-info-in-buffer)
   ("R" . debpaste-display-received-info-in-buffer)
   ("q" . debpaste-quit-buffers)
   ("K" . debpaste-kill-all-buffers))

  :config
  (setq
   debpaste-user-name "alezost"
   debpaste-expire-time (* 3 24 60 60))
  (add-to-list 'debpaste-domains "debpaste" t))

(use-package web-search
  :defer t
  :commands
  (web-search-yandex
   web-search-ipduh
   web-search-ip-address
   web-search-wikipedia-ru
   web-search-arch-package
   web-search-ej)
  :init (al/add-my-package-to-load-path-maybe "web-search")
  :config
  (web-search-add-engine
   'ipduh "IPduh"
   "http://ipduh.com/apropos/?%s"
   'web-search-clean-ip)
  (web-search-add-engine
   'ip-address "IP address"
   "http://www.ip-address.org/lookup/ip-locator.php?track=%s"
   'web-search-clean-ip)
  (web-search-add-engine
   'yandex "Yandex"
   "http://yandex.ru/yandsearch?text=%s")
  (web-search-add-engine
   'wikipedia-en "Wikipedia (english)"
   "http://en.wikipedia.org/w/index.php?search=%s")
  (web-search-add-engine
   'wikipedia-ru "Wikipedia (russian)"
   "http://ru.wikipedia.org/w/index.php?search=%s")
  (web-search-add-engine
   'arch-package "Arch Packages"
   "https://www.archlinux.org/packages/?sort=&q=%s&maintainer=&flagged=")
  (web-search-add-engine
   'multitran "Multitran"
   "http://www.multitran.ru/c/M.exe?CL=1&s=%s")
  (web-search-add-engine
   'ej "ej.ru"
   "http://mvvc44tv.cmle.ru/?a=note&id=%s"))

(use-package echo-msk
  :defer t
  :init
  (al/add-my-package-to-load-path-maybe "echo-msk")
  (bind-keys
   :prefix-map al/echo-msk-map
   :prefix-docstring "Map for echo-msk."
   :prefix "C-M-s-e"
   ("p" . echo-msk-program-task)
   ("s" . echo-msk-browse-schedule)
   ("a" . echo-msk-emms-play-online-audio)
   ("A" . echo-msk-browse-online-audio)
   ("v" . echo-msk-browse-online-video))
  :config
  (when (require 'dvorak-russian-computer nil t)
    (setq echo-msk-input-method "dvorak-russian-computer")))

;;; net.el ends here
