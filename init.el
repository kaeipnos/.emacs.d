
;; init downloaded packages
(package-initialize)

(require 'package)
(add-to-list 'package-archives '("melpa" . "http://melpa.org/packages/"))

(require 'use-package)

;; ido
(use-package ido :ensure t :defer t
  :init
  (ido-mode t)
  (setq ido-enable-flex-matching t
        ido-use-virtual-buffers t))

;; markdown
(use-package markdown-mode :ensure t :defer t
  :init
  (add-to-list 'auto-mode-alist '("\\.md$" . markdown-mode))
  (add-to-list 'auto-mode-alist '("\\.mdown$" . markdown-mode))
  (add-hook 'markdown-mode-hook
            (lambda ()
              (visual-line-mode t)
              (writegood-mode t)
              (flyspell-mode t)))
  :config
  (use-package writegood-mode :ensure t :defer t)
  )

;; close (), [], {}
(use-package autopair :ensure t :defer t
  :init (autopair-global-mode t))

(use-package irony
  :ensure t
  :defer t
  :init
  (add-hook 'c++-mode-hook 'irony-mode)
  (add-hook 'c-mode-hook 'irony-mode)
  (add-hook 'objc-mode-hook 'irony-mode)
  :config
  (use-package company-irony :ensure t :defer t)
  (use-package company-irony-c-headers :ensure t :defer t)
  (defun my-irony-mode-hook ()
    (define-key irony-mode-map [remap completion-at-point]
      'irony-completion-at-point-async)
    (define-key irony-mode-map [remap complete-symbol]
      'irony-completion-at-point-async)
    (require 'company-irony-c-headers)
    (eval-after-load 'company
      '(add-to-list 'company-backends '(company-irony-c-headers company-irony))))
  (add-hook 'irony-mode-hook 'my-irony-mode-hook)
  (add-hook 'irony-mode-hook 'irony-cdb-autosetup-compile-options))

(defun irony-semantic-config ()
  (semantic-mode)
  ;; Use info extracted from Irony to help Semantic:
  ;; https://github.com/AndreaOrru/emacs.d/blob/master/lisp/init-semantic.el
  (require 'irony)
  (defadvice irony-cdb--update-compile-options (after my/irony-cdb--update-compile-options activate)
    "Pass the include paths detected by Irony to Semantic."
    (interactive)
    ;; include dirs
    (dolist (dir (irony--extract-user-search-paths
                  irony--compile-options
                  irony--working-directory))
      (semantic-add-system-include dir))
    ;; preprocessor defines
    ;; http://stackoverflow.com/questions/7300266/c-preprocessor-defines-not-taken-into-account-by-cedet-semantic
    (dolist (str irony--compile-options)
      (if (string-prefix-p "-D" str)
	  ;;(add-to-list 'semantic-lex-c-preprocessor-symbol-map (cons (string-remove-prefix "-D" str) "TRUE"))
	  (semantic-c-add-preprocessor-symbol (string-remove-prefix "-D" str) ""))
	)
    )

  ;; Force reloading all the includes after Irony update:
  (add-to-list 'semantic-init-db-hook
               (lambda () (semanticdb-find-translate-path nil nil)))

  (defun semantic-parse-dir (root)
    "Make Semantic parse all source files in directory ROOT, recursively."
    (interactive (list (read-directory-name "Root directory; "
                                            irony--working-directory)))
    (dolist (file (directory-files-recursively
                   root
                   ".*\\.\\(c\\|cpp\\|cxx\\|h\\|hpp\\|hxx\\)"))
      (semanticdb-file-table-object file)))
  )
(add-hook 'c-mode-common-hook 'irony-semantic-config)


(use-package yasnippet
  :ensure t
  :defer t
  :init
  (yas-global-mode t)
  ;; KILL yas keybind to tab, those three lines are needed.
  (define-key yas-minor-mode-map [(tab)]        nil)
  (define-key yas-minor-mode-map (kbd "TAB")    nil)
  (define-key yas-minor-mode-map (kbd "<tab>")  nil)
  :config
  :bind)

(use-package auto-yasnippet :ensure t :defer t)

(use-package company
  :ensure t
  :defer t
  :init (add-hook 'after-init-hook 'global-company-mode)
  :config
  (setq company-idle-delay              0.1
        company-minimum-prefix-length   1
        company-show-numbers            t
        company-tooltip-limit           20
        company-dabbrev-downcase        0
        company-auto-complete           nil
        company-selection-wrap-around   t
        )
  ;; no company for vhdl
  (setq company-global-modes '(not vhdl-mode))

  ;; company and yasnippet for c/c++
  (defun check-expansion ()
    (save-excursion
      (if (looking-at "\\_>") t
        (backward-char 1)
        (if (looking-at "\\.") t
          (backward-char 1)
          (if (looking-at "->") t nil)))))

  (defun do-yas-expand ()
    (let ((yas/fallback-behavior 'return-nil))
      (yas/expand)))

  (defun tab-indent-or-complete ()
    (interactive)
    (if (minibufferp)
        (minibuffer-complete)
      (if (or (not yas/minor-mode)
              (null (do-yas-expand)))
          (if (check-expansion)
              (company-complete-common-or-cycle)
            (indent-for-tab-command)))))

  (defun company-yas-completion-setup ()
    (local-set-key [tab] 'tab-indent-or-complete)
    (define-key company-active-map [tab] 'company-complete-common-or-cycle)
    )

  (add-hook 'python-mode-hook 'company-yas-completion-setup)
  (add-hook 'c++-mode-hook 'company-yas-completion-setup)
  (add-hook 'c-mode-hook 'company-yas-completion-setup)
  :bind)


(use-package flycheck
  :ensure t
  :defer t
  :init
  (add-hook 'c++-mode-hook 'flycheck-mode)
  (add-hook 'c-mode-hook 'flycheck-mode)
  :config
  :bind)


(use-package flycheck-irony
  :ensure t
  :defer t
  :init
  (add-hook 'c++-mode-hook 'flycheck-irony-setup)
  (add-hook 'c-mode-hook 'flycheck-irony-setup)
  :config
  :bind)



(use-package anaconda-mode
  :ensure t
  :defer t
  :init
  (use-package company-anaconda :ensure t :defer t)
  (defun anaconda-python-hook ()
    (eval-after-load "company"
      '(add-to-list 'company-backends 'company-anaconda))
    )
  (add-hook 'python-mode-hook 'anaconda-mode)
  (add-hook 'python-mode-hook 'anaconda-python-hook)
  :config
  )


(use-package powerline
  :ensure t
  :defer t
  :init
  (powerline-default-theme)
  :config)


(use-package iedit
  :ensure t
  :defer t
  :init
  :config
  :bind
  ("C-c i" . iedit-mode))


(use-package swiper
  :ensure t
  :defer t
  :init
  :config
  :bind
  ("C-s" . swiper))



(use-package function-args
  :ensure t
  :defer t
  :init
  :config
  :bind
  ("C-c j" . moo-jump-local)
  ("C-c d" . moo-jump-directory))

(use-package remember
  :ensure t
  :defer t
  :init
  :config
  :bind
  ("C-r" . remember))


(use-package cmake-mode
  :ensure t
  :defer t
  :init
  (defun cmake-setup ()
    (setq cmake-tab-width 4)
    (setq indent-tabs-mode nil))
  (add-hook 'cmake-mode-hook 'cmake-setup)
  :config
  :bind)

;; see through
(defun set-window-opacity (percent)
  (set-frame-parameter (selected-frame) 'alpha (list percent)))
(defvar window-transparent nil)
(defun toggle-window-opacity ()
  (interactive)
  (if window-transparent
      (progn (set-window-opacity 100) (setq window-transparent nil))
    (progn (set-window-opacity 80) (setq window-transparent t))))
(global-set-key (kbd "M-à") 'toggle-window-opacity)

;; ;; atomic move 
;; (global-set-key (kbd "C-i") 'previous-line)
;; (global-set-key (kbd "C-k") 'next-line)
;; (global-set-key (kbd "C-j") 'left-char)
;; (global-set-key (kbd "C-l") 'right-char)
;; (global-set-key (kbd "C-ù") 'recenter-top-bottom)
;; (global-set-key (kbd "C-l") 'recenter-top-bottom)

;; ;; paragraph move
;; (global-set-key (kbd "C-S-i") 'backward-paragraph)
;; (define-key emacs-lisp-mode-map (kbd "C-M-i") nil)
;; (global-set-key (kbd "C-S-k") 'forward-paragraph)

;; == basic complete ==
(global-set-key (kbd "C-,") 'dabbrev-expand)
(global-set-key (kbd "C-;") 'yas-expand)

;; == undo ==
(global-set-key (kbd "C-:") 'undo)

;; == window splitting/navigation ==
(defun me:switch-to-buffer-implicit ()
  (interactive)
  (switch-to-buffer (other-buffer)))
(global-set-key (kbd "C-=") 'me:switch-to-buffer-implicit)
(global-set-key (kbd "C-)") 'other-window)
(global-set-key (kbd "C-à") 'split-window-right)
(global-set-key (kbd "C-ç") 'split-window-below)
(global-set-key (kbd "C-_") 'delete-window)
(defun me:kill-current-buffer ()
  (interactive)
  (kill-buffer (current-buffer)))
(global-set-key (kbd "C-8") 'me:kill-current-buffer)

;; == vhdl ==
;; fix paragraph
(add-hook 'vhdl-mode-hook
          (lambda
            ()
            (setq paragraph-start "\\|[        ]*$"
                  paragraph-separate "[  ]*$"
                  (vhdl-electric-mode 1)
                  (vhdl-stutter-mode 1)
                  (local-set-key (kbd "C-c c") 'vhdl-compile)
                  (local-set-key (kbd "C-c n") 'next-error)
                  (local-set-key (kbd "C-c p") 'previous-error))))


;; compile-mode
(add-hook 'c-mode-common-hook
          (lambda
            ()
            (local-set-key (kbd "C-c c") 'compile)
            (local-set-key (kbd "C-c e f") 'first-error)
            (local-set-key (kbd "C-c e n") 'next-error)
            (local-set-key (kbd "C-c e p") 'previous-error)))

;; semantic
(defun semantic-config ()
  (semantic-mode)
  (global-semantic-decoration-mode t)
  (global-semantic-highlight-func-mode t)
  (global-semantic-highlight-edits-mode t)
  (global-semantic-stickyfunc-mode t))
(add-hook 'c-mode-common-hook 'semantic-config)
(add-hook 'python-mode-hook 'semantic-config)

;; highligh paren
(show-paren-mode t)

;; case insensitive file search
(setq read-file-name-completion-ignore-case t)
(setq read-buffer-completion-ignore-case t)

;; line numbers
(global-linum-mode t)

;; scrolling
(setq mouse-wheel-progressive-speed nil)
(setq mouse-wheel-scroll-amount '(3 ((shift) . 1) ((control) . nil)))

;; comment bindings
(global-set-key (kbd "C-!") 'comment-or-uncomment-region)

;; rectangle mark
(global-set-key (kbd "C-c r") 'rectangle-mark-mode)

;; no default message in *scratch*
(setq initial-scratch-message nil)

;; reload init.el with ease
(defun reload-default ()
  "reload config"
  (interactive)
  (load-file "~/.emacs.d/init.el"))

;; easly fix indentation for a whole buffer
(defun indent-buffer ()
  (interactive)
  (save-excursion
    (delete-trailing-whitespace)
    (indent-region (point-min) (point-max) nil)
    (untabify (point-min) (point-max))))
(global-set-key "\C-x\_" 'indent-buffer)

;; backup
;; http://stackoverflow.com/questions/151945/how-do-i-control-how-emacs-makes-backup-files
;; Default and per-save backups go here:
(setq backup-directory-alist '(("" . "~/.emacs.d/backup/per-save")))

(defun force-backup-of-buffer ()
  ;; Make a special "per session" backup at the first save of each
  ;; emacs session.
  (when (not buffer-backed-up)
    ;; Override the default parameters for per-session backups.
    (let ((backup-directory-alist '(("" . "~/.emacs.d/backup/per-session")))
          (kept-new-versions 3))
      (backup-buffer)))
  ;; Make a "per save" backup on each save.  The first save results in
  ;; both a per-session and a per-save backup, to keep the numbering
  ;; of per-save backups consistent.
  (let ((buffer-backed-up nil))
    (backup-buffer)))
(add-hook 'before-save-hook  'force-backup-of-buffer)

;; doxygen with semantics
;; http://emacs.stackexchange.com/questions/8006/is-there-a-yasnippet-producing-a-prepopulated-doxygen-comment
(defun moo-doxygen-with-semantic ()
  "Generate a doxygen yasnippet and expand it with `aya-expand'.
The point should be on the top-level function name."
  (interactive)
  (move-beginning-of-line nil)
  (let ((tag (semantic-current-tag)))
    (unless (semantic-tag-of-class-p tag 'function)
      (error "Expected function, got %S" tag))
    (let* ((name (semantic-tag-name tag))
           (attrs (semantic-tag-attributes tag))
           (args (plist-get attrs :arguments))
           (ord 1))
      (setq aya-current
            (format
             "/**
* $1
*
%s
* @return $%d
*/
"
             (mapconcat
              (lambda (x)
                (format "* @param %s $%d"
                        (car x) (incf ord)))
              args
              "\n")
             (incf ord)))
      (aya-expand))))

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(autopair-global-mode t)
 '(confirm-kill-emacs nil)
 '(confirm-kill-processes nil)
 '(custom-enabled-themes (quote (deeper-blue)))
 '(inhibit-startup-screen t)
 '(menu-bar-mode nil)
 '(package-selected-packages
   (quote
    (company-quickhelp ensime scala-mode ditz-mode helm-gtags sr-speedbar writegood-mode autopair ido-mode auto-yasnippet cmake-mode function-args iedit powerline company-anaconda anaconda-mode yasnippet yas company-irony-c-headers flycheck-irony flycheck company-irony company irony use-package)))
 '(scroll-bar-mode nil)
 '(semantic-mode t)
 '(tool-bar-mode nil))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

;; write over the marked region
(delete-selection-mode t)

;; no click click
(setq use-dialog-box nil)

;; life is too short to type 'yes'
(defalias 'yes-or-no-p 'y-or-n-p)
;; http://emacs.stackexchange.com/questions/17269/how-configure-the-confirmation-minibuffer-to-use-enter-instead-y
(defun y-or-n-p-with-return (orig-func &rest args)
  (let ((query-replace-map (copy-keymap query-replace-map)))
    (define-key query-replace-map (kbd "RET") 'act)
    (apply orig-func args)))
(advice-add 'y-or-n-p :around #'y-or-n-p-with-return)

;; set font
;; (set-default-font "Monospace-11")
;; (set-default-font "DejaVu Sans Mono")
;; (set-default-font "Ubuntu Mono")
(set-default-font "Liberation Mono")
(set-face-attribute 'default nil :height 100)
