;; This file is part of Guile-WM.

;;    Guile-WM is free software: you can redistribute it and/or modify
;;    it under the terms of the GNU General Public License as published by
;;    the Free Software Foundation, either version 3 of the License, or
;;    (at your option) any later version.

;;    Guile-WM is distributed in the hope that it will be useful,
;;    but WITHOUT ANY WARRANTY; without even the implied warranty of
;;    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;    GNU General Public License for more details.

;;    You should have received a copy of the GNU General Public License
;;    along with Guile-WM.  If not, see <http://www.gnu.org/licenses/>.

(define-module (guile-wm module window-cycle)
  #:use-module (xcb event-loop)
  #:use-module (xcb xml)
  #:use-module (xcb xml xproto)
  #:use-module (guile-wm icccm)
  #:use-module (guile-wm reparent)
  #:use-module (guile-wm shared)
  #:use-module (guile-wm command)
  #:use-module (guile-wm log)
  #:use-module (guile-wm focus))

(define (pick-next-matching-window start all pred)
  (let pick ((to-test (cdr start)))
    (cond
     ((null? to-test) (pick all))
     ((eq? to-test start) #f)
     ((pred (car to-test)) (car to-test))
     (else (pick (cdr to-test))))))

(define (basic-window-cycle pred)
  (log! "in basic window cycle")
  (define windows (or (reparented-windows) (top-level-windows)))
  (with-replies ((focus get-input-focus))
                (define old (xref focus 'focus))
                (log! (format #f "windows is ~a" windows))
                (if (not (null? windows))
                    (if (not (memv (xid->integer old) (xenum-values input-focus)))
                        (and=> (let find-focus ((w windows))
                                 (log! (format #f "find-focus is ~a and w is ~a" find-focus w))
                                 (cond
                                  ((null? w) #f)
                                  ((xid= (window-parent (car w)) old)
                                   (begin
                                     (log! (format #f  "pick next ~a " (pick-next-matching-window w windows  pred)))
                                     (pick-next-matching-window w windows  pred)))
                                  (else (find-focus (cdr w)))))
                               set-focus)
                        (set-focus (car windows))))))

(define-command (window-cycle)
  "Bring the bottom-most X window to the front and give it the input
focus."
  (begin
    (log! "in window cycle")
    (basic-window-cycle (lambda (win) #t))))

(define-command (visible-window-cycle)
  "Bring the bottom-most visible X window to the front and give it the
input focus. Requires window reparenting to work properly."
  (basic-window-cycle
   (lambda (win) (not (window-obscured? win)))))
