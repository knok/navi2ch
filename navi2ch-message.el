;;; navi2ch-message.el --- write message module for navi2ch

;; Copyright (C) 2000 by 2$B$A$c$s$M$k(B

;; Author: (not 1)
;; Keywords: network, 2ch

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Code:

(require 'navi2ch-article)
(require 'navi2ch-vars)

(defvar navi2ch-message-mode-map nil)
(unless navi2ch-message-mode-map
  (setq navi2ch-message-mode-map (make-sparse-keymap))
  (define-key navi2ch-message-mode-map "\C-c\C-c" 'navi2ch-message-send-message)
  (define-key navi2ch-message-mode-map "\C-c\C-k" 'navi2ch-message-exit)
  (define-key navi2ch-message-mode-map "\C-c\C-y" 'navi2ch-message-cite-original)
  (define-key navi2ch-message-mode-map "\C-cy" 'navi2ch-message-cite-original-from-number)
  (define-key navi2ch-message-mode-map "\C-c\C-i" 'navi2ch-message-insert-backup)
  (define-key navi2ch-message-mode-map "\C-c\C-b" 'navi2ch-base64-insert-file)
  (define-key navi2ch-message-mode-map "\et" 'navi2ch-toggle-offline))

(defvar navi2ch-message-mode-menu-spec
  '("Message"
    ["Toggle offline" navi2ch-toggle-offline]
    ["Send message" navi2ch-message-send-message]
    ["Cancel" navi2ch-message-exit]
    ["Cite message" navi2ch-message-cite-original]))

(defvar navi2ch-message-buffer-name "*navi2ch message*")
(defvar navi2ch-message-backup-buffer-name "*navi2ch message backup*")
(defvar navi2ch-message-current-article-buffer nil)
(defvar navi2ch-message-current-article nil)
(defvar navi2ch-message-current-board nil)
(defvar navi2ch-message-new-message-p nil)
(defvar navi2ch-message-window-configuration nil)

(defun navi2ch-message-write-message (board article &optional new sage)
  (if (and (get-buffer navi2ch-message-buffer-name)
	   (or navi2ch-message-always-pop-message
	       (not (navi2ch-message-kill-message))))
      (navi2ch-message-pop-message-buffer)
    (setq navi2ch-message-window-configuration
	  (current-window-configuration))
    (delete-other-windows)
    (split-window-vertically)
    (other-window 1)
    (setq navi2ch-message-current-article article)
    (setq navi2ch-message-current-board board)
    (setq navi2ch-message-new-message-p new)
    (setq navi2ch-message-current-article-buffer
	  (if new nil (current-buffer)))
    (switch-to-buffer (get-buffer-create navi2ch-message-buffer-name))
    (navi2ch-message-mode)
    (erase-buffer)
    (navi2ch-message-insert-header new sage)
    (navi2ch-set-mode-line-identification)
    (run-hooks 'navi2ch-message-setup-message-hook)
    (when sage
      (run-hooks 'navi2ch-message-setup-sage-message-hook))))

(defun navi2ch-message-pop-message-buffer ()
  (interactive)
  (let ((buf (get-buffer navi2ch-message-buffer-name)))
    (when buf
      (cond ((get-buffer-window buf)
             (select-window (get-buffer-window buf)))
            (buf
             (setq navi2ch-message-window-configuration
                   (current-window-configuration))
             (delete-other-windows)
             (split-window-vertically)
             (other-window 1)
             (switch-to-buffer navi2ch-message-buffer-name))))))

(defun navi2ch-message-insert-backup ()
  (interactive)
  (when (get-buffer navi2ch-message-backup-buffer-name)
    (erase-buffer)
    (insert-buffer navi2ch-message-backup-buffer-name)))

(defun navi2ch-message-insert-header (new sage)
  (and sage (setq sage "sage"))
  (when new
    (insert "Subject: \n"))
  (insert "From: "
	  (or (cdr (assq 'name navi2ch-message-current-article))
	      (cdr (assoc (cdr (assq 'id navi2ch-message-current-board))
			  navi2ch-message-user-name-alist))
	      navi2ch-message-user-name "") "\n"
	      "Mail: "
	      (or sage
	      (cdr (assq 'mail navi2ch-message-current-article))
	      navi2ch-message-mail-address "") "\n"
	      "----------------\n"))

(defun navi2ch-message-send-message ()
  (interactive)
  (when (or (not navi2ch-message-ask-before-send)
            (y-or-n-p "send message?"))
    (run-hooks 'navi2ch-message-before-send-hook)
    (save-excursion
      (let (subject from mail message)
        (goto-char (point-min))
        (when navi2ch-message-new-message-p
	  (re-search-forward "Subject: \\([^\n]*\\)\n" nil t)
          (setq subject (match-string 1)))
        (re-search-forward "From: \\([^\n]*\\)\n")
        (setq from (match-string 1))
        (when navi2ch-message-remember-user-name
          (setq navi2ch-message-user-name from))
        (when (not navi2ch-message-new-message-p)
          (navi2ch-message-set-name from))
        (re-search-forward "Mail: \\([^\n]*\\)\n")
        (setq mail (match-string 1))
	(when (not navi2ch-message-new-message-p)
	  (navi2ch-message-set-mail mail))
        (forward-line 1)
        (setq message (buffer-substring (point) (point-max)))
        (let ((str (buffer-substring-no-properties
                    (point-min) (point-max))))
          (save-excursion
            (set-buffer (get-buffer-create
                         navi2ch-message-backup-buffer-name))
            (erase-buffer)
            (insert str)
            (bury-buffer)))
	(when navi2ch-message-trip
	  (setq from (concat from "#" navi2ch-message-trip)))
        (when (navi2ch-net-send-message
               from mail message subject
               navi2ch-message-current-board
               navi2ch-message-current-article)
          (sleep-for navi2ch-message-wait-time)
          (save-excursion
            (if navi2ch-message-new-message-p
                (progn
		  (set-buffer navi2ch-board-buffer-name)
		  (navi2ch-board-sync))
              (set-buffer (navi2ch-article-current-buffer))
              (navi2ch-article-sync))))))
    (run-hooks 'navi2ch-message-after-send-hook)
    (navi2ch-message-exit 'after-send)))

(defun navi2ch-message-set-name (name)
  (save-excursion
    (set-buffer navi2ch-message-current-article-buffer)
    (setq navi2ch-article-current-article
          (navi2ch-put-alist 'name name
                             navi2ch-article-current-article))))

(defun navi2ch-message-set-mail (mail)
  (let ((case-fold-search t))
    (unless (string-match "sage" mail)
      (save-excursion
	(set-buffer navi2ch-message-current-article-buffer)
	(setq navi2ch-article-current-article
	      (navi2ch-put-alist 'mail mail
				 navi2ch-article-current-article))))))
      

(defun navi2ch-message-cite-original (&optional arg)
  "$B0zMQ$9$k(B"
  (interactive "P")
  (navi2ch-message-cite-original-from-number
   (save-excursion
     (set-buffer (navi2ch-article-current-buffer))
     (navi2ch-article-get-current-number))
   arg))

(defun navi2ch-message-cite-original-from-number (num &optional arg)
  "$BHV9f$rA*$s$G!"0zMQ$9$k!#(B"
  (interactive "ninput number: \nP")
  (let (same msg board article)
    (save-excursion
      (set-buffer (navi2ch-article-current-buffer))
      (setq msg (cdr (assq 'data (navi2ch-article-get-message num))))
      (setq article navi2ch-article-current-article)
      (setq board navi2ch-article-current-board)
      (setq same (and (string-equal (cdr (assq 'id board))
				    (cdr (assq 'id navi2ch-message-current-board)))
		      (string-equal (cdr (assq 'artid article))
				    (cdr (assq 'artid navi2ch-message-current-article))))))
    (if same
	(insert ">>" (number-to-string num) "\n")
      (insert (navi2ch-article-to-url board article num num nil) "\n"))
    (unless arg
      (set-mark (point))
      (let ((point (point)))
	(insert msg "\n")
	(string-rectangle point (point) navi2ch-message-cite-prefix)))))
    
(defun navi2ch-message-exit (&optional after-send)
  (interactive)
  (when (navi2ch-message-kill-message after-send)
    ;; $B$`$%!"(Bset-window-configuration $B$r;H$&$H%+!<%=%k0LCV$,JQ$K$J$k$s$+$$!)(B
    (set-window-configuration navi2ch-message-window-configuration)
    (when (and (not navi2ch-message-new-message-p)
               after-send)
      (set-buffer (navi2ch-article-current-buffer))
      (navi2ch-article-load-number))))

(defun navi2ch-message-kill-message (&optional no-ask)
  (when (or no-ask
	    (not navi2ch-message-ask-before-kill)
	    (y-or-n-p "kill current message?"))
    (kill-buffer navi2ch-message-buffer-name)
    t))

(defun navi2ch-message-setup-menu ()
  (easy-menu-define navi2ch-message-mode-menu
		    navi2ch-message-mode-map
		    "Menu used in navi2ch-message"
		    navi2ch-message-mode-menu-spec)
  (easy-menu-add navi2ch-message-mode-menu))

(defun navi2ch-message-fill-paragraph (arg)
  (interactive)
  (let ((before (point)))
    (save-excursion
      (forward-paragraph)
      (or (bolp) (newline 1))
      (let ((end (point))
	    (beg (progn (backward-paragraph) (point))))
	(when (eq beg (point-min))
	  (forward-line 3)
	  (setq beg (point)))
	(goto-char before)
	(fill-region-as-paragraph beg end arg)
	t))))

(defun navi2ch-message-mode ()
  "\\{navi2ch-message-mode-map}"
  (interactive)
  (setq major-mode 'navi2ch-message-mode)
  (setq mode-name "Navi2ch Message")
  (set (make-local-variable 'fill-paragraph-function) 'navi2ch-message-fill-paragraph)
  (use-local-map navi2ch-message-mode-map)
  (navi2ch-message-setup-menu)
  (run-hooks 'navi2ch-message-mode-hook)
  (force-mode-line-update))

(defun navi2ch-message-add-aa (alist)
  "aa $B$rDI2C$9$k(B"
  (dolist (pair alist)
    (define-key
      navi2ch-message-mode-map
      (concat navi2ch-message-aa-prefix-key (car pair))
      `(lambda () (interactive) (insert ,(cdr pair))))))
      
;; $B%m!<%I$7$?;~$K8F$P$l$k(B
(navi2ch-message-add-aa navi2ch-message-aa-alist)
				    
(provide 'navi2ch-message)

;;; navi2ch-message.el ends here