;;; init.el stuff

;;; Code:
(setq
 conf-enabled (concat user-emacs-directory "conf.d")
 custom-file (concat conf-enabled "/99custom.el"))

(eval-and-compile
  (add-to-list 'load-path (expand-file-name "lib" user-emacs-directory)))

(add-to-list 'exec-path "~/bin/")

(setq url-request-method "GET")
(setq package-archives '(("gnu" . "https://elpa.gnu.org/packages/")
                         ("melpa" . "https://melpa.org/packages/")
;;                         ("marmalade" . "https://marmalade-repo.org/packages/")
                         ("org" . "http://orgmode.org/elpa/")
                         ("sunrise" . "http://joseito.republika.pl/sunrise-commander/")))

;;(load-file internal-config) ;; init?
;;(load-file interface-config) ;;colors

(load-file (concat conf-enabled "/00init.el"))

(require 'package)
(package-initialize)

(defun package-install-if-not (package)
  "Install PACKAGE if it's not installed yet."
  (unless (package-installed-p package)
    (package-refresh-contents)
    (package-install package)))

(package-install-if-not 'use-package)

(setq package-enable-at-startup nil)

(require 'use-package)
(put 'use-package 'lisp-indent-function 1)
(setq use-package-always-ensure t)

(require 'root-edit)

(use-package smex
  :config
  (setq smex-save-file "~/.cache/emacs/smex-items")
  (smex-initialize))

(use-package ivy
  :config
;;  (setq ivy-re-builders-alist '((t . ivy--regex-fuzzy)))
  (ivy-mode t)
  (setq ivy-count-format "%d/%d ")
  :bind
  (("C-c C-r" . ivy-resume)))

(use-package counsel
  :config
  :bind
  (("M-x" . counsel-M-x)))

(use-package swiper
  :config
  (defun counsel-grep-or-isearch-or-swiper ()
    "Call `swiper' for small buffers and `counsel-grep'/`isearch-forward' for large ones."
    (interactive)
    (let ((big (> (buffer-size)
                  (if (eq major-mode 'org-mode)
                      (/ counsel-grep-swiper-limit 4)
                    counsel-grep-swiper-limit)))
          (local (and (buffer-file-name)
                      (not (buffer-narrowed-p))
                      (not (ignore-errors
                             (file-remote-p (buffer-file-name))))
                      (not (string-match
                            counsel-compressed-file-regex
                            (buffer-file-name))))))
      (if big
          (if local
              (progn
                (save-buffer)
                (counsel-grep))
            (call-interactively #'isearch-forward))
        (swiper--ivy (swiper--candidates)))))
  :bind
  (("C-s" . counsel-grep-or-isearch-or-swiper)))

(use-package ivy-rich
  :config
  (setq ivy-rich-abbreviate-paths t)
  (setq ivy-rich-switch-buffer-name-max-length 45)
  (ivy-set-display-transformer 'ivy-switch-buffer 'ivy-rich-switch-buffer-transformer))

(use-package jabber
  :init
  (setq dired-bind-jump nil)
  :config
  (setq jabber-history-enabled t
        jabber-use-global-history nil
        fsm-debug nil)
    ;; load jabber-account-list from encrypted file
  (defgroup jabber-local nil
    "Local settings"
    :group 'jabber)

  (defcustom jabber-secrets-file "~/.secrets.el.gpg"
    "Jabber secrets file, sets jabber-account-list variable)"
    :group 'jabber-local)

  (defadvice jabber-connect-all (before load-jabber-secrets (&optional arg))
    "Try to load account list from secrets file"
    (unless jabber-account-list
      (when (file-readable-p jabber-secrets-file)
        (load-file jabber-secrets-file))))

  (ad-activate 'jabber-connect-all)

  ;; customized
  (custom-set-variables
   '(jabber-auto-reconnect t)
   '(jabber-avatar-set t)
   '(jabber-chat-buffer-format "*-jc-%n-*")
   '(jabber-default-status "")
   '(jabber-groupchat-buffer-format "*-jg-%n-*")
   '(jabber-chat-foreign-prompt-format "▼ [%t] %n> ")
   '(jabber-chat-local-prompt-format "▲ [%t] %n> ")
   '(jabber-muc-colorize-foreign t)
   '(jabber-muc-private-buffer-format "*-jmuc-priv-%g-%n-*")
   '(jabber-rare-time-format "%e %b %Y %H:00")
   '(jabber-resource-line-format "   %r - %s [%p]")
   '(jabber-roster-buffer "*-jroster-*")
   '(jabber-roster-line-format "%c %-17n")
   '(jabber-roster-show-bindings nil)
   '(jabber-roster-show-title nil)
   '(jabber-roster-sort-functions (quote (jabber-roster-sort-by-status jabber-roster-sort-by-displayname jabber-roster-sort-by-group)))
   '(jabber-show-offline-contacts nil)
   '(jabber-show-resources nil))

  (custom-set-faces
   '(jabber-chat-prompt-foreign ((t (:foreground "#8ac6f2" :weight bold))))
   '(jabber-chat-prompt-local ((t (:foreground "#95e454" :weight bold))))
   '(jabber-chat-prompt-system ((t (:foreground "darkgreen" :weight bold))))
   '(jabber-rare-time-face ((t (:inherit erc-timestamp-face))))
   '(jabber-roster-user-away ((t (:foreground "LightSteelBlue3" :slant italic :weight normal))))
   '(jabber-roster-user-error ((t (:foreground "firebrick3" :slant italic :weight light))))
   '(jabber-roster-user-online ((t (:foreground "gray  78" :slant normal :weight bold))))
   '(jabber-roster-user-xa ((((background dark)) (:foreground "DodgerBlue3" :slant italic :weight normal))))
   '(jabber-title-large ((t (:inherit variable-pitch :weight bold :height 2.0 :width ultra-expanded))))
   '(jabber-title-medium ((t (:inherit variable-pitch :foreground "#E8E8E8" :weight bold :height 1.2 :width expanded))))
   '(jabber-title-small ((t (:inherit variable-pitch :foreground "#adc4e3" :weight bold :height 0.7 :width semi-expanded))))))

(use-package jabber-otr)

(use-package w3m
  :config
  (add-hook 'w3m-mode-hook 'w3m-lnum-mode)
  (setq w3m-use-tab nil)
  (setq w3m-use-title-buffer-name t)
  (setq w3m-use-filter t)
  (setq w3m-enable-google-feeling-lucky t)
  (setq w3m-use-header-line-title t)
  (defun set-external-browser (orig-fun &rest args)
    (let ((browse-url-browser-function
           (if (eq browse-url-browser-function 'w3m-browse-url)
               'browse-url-generic
             browse-url-browser-function)))
      (apply orig-fun args)))
  (advice-add 'w3m-view-url-with-browse-url :around #'set-external-browser))

(use-package keyfreq
  :config
  (keyfreq-mode 1)
  (keyfreq-autosave-mode 1))

;; avy-based stuff
(use-package avy
  :config
  (avy-setup-default)
  :bind
  (("C-:" . avy-goto-char)
   ;; ("C-'" . avy-goto-char-2)
   ("M-g M-g" . avy-goto-line)
   ("M-g w" . avy-goto-word-1)))

(use-package ace-jump-buffer
  :bind
  (("M-g b" . ace-jump-buffer)))


(use-package ace-window
  :config
  (setq aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l))
  :bind
  (("M-o" . ace-window)))

(use-package ace-link
  :config
  (ace-link-setup-default))

(use-package link-hint
  :ensure t
  :bind
  (("C-c l o" . link-hint-open-link)
   ("C-c l c" . link-hint-copy-link)))

(use-package quelpa)
(use-package quelpa-use-package)

(use-package projectile)
(use-package yasnippet
  :config
  (yas-reload-all)
  (setq yas-prompt-functions '(yas-completing-prompt yas-ido-prompt))
  (add-hook 'prog-mode-hook #'yas-minor-mode))

(use-package flycheck
  :config
  (add-hook 'prog-mode-hook #'flycheck-mode))

(use-package avy-flycheck
  :config
  (avy-flycheck-setup))

(use-package nameless
  :config
  (add-hook 'emacs-lisp-mode-hook #'nameless-mode)
  (setq nameless-private-prefix t))

;; scheme
(use-package geiser)
;; clojure
(use-package clojure-mode)
(use-package clojure-snippets)
(use-package cider)

;; scala
(use-package ensime
  :bind (:map ensime-mode-map
              ("C-x C-e" . ensime-inf-eval-region)))

;; company-based plugins
(use-package company
  :config
  (add-hook 'after-init-hook 'global-company-mode))

(use-package company-shell
  :config
  (add-to-list 'company-backends 'company-shell))

(use-package company-emoji
  :config
  (add-to-list 'company-backends 'company-emoji)
  (set-fontset-font t 'symbol
                    (font-spec :family
                               (if (eq system-type 'darwin)
                                   "Apple Color Emoji"
                                 "Symbola"))
                               nil 'prepend))

(use-package ibuffer-vc
  :config
  (add-hook 'ibuffer-hook
            (lambda ()
              (ibuffer-vc-set-filter-groups-by-vc-root)
              (unless (eq ibuffer-sorting-mode 'alphabetic)
                (ibuffer-do-sort-by-alphabetic)))))

(use-package magit)

(use-package diff-hl
  :config
  (add-hook 'magit-post-refresh-hook 'diff-hl-magit-post-refresh)
  (add-hook 'prog-mode-hook #'diff-hl-mode)
  (add-hook 'dired-mode-hook #'diff-hl-dired-mode))

(use-package edit-indirect)

;; interface

(use-package rainbow-delimiters
  :config
  (add-hook 'prog-mode-hook #'rainbow-delimiters-mode))

(use-package rainbow-identifiers
  :config
  (add-hook 'prog-mode-hook #'rainbow-identifiers-mode))

(use-package rainbow-mode
  :config
  (add-hook 'prog-mode-hook #'rainbow-mode))

(use-package spaceline
  :config
  (require 'spaceline-config)
  (spaceline-emacs-theme))

(use-package point-im
  :ensure nil
  :quelpa
  (point-im :repo "a13/point-im.el" :fetcher github :version original)
  :config
  (setq point-im-reply-id-add-plus nil)
  (add-hook 'jabber-chat-mode-hook #'point-im-mode))

(use-package eshell-toggle
  :ensure nil
  :quelpa
  (eshell-toggle :repo "4DA/eshell-toggle" :fetcher github :version original)
  :bind
  (("M-`" . eshell-toggle)))


(use-package reverse-im
  :config
  (add-to-list 'load-path "~/.xkb/contrib")
  (reverse-im-activate
   (if (require 'unipunct nil t)
       "russian-unipunct"
     "russian-computer")))


(load-file custom-file)

(provide 'init)

;;; init.el ends here
