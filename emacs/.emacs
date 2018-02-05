(require 'package)
;;(add-to-list 'load-path "~/.emacs.d/")

(setq c-default-style "linux")
(setq line-number-mode t)
(setq column-number-mode t)
(add-to-list 'default-frame-alist '(fullscreen . maximized))
(add-to-list 'write-file-functions 'delete-trailing-whitespace)
(defun load-food-file (a)
  "load the list of food that should be there every day"
  (interactive "p")
  (find-file "/home/derek/Desktop/Northeastern/Things"))
(defun open-msdata (a)
  "load the data of minesweeper"
  (interactive "p")
  (find-file "~/.local/share/gnome-mines/history"))
(defun resume (a)
  "load the resume.tex and open the terminal in the other window"
  (interactive "p")
  (split-window-right)
  (find-file "~/Desktop/Northeastern/resume/resume.tex")
  (other-window 1)
  (term "/bin/bash")
  (insert "cd ~/Desktop/Northeastern\n"))
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(inhibit-startup-screen t)
 '(package-archives
   (quote
    (("gnu" . "http://elpa.gnu.org/packages/")
     ("melpa-stable" . "http://stable.melpa.org/packages/")))))
(package-initialize)

(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
(require 'package)
(add-to-list 'package-archives
             '("melpa-stable" . "http://stable.melpa.org/packages/") t)

(defun c-lineup-arglist-tabs-only (ignored)
  "Line up argument lists by tabs, not spaces"
  (let* ((anchor (c-langelem-pos c-syntactic-element))
         (column (c-langelem-2nd-pos c-syntactic-element))
         (offset (- (1+ column) anchor))
         (steps (floor offset c-basic-offset)))
    (* (max steps 1)
       c-basic-offset)))

(add-hook 'c-mode-common-hook
          (lambda ()
            ;; Add kernel style
            (c-add-style
             "linux-tabs-only"
             '("linux" (c-offsets-alist
                        (arglist-cont-nonempty
                         c-lineup-gcc-asm-reg
                         c-lineup-arglist-tabs-only))))))

(add-hook 'c-mode-hook
          (lambda ()
            (let ((filename (buffer-file-name)))
              ;; Enable kernel mode for the appropriate files
              (when (and filename
                         (string-match (expand-file-name "~/src/linux-trees")
                                       filename))
                (setq indent-tabs-mode t)
                (setq show-trailing-whitespace t)
                (c-set-style "linux-tabs-only")))))
