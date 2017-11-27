;;; doi2bib.el --- Interface for doi.org  -*- lexical-binding: t -*-

;; Copyright (C) 2017 Alexander Griffith
;; Author: Johnson Denen <alexjgriffith@gmail.com>
;; Version: 0.1.0
;; Package-Requires: ((emacs "25.0"))
;; Homepage: https://github.com/alexjgriffith/doi2bib.el

;; This file is not part of GNU Emacs.

;; This file is part of doi2bib.el.

;; doi2bib.el is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; doi2bib.el is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with mastodon.el.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;; Code:
(defcustom doi2bib-output-buffer "doi2bib-scratch"
  "The temporary output buffer for BibTex results.")

(defun doi2bib-get-request (doi &optional buffer)
  (let ((url-request-method "GET")
        (url-mime-accept-string "application/x-bibtex; charset=utf-8")
        (buffer (or buffer (concat "*bibtex-" doi "*"))))
    (with-current-buffer (get-buffer-create buffer)
      (bibtex-mode))
    (url-retrieve (concat "https://doi.org/" doi)
                  (lambda (status buffer)
                    (goto-char (point-min))
                    (let ((str (buffer-substring  (+ 1 (search-forward-regexp "^$")) (point-max))))
                      (kill-buffer (current-buffer))
                      (with-current-buffer (get-buffer-create buffer)
                        (goto-char (point-max))
                                   (insert (format "%s\n\n" str) )
                                    (current-buffer))))
                  (list buffer))
    buffer))

(defun doi2bib-get-doi-list (doi-list buffer)
  (mapcar (lambda(doi)(doi2bib-get-request doi buffer)) doi-list)
  (switch-to-buffer (get-buffer-create buffer)))

(defun doi2bib-convert-file (file)
  (interactive)
  (warn "stub")
  )

(defun doi2bib (doi &optional buffer)
  (interactive "sDOI:")
  (doi2bib-get-doi-list '(doi) doi2bib-output-buffer ))

(defun doi2bib-select-pair ()
  (interactive)
  (let ((start (point))
        (end (re-search-forward ")" nil t))
        (buffer (current-buffer)))
    (goto-char start)
    (when end
      (with-current-buffer (get-buffer-create "lit-cites2.txt")
        (goto-char (point-max))
        (insert-buffer-substring  buffer start end)
        (insert "\n" )
        t))))

(defun doi2bib-select-pair-next ()
  (interactive)
  (re-search-forward "(")
  (goto-char (- (point) 1))
  (let ((ret (doi2bib-select-pair)))
    (re-search-forward ")")
    ret))

(defun doi2bib-subsel ()
  (let ((previous (point))
        (end (re-search-forward "(.*)" nil t))
        (start (re-search-backward "(.*)" nil t)))
    (goto-char previous)
    (when end
      (goto-char end)
      (buffer-substring start end))))

(defun get-within-parens ()
  (let((x (doi2bib-subsel))
       (y '()))
    (while x
      (push x y)
      (setq x (doi2bib-subsel)))
    (mapconcat (lambda (x) x)y "\n")))

(defun doi2bib-subsel-into-new-buffer ()
  (let ((vals (get-within-parens)))
    (with-current-buffer (get-buffer-create "test") (insert vals))))

(defun doi2bib-get-doi-list-example()
  "Request the bibtex for a sample doi 10.1136/tobaccocontrol-2012-050740"
  (interactive)
  (doi2bib-get-doi-list '("10.1136/tobaccocontrol-2012-050740") "*temp*" ))

(provide 'doi2bib)
;;; doi2bib.el ends here
