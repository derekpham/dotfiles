(require 'package)
(add-to-list 'package-archives
             '("melpa" . "http://melpa.org/packages/"))
(add-to-list 'package-archives
             '("org" . "http://orgmode.org/elpa/"))

;; remove crap
(menu-bar-mode -1)
(when (fboundp 'tool-bar-mode)
  (tool-bar-mode -1))
(when (fboundp 'scroll-bar-mode)
  (scroll-bar-mode -1))
(when (fboundp 'horizontal-scroll-bar-mode)
  (horizontal-scroll-bar-mode -1))

;; The uniquify library makes it so that when you visit two files with
;; the same name in different directories, the buffer names have
;; the directory name appended to them instead of the silly hello<2> names you get by default.
(require 'uniquify)

(setq line-number-mode t
      column-number-mode t
      apropos-sort-by-scores t
      ido-enable-flex-matching t
      ido-everywhere t
      uniquify-buffer-name-style 'forward
      require-final-newline t
      load-prefer-newer t
      visible-bell t
      ediff-window-setup-function 'ediff-setup-windows-plain

      ;; move backup files to a dedicated directory
      backup-directory-alist `(("." . "~/etc/emacs-backup-files"))
      backup-by-copying t
      default-directory "~/"
      command-line-default-directory "~/")

(show-paren-mode 1)
(ido-mode 1)

(setq-default indent-tabs-mode nil)

;; when open file, return to last pointer
(save-place-mode 1)

(global-set-key (kbd "M-o") 'other-window)
(windmove-default-keybindings)
;; (global-set-key (kbd "M-/") 'hippie-expand) not sure what this does yet
(global-set-key (kbd "C-x C-b") 'ibuffer)
(global-set-key (kbd "M-z") 'zap-up-to-char)

(add-to-list 'default-frame-alist '(fullscreen . maximized))
(add-to-list 'write-file-functions 'delete-trailing-whitespace)

(global-company-mode 1)
(add-to-list 'company-backends '(company-capf :with company-dabbrev))

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-enabled-themes '(solarized-dark))
 '(custom-safe-themes
   '("0598c6a29e13e7112cfbc2f523e31927ab7dce56ebb2016b567e1eff6dc1fd4f" "a8245b7cc985a0610d71f9852e9f2767ad1b852c2bdea6f4aadc12cce9c4d6d0" "d677ef584c6dfc0697901a44b885cc18e206f05114c8a3b7fde674fce6180879" "8aebf25556399b58091e533e455dd50a6a9cba958cc4ebb0aab175863c25b9a4" "bfdcbf0d33f3376a956707e746d10f3ef2d8d9caa1c214361c9c08f00a1c8409" default))
 '(inhibit-startup-screen t)
 '(package-selected-packages
   '(company ## rust-mode go-mode haskell-mode solarized-theme uniquify-files)))
(package-initialize)

(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
