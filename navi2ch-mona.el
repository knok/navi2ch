;;; navi2ch-mona.el --- Mona Font Utils for Navi2ch

;; Copyright (C) 2001 by Navi2ch Project

;; Author: Taiki SUGAWARA <taiki@users.sourceforge.net>
;; 431 $B$NL>L5$7$5$s(B
;; 874 $B$NL>L5$7$5$s(B
;; UEYAMA Rui <rui314159@users.sourceforge.net>
;; part5 $B%9%l$N(B 26, 45 $B$5$s(B

;; The part of find-face is originated form apel (poe.el).
;; You can get the original apel from <ftp://ftp.m17n.org/pub/mule/apel>.
;; poe.el's Authors:  MORIOKA Tomohiko <tomo@m17n.org>
;;      Shuhei KOBAYASHI <shuhei@aqua.ocn.ne.jp>
;; apel is also licened under GPL.

;; Keywords: 2ch, network

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

;;; Commentary:

;; custom $B$r;H$C$F(B M-x customize-group navi2ch-mona $B$+$i(B
;; $B@_Dj$9$k$H%i%/%A%s!#(B

;;; Code:
(provide 'navi2ch-mona)
(defvar navi2ch-mona-ident
  "$Id$")
(eval-when-compile (require 'cl))
(require 'navi2ch-util)

(eval-when-compile
  (navi2ch-defalias-maybe 'set-face-attribute 'ignore)
  (autoload 'x-decompose-font-name "fontset"))

(make-face 'navi2ch-mona-face)
(make-face 'navi2ch-mona12-face)
(make-face 'navi2ch-mona14-face)
(make-face 'navi2ch-mona16-face)

(defvar navi2ch-mona-create-fontset nil)
(eval-when-compile
  (navi2ch-defalias-maybe 'query-fontset 'ignore)
  (navi2ch-defalias-maybe 'new-fontset 'ignore))

;; $B%+%9%?%^%$%:JQ?t$N(B defcustom $B$KI,MW$J4X?t(B
(defun navi2ch-mona-create-fontset-from-family-name (family-name height)
  "navi2ch $B$,I,MW$H$9$k%U%)%s%H%;%C%H$r:n$j!"$=$NL>A0$rJV$9!#(B

FAMILY-NAME $B$O(B \"foundry-family\" $B$+$i$J$kJ8;zNs!#(BHEIGHT $B$O(B pixelsize$B!#(B

XEmacs $B$G$OL@<(E*$K%U%)%s%H%;%C%H$r:n$kI,MW$,$J$$$N$G!"(B
$B%U%)%s%H%;%C%HL>$H$7$F0UL#$N$"$kJ8;zNs(B
 \"-<FAMILY-NAME>-medium-r-*--<height>-*-*-*-p-*-*-*\"
$B$rJV$9$@$1!#(B"
  (let ((fontset-name (format "-%s-medium-r-*--%d-*-*-*-p-*-*-*"
                              family-name height)))
    (if (or navi2ch-on-xemacs
	    (not navi2ch-mona-create-fontset))
	fontset-name
      (let* ((fields (x-decompose-font-name fontset-name))
	     (foundry (aref fields 0))
	     (family (aref fields 1))
	     (slant (aref fields 3))
	     (swidth (aref fields 4))
	     (fontset-templ (format
			     "-%s-%s-%%s-%s-%s--%d-*-*-*-p-*-fontset-mona%d"
			     foundry family slant swidth height height))
	     (font-templ (progn
			   (string-match "^\\(.*\\)\\(fontset-mona[^-]+\\)$"
					 fontset-templ)
			   (concat (match-string 1 fontset-templ) "%s")))
	     (fontset (format "-%s-%s-*-*-*--%d-*-*-*-*-*-%s"
			      foundry family height
			      (match-string 2 fontset-templ))))
	(setq fontset-name fontset)
	(dolist (weight '("medium" "bold"))
	  (let ((fontset (format fontset-templ weight))
		(font (format font-templ weight "%s")))
	    (unless (query-fontset fontset)
	      (new-fontset fontset
			   (list (cons 'ascii
				       (format font "iso8859-1"))
				 (cons 'latin-iso8859-1
				       (format font "iso8859-1"))
				 (cons 'katakana-jisx0201
				       (format font "jisx0201.1976-0"))
				 (cons 'latin-jisx0201
				       (format font "jisx0201.1976-0"))
				 (cons 'japanese-jisx0208
				       (format font "jisx0208.1990-0"))))))))
      fontset-name)))

(defun navi2ch-mona-set-font-family-name (symbol value)
  "VALUE$B$G;XDj$5$l$k%U%)%s%H%;%C%H$K1~$8$F%U%'%$%9$r:n@.$9$k!#(B"
  (condition-case nil
      (progn
	(dolist (height '(12 14 16))
	  (let ((fontset (navi2ch-mona-create-fontset-from-family-name
			  value height))
		(face (intern (format "navi2ch-mona%d-face" height))))
	    (set-face-font face fontset)))
	(set-default symbol value))
    (error nil)))

;; Customizable variables.
(defcustom navi2ch-mona-enable nil
  "*non-nil $B$J$i!"%b%J!<%U%)%s%H$r;H$C$F%9%l$rI=<($9$k!#(B"
  :set (lambda (symbol value)
	 (if value
	     (navi2ch-mona-setup)
	   (navi2ch-mona-undo-setup))
	 (set-default symbol value))
  :initialize 'custom-initialize-default
  :type 'boolean
  :group 'navi2ch-mona)

(defcustom navi2ch-mona-enable-board-list nil
  "*$B%b%J!<%U%)%s%H$GI=<($9$kHD$N%j%9%H!#(B"
  :type '(repeat (string :tag "$BHD(B"))
  :group 'navi2ch-mona)

(defcustom navi2ch-mona-disable-board-list nil
  "*$B%b%J!<%U%)%s%H$r;H$o$J$$HD$N%j%9%H!#(B"
  :type '(repeat (string :tag "$BHD(B"))
  :group 'navi2ch-mona)

(defcustom navi2ch-mona-pack-space-p nil
  "*non-nil $B$J$i!"(BWeb $B%V%i%&%6$N$h$&$K(B2$B$D0J>e$N6uGr$O(B1$B$D$K$^$H$a$FI=<($9$k!#(B"
  :type 'boolean
  :group 'navi2ch-mona)

(defcustom navi2ch-mona-font-family-name "mona-gothic"
  "*$B%b%J!<%U%)%s%H$H$7$F;H$&%U%)%s%H$N(B family $BL>!#(B
XLFD $B$G$$$&(B \`foundry-family\' $B$r;XDj$9$k!#MW$9$k$K(B X $B$G$N(B
$B%U%)%s%HL>$N:G=i$N(B2$B%U%#!<%k%I$r=q$1$P$$$$$C$F$3$C$?!#(B

XEmacs $B$G$O!";XDj$5$l$?(B family $B$KBP$7$F(B pixelsize: 12/14/16
$B$N(B 3$B$D$N%U%)%s%H%;%C%H$r:n$k!#(B

Emacs 21 $B$G$O!"$=$l$K2C$($F(B medium/bold $B$J%U%)%s%H$rJL!9$K:n$k!#(B
$B$?$H$($P0z?t(B \`moga-gothic\' $B$,$o$?$5$l$k$H!"(B

 -mona-gothic-medium-r-*--12-*-*-*-*-*-fontset-mona12
 -mona-gothic-medium-r-*--14-*-*-*-*-*-fontset-mona14
 -mona-gothic-medium-r-*--16-*-*-*-*-*-fontset-mona16
 -mona-gothic-bold-r-*--12-*-*-*-*-*-fontset-mona12
 -mona-gothic-bold-r-*--14-*-*-*-*-*-fontset-mona14
 -mona-gothic-bold-r-*--16-*-*-*-*-*-fontset-mona16

$B$H$$$&(B 6 $B$D$N%U%)%s%H%;%C%H$r:n$k$3$H$K$J$k!#(B

$BJ8;z$N$+$o$j$K%H!<%U$,I=<($5$l$A$c$&$N$O!"$?$V$s%U%)%s%H$,(B
$B8+$D$+$i$J$+$C$?$;$$$J$N$G!"(B\`xlsfonts\' $B$r<B9T$7$F(B

-<$B;XDj$7$?J8;zNs(B>-{medium,bold}-r-*--{12,14,16}-*-*\\
-*-*-*-{iso8859-1,jisx0201.1976-0,jisx0208.(1983|1990)-0}

$B$,$"$k$+$I$&$+3N$+$a$F$M!#(B"
  :type '(choice (string :tag "Mona Font"
			 :value "mona-gothic")
		 (const :tag "MS P Gothic"
			:value "microsoft-pgothic")
		 (string :tag "family name"))
  :set 'navi2ch-mona-set-font-family-name
  :initialize 'custom-initialize-reset
  :group 'navi2ch-mona)

(defconst navi2ch-mona-sample-string
  (concat "$B%5%s%W%k%F%-%9%H%2%C%H%)!*!*(B $B$R$i$,$J!"%+%?%+%J!"(BRoman Alphabet$B!#(B\n"
          (decode-coding-string
           (base64-decode-string
	    (concat
	     "gVCBUIFQgVCBUIHJgVCBUIFQgVCBUIFQgVCBUIFAgUAogUyBTAqBQIFAgUCBQCCB"
	     "yIHIgUCBQIFAgWqBQIFAgUCBQIFAgUAogUyB3CiBTAqBQIFAgbyBad+ERN+BvIHc"
	     "gU2CwoHfgd+B3yiBTIHcOzs7gd+B34HfCoFAgUCBQIFAgUCBQCCBUIFQgUAgKIFM"
	     "gdwogUyB3Ds7CoFAgUCBQIFAgUCBQL3eu9673rCwsLCwryK93rveCg=="))
	   'shift_jis)))

(defcustom navi2ch-mona-face-variable t
  "*$B%G%U%)%k%H$N(B Mona face $B$rA*$V!#(B"
  :type `(radio (const :tag "navi2ch-mona16-face"
                       :sample-face navi2ch-mona16-face
                       :doc ,navi2ch-mona-sample-string
                       :format "%t:\n%{%d%}\n"
                       navi2ch-mona16-face)
                (const :tag "navi2ch-mona14-face"
                       :sample-face navi2ch-mona14-face
                       :doc ,navi2ch-mona-sample-string
                       :format "%t:\n%{%d%}\n"
                       navi2ch-mona14-face)
                (const :tag "navi2ch-mona12-face"
                       :sample-face navi2ch-mona12-face
                       :doc ,navi2ch-mona-sample-string
                       :format "%t:\n%{%d%}\n"
                       navi2ch-mona12-face)
                (const :tag "$B%G%U%)%k%H$N%U%)%s%H$HF1$8%5%$%:$N(B face $B$r<+F0A*Br$9$k(B"
                       t))
  :set (function (lambda (symbol value)
                   (set-default symbol value)
                   (navi2ch-mona-set-mona-face)))
  :initialize 'custom-initialize-default
  :group 'navi2ch-mona)

(defcustom navi2ch-mona-on-message-mode nil
  "*non-nil $B$N>l9g!"%l%9$r=q$/;~$K$b%b%J!<%U%)%s%H$r;H$&!#(B"
  :type 'boolean
  :group 'navi2ch-mona)

;; defun find-face for GNU Emacs
;; the code is originated from apel.
(defun navi2ch-find-face-subr (face-or-name)
  "Retrieve the face of the given name.
If FACE-OR-NAME is a face object, it is simply returned.
Otherwise, FACE-OR-NAME should be a symbol.  If there is no such face,
nil is returned.  Otherwise the associated face object is returned."
  (car (memq face-or-name (face-list))))

(defmacro navi2ch-find-face (face-or-name)
  (if (fboundp 'find-face)
      `(find-face ,face-or-name)
    `(navi2ch-find-face-subr ,face-or-name)))

(defmacro navi2ch-mona-char-height ()
  (if (featurep 'xemacs)
      '(font-height (face-font 'default))
    '(frame-char-height)))

(defmacro navi2ch-set-face-parent (face parent)
  (if (featurep 'xemacs)
      `(set-face-parent ,face ,parent)
    `(set-face-attribute ,face nil :inherit ,parent)))

;; functions
(defun navi2ch-mona-set-mona-face ()
  (let ((parent navi2ch-mona-face-variable))
    (when (eq t parent)
      (let* ((height (navi2ch-mona-char-height))
	     (face-name (if height
			    (format "navi2ch-mona%d-face" height)
			  "navi2ch-mona16-face")))
	(setq parent (intern face-name))))
    (when (navi2ch-find-face parent)
      (navi2ch-set-face-parent 'navi2ch-mona-face parent))))

(defun navi2ch-mona-put-face ()
  "face $B$,FC$K;XDj$5$l$F$$$J$$ItJ,$r(B mona-face $B$K$9$k!#(B
`navi2ch-article-face' $B$NItJ,$b(B mona-face $B$K$9$k!#(B"
  (save-excursion
    (goto-char (point-min))
    (let (p face)
      (while (not (eobp))
	(setq p (next-single-property-change (point)
					     'face nil (point-max)))
	(setq face (get-text-property (point) 'face))
	(if (or (null face)
		(eq face 'navi2ch-article-face))
	    (put-text-property (point) (1- p)
			       'face 'navi2ch-mona-face))
	(goto-char p)))))

(defun navi2ch-mona-pack-space ()
  "$BO"B3$9$k(B2$B$D0J>e$N6uGr$r(B1$B$D$K$^$H$a$k!#(B"
  (save-excursion
    (goto-char (point-min))
    (while (re-search-forward "^ +" nil t)
      (replace-match ""))
    (goto-char (point-min))
    (while (re-search-forward "  +" nil t)
      (replace-match " "))))

(defun navi2ch-mona-arrange-message ()
  "$B%b%J!<%U%)%s%H$r;H$&HD$J$i$=$N$?$a$N4X?t$r8F$V!#(B"
  (let ((id (cdr (assq 'id navi2ch-article-current-board))))
    (when (or (member id navi2ch-mona-enable-board-list)
	      (and (not (member id navi2ch-mona-disable-board-list))
		   navi2ch-mona-enable))
      (navi2ch-mona-put-face))
    (when navi2ch-mona-pack-space-p
      (navi2ch-mona-pack-space))))

(defun navi2ch-mona-message-mode-hook ()
  (if navi2ch-mona-on-message-mode
      (navi2ch-ifxemacs
	  (let ((extent (make-extent (point-min) (point-max))))
	    (set-extent-properties extent
				   '(face navi2ch-mona-face
					  start-closed t end-closed t)))
	(let ((overlay (make-overlay (point-min) (point-max) nil nil t)))
	  (overlay-put overlay 'face 'navi2ch-mona-face)))))

(defun navi2ch-mona-setup ()
  "*$B%b%J!<%U%)%s%H$r;H$&$?$a$N%U%C%/$rDI2C$9$k!#(B"
  (when (and (eq window-system 'x)	; NT Emacs $B$G$bF0$/$N$+$J(B?
	     (or navi2ch-on-emacs21 navi2ch-on-xemacs))
    (navi2ch-mona-set-mona-face)	; $B2?2s8F$s$G$bBg>fIW(B
    (add-hook 'navi2ch-article-arrange-message-hook
	      'navi2ch-mona-arrange-message)
    (add-hook 'navi2ch-message-mode-hook
	      'navi2ch-mona-message-mode-hook)))

(defun navi2ch-mona-undo-setup ()
  (remove-hook 'navi2ch-article-arrange-message-hook
	       'navi2ch-mona-arrange-message)
  (remove-hook 'navi2ch-message-mode-hook
	       'navi2ch-mona-message-mode-hook))

(run-hooks 'navi2ch-mona-load-hook)
;;; navi2ch-mona.el ends here
