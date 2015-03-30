;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2015 Tomáš Čech <sleep_walker@suse.cz>
;;;
;;; This file is part of GNU Guix.
;;;
;;; GNU Guix is free software; you can redistribute it and/or modify it
;;; under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3 of the License, or (at
;;; your option) any later version.
;;;
;;; GNU Guix is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Guix.  If not, see <http://www.gnu.org/licenses/>.

(define-module (gnu packages flash)
  #:use-module ((guix licenses) #:prefix l:)
  #:use-module (guix packages)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages boost)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages curl)
  #:use-module (gnu packages cyrus-sasl)
  #:use-module (gnu packages gettext)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages gnupg)
  #:use-module (gnu packages gnuzilla)
  #:use-module (gnu packages graphics)
  #:use-module (gnu packages gstreamer)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages image)
  #:use-module (gnu packages llvm)
  #:use-module (gnu packages openssl)
  #:use-module (gnu packages pcre)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages qt)
  #:use-module (gnu packages sdl)
  #:use-module (gnu packages video)
  #:use-module (gnu packages xiph)
  #:use-module (gnu packages xml)
  #:use-module (gnu packages yasm)
  #:use-module (gnu packages)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix build-system cmake)
  #:use-module (guix build-system gnu))

(define-public gnash
  (package
    (name "gnash")
    (version "0.8.10+")
    (source
     (origin
       ;; release is too old to be built correctly against ffmpeg, libjpeg and
       ;; more, lets go with head containing all required fixes already
       (method git-fetch)
       (uri (git-reference
             (url "git://git.sv.gnu.org/gnash.git")
             (commit "6675d736bf4d7")))
       (sha256
        (base32 "0j9mvg2jdp398dfdnmxfzhiaqm79h0ic2airmvgmf22rrsx2flgw"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("pkg-config" ,pkg-config)
       ("libtool" ,libtool)
       ("autoconf" ,autoconf)
       ("automake" ,automake)
       ("bash" ,bash)))
    (inputs
     ;; gstreamer 0.10 is required, but not available, gstreamer-1.0 not
     ;; supported yet - lets go with ffmpeg instead
     `(("agg" ,agg)
       ("boost" ,boost)
       ("curl" ,curl) ; FIXME: compile in RTMP support
       ("cyrus-sasl" ,cyrus-sasl)
       ("ffmpeg" ,ffmpeg)
       ("gconf" ,gconf)
       ("gettext" ,gnu-gettext)
       ("giflib" ,giflib)
       ("gtk+-2" ,gtk+-2)
       ("icecat" ,icecat)
       ("libgcrypt" ,libgcrypt)
       ("libjpeg" ,libjpeg)
       ("libltdl" ,libltdl)
       ("npapi-sdk" ,npapi-sdk)
       ("nspr" ,nspr)
       ("openssl" ,openssl)
       ("pango" ,pango)
       ("pangox-compat" ,pangox-compat)
       ("perl" ,perl)
       ("qt-4" ,qt-4)
       ("sdl", sdl)
       ("speex", speex)))
    (arguments
     `(#:configure-flags
       (list
        "--enable-media=gst"
;;        "--enable-media=ffmpeg"
        "--disable-jemalloc"
        "--with-npapi-install=system"
        (string-append "--with-npapi-plugindir=" (assoc-ref %outputs "out")
                       "/lib/mozilla/plugins")
        (string-append "--with-pango-incl="
                       (assoc-ref %build-inputs "pango") "/include/pango-1.0")
        (string-append "--with-pango-lib="
                       (assoc-ref %build-inputs "pangox-compat") "/lib")
        (string-append "--with-boost-incl="
                       (assoc-ref %build-inputs "boost") "/include/")
        (string-append "--with-boost-lib="
                       (assoc-ref %build-inputs "boost") "/lib")
        (string-append "--with-npapi-incl=" (assoc-ref %build-inputs "icecat")
                       "/include/icecat-31.5.0"))
       #:phases
       (alist-cons-after
        'unpack 'autoreconf
        (lambda _
          (zero? (system* "sh" "autogen.sh")))
        (alist-cons-after
         'install 'install-plugins
         (lambda _
           (zero? (system* "make" "install-plugins")))
        %standard-phases))))
    (home-page "https://www.gnu.org/software/gnash/")
    (synopsis "GNU Flash movie player")
    (description
     "Gnash is a free Flash movie player.  It supports SWF version v7 and some
of v8 and v9.  It is possible to configure Gnash to use several different
audio or video backends, ensuring good performance.")
    (license l:gpl3+)))

(define-public lightspark
  (package
    (name "lightspark")
    (version "0.7.2")
    (source
     (origin
      (method url-fetch)
      (uri
       (string-append
        "https://github.com/lightspark/lightspark/archive/lightspark-"
                          version ".tar.gz"))
      (sha256
       (base32
        "09p36k3477nn9181vn6ni036bwyz9387393hyzhfsbh41k4ynnap"))))
    (build-system cmake-build-system)
    (native-inputs
     `(("pkg-config" ,pkg-config)))
    (inputs
     `(("boost" ,boost)
       ("cairo" ,cairo)
       ("curl" ,curl)
       ("ffmpeg" ,ffmpeg)
       ("glew" ,glew)
       ("libjpeg" ,libjpeg)
       ("libxml2" ,libxml2)
       ("libxmlpp" ,libxmlpp)
       ("llvm" ,llvm)
       ("mesa" ,mesa)
       ("pcre" ,pcre)
       ("yasm" ,yasm)
       ("zlib" ,zlib)))
    ;; libglew, librtmp
    (arguments
     `(#:configure-flags
       (list (string-append "-DCMAKE_ASM-NASM_COMPILER="
                            (assoc-ref %build-inputs "yasm") "/bin/yasm"))))
    (home-page "https://github.com/lightspark/lightspark")
    (synopsis "Open source implementation of flash")
    (description "blah blah")
    (license l:gpl3)))
