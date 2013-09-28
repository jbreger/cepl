;; Raymarcher!

(defparameter *gpu-array* nil)
(defparameter *vertex-stream* nil)
(defparameter *loop* 0.0)

(defpipeline prog-1 ((position :vec4) &uniform (loop :float) (radius :float) (fog-dist :float))
  (:vertex (setf gl-position position)
           (out posxy (swizzle position :xy)))
  (:fragment 
   (labels ((object ((p :vec3) (r :float))
              (return (+ (* 0.2 (+ (y p)
                                   (sin (+ (* (+ (cos loop) 8.0) (x p)) loop))))
                         (- (length p) r)))))
     (let* ((eye-pos (v! 0.0 0.0 -5.0))
            (eye-dir (normalize (v! (x posxy) (y posxy) 1.0)))
            (e eye-pos)
            (output (v! 0.0 0.0 0.0)))
       (for (i 0) (< i 20) (++ i)
            (let ((d (object e radius)))
              (if (<= d 0.0) 
                  (let ((norm (normalize (v! (- (object (+ e (v! 0.01 0.0 0.0)) radius)
                                                (object (- e (v! 0.01 0.0 0.0)) radius))
                                             (- (object (+ e (v! 0.0 0.01 0.0)) radius)
                                                (object (- e (v! 0.0 0.01 0.0)) radius))
                                             (- (object (+ e (v! 0.0 0.0 0.01)) radius)
                                                (object (- e (v! 0.0 0.0 0.01)) radius))))))
                    (setf output (v! (+ 0.3 (* 0.5 (y norm))) 
                                     0.0
                                     (+ 0.5 (* 0.2 (mix (y norm) (x norm)
                                                        (sin (* 1.0 loop))))) ))
                    (break)))
              (setf d (max d 0.01))
              (setf e (+ e (* eye-dir d)))))
       (out output-color (vec4 output 1.0))))))

(defun run-demo ()
  (cgl:clear-color 0.0 0.0 0.0 0.0)
  (cgl:viewport 0 0 1024 768)
  (setf *gpu-array* (make-gpu-array (list (v! -1.0  -1.0  0.0  1.0)
                                          (v!  1.0  -1.0  0.0  1.0)
                                          (v!  1.0   1.0  0.0  1.0)
                                          (v!  1.0   1.0  0.0  1.0)
                                          (v! -1.0   1.0  0.0  1.0)
                                          (v! -1.0  -1.0  0.0  1.0))
                                    :element-type :vec4
                                    :dimensions 6))
  (setf *vertex-stream* (make-vertex-stream *gpu-array*))
  (loop :until (find :quit-event (sdl:collect-event-types)) :do
     (cepl-utils:update-swank)
     (continuable (draw *vertex-stream*))))

(defun draw (gstream)
  (setf *loop* (+ 0.01 *loop*))
  (gl:clear :color-buffer-bit)  
  (prog-1 gstream :loop *loop* :radius 1.4 :fog-dist 8.0)
  (gl:flush)
  (sdl:update-display))
