;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2016 David Thompson <davet@gnu.org>
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

(define-module (gnu packages docker)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix build-system python)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system go)
  #:use-module (guix utils)
  #:use-module (gnu packages base)
  #:use-module (gnu packages databases)
  #:use-module (gnu packages golang)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages python)
  #:use-module (gnu packages python-web)
  #:use-module (gnu packages version-control))

(define-public python-docker-py
  (package
    (name "python-docker-py")
    (version "1.6.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "docker-py" version))
       (sha256
        (base32
         "16ba4xyd46hkj9nkfpz15r8kskl7ljx1afjzchyrhdsrklvzgzim"))))
    (build-system python-build-system)
    ;; TODO: Tests require a running Docker daemon.
    (arguments '(#:tests? #f))
    (inputs
     `(("python-requests" ,python-requests)
       ("python-six" ,python-six)
       ("python-websocket-client" ,python-websocket-client)))
    (home-page "https://github.com/docker/docker-py/")
    (synopsis "Python client for Docker")
    (description "Docker-Py is a Python client for the Docker container
management tool.")
    (license license:asl2.0)))

(define-public python-dockerpty
  (package
    (name "python-dockerpty")
    (version "0.3.4")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "dockerpty" version))
       (sha256
        (base32
         "0za6rr349641wv76ww9l3zcic2xyxrirlxpnzl4296h897648455"))))
    (build-system python-build-system)
    (native-inputs
     `(("python-six" ,python-six)))
    (home-page "https://github.com/d11wtq/dockerpty")
    (synopsis "Python library to use the pseudo-TTY of a Docker container")
    (description "Docker PTY provides the functionality needed to operate the
pseudo-terminal (PTY) allocated to a Docker container using the Python
client.")
    (license license:asl2.0)))

(define-public docker-compose
  (package
    (name "docker-compose")
    (version "1.5.2")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "docker-compose" version))
       (sha256
        (base32
         "0ksg7hm2yvc977968dixxisrhcmvskzpcx3pz0v1kazrdqp7xakr"))))
    (build-system python-build-system)
    ;; TODO: Tests require running Docker daemon.
    (arguments '(#:tests? #f))
    (inputs
     `(("python-docker-py" ,python-docker-py)
       ("python-dockerpty" ,python-dockerpty)
       ("python-docopt" ,python-docopt)
       ("python-jsonschema" ,python-jsonschema)
       ("python-pyyaml" ,python-pyyaml)
       ("python-requests" ,python-requests-2.7)
       ("python-six" ,python-six)
       ("python-texttable" ,python-texttable)
       ("python-websocket-client" ,python-websocket-client)))
    (home-page "https://www.docker.com/")
    (synopsis "Multi-container orchestration for Docker")
    (description "Docker Compose is a tool for defining and running
multi-container Docker applications.  A Compose file is used to configure an
application’s services.  Then, using a single command, the containers are
created and all the services are started as specified in the configuration.")
    (license license:asl2.0)))

(define-public docker
  (let ((commit "3d479c0"))
    (package
      (name "docker")
      (version "18.04.0-ce")
      (home-page "https://www.docker.com/")
      (source (origin
                (method url-fetch)
                (uri (string-append
                      "https://github.com/docker/docker-ce/archive/v" version
                      ".tar.gz"))
                (file-name (string-append name "-" version ".tar.gz"))
                (sha256
                 (base32
                  "0lz2zr2pqj4vhn3s2gwkncfyn3s9is1msprdwi8a9ynwjwm6zlbv"))))
      (native-inputs `(("pkg-config" ,pkg-config)))
      (inputs
       `(("eudev" ,eudev)
         ("go" ,go)
         ("sqlite" ,sqlite)
         ("lvm2" ,lvm2)
         ("btrfs-progs" ,btrfs-progs)
         ("libseccomp" ,libseccomp)))
      (build-system gnu-build-system)
      (arguments
       `(#:tests? #f
         #:strip-binaries? #f
         #:phases
         (modify-phases %standard-phases
           (delete 'configure) ;; no configure
           (replace 'build
             (lambda* (#:key inputs outputs #:allow-other-keys)
               (chdir "components/engine")
               (setenv "DOCKER_GITCOMMIT" ,commit) ; required by build
               (setenv "AUTO_GOPATH" "1") ; FIXME: is this OK?
               (setenv "DOCKER_MAKE_INSTALL_PREFIX" (assoc-ref outputs "out"))
               (setenv "BUILDFLAGS" "-buildmode=pie")
               (setenv "BUILDTAGS" "seccomp pkcs11")
               (invoke "bash" "hack/make.sh" "dynbinary")
               #t))
           (replace 'install
             (lambda* (#:key outputs #:allow-other-keys)
               (let ((bin (string-append (assoc-ref outputs "out") "/bin")))
                 (mkdir-p bin)
                 (copy-file "bundles/dynbinary-daemon/dockerd-dev"
                            (string-append bin "/dockerd"))
                 #t))))))
      (synopsis "Docker is daemon controlling containers")
      (description "Docker is tool-set for process containerization.  This
package contains its daemon.")
      (license license:asl2.0))))

(define-public docker-cli
  (let ((commit "e5980c5"))
    (package
      (name "docker-cli")
      (version "18.05.0-dev")
      (home-page "https://www.docker.com/")
      (source (origin
                (method git-fetch)
                (uri (git-reference
                      (url "https://github.com/docker/cli.git")
                      (commit commit)))
                (file-name (string-append name "-" version "-" commit ".tar.gz"))
                (sha256
                 (base32
                  "0dx3vqdas8f37nvww1hx8b0s5giy6bybzx8z9yfl7nl3pakxckka"))))
      (inputs
       `(("go" ,go)
         ("go-github-com-miekg-pkcs11" ,go-github-com-miekg-pkcs11)))
      (build-system gnu-build-system)
      (arguments
       `(#:tests? #f
         #:phases
         (modify-phases %standard-phases
           (delete 'configure) ;; no configure
           (replace 'build
             (lambda* (#:key inputs outputs #:allow-other-keys)
               (setenv "DOCKER_GITCOMMIT" ,commit) ; required by build
               (setenv "AUTO_GOPATH" "1") ; FIXME: is this OK?
               (setenv "DOCKER_MAKE_INSTALL_PREFIX" (assoc-ref outputs "out"))
               (setenv "BUILDFLAGS" "-buildmode=pie")
               (mkdir-p "src/github.com/docker")
               (symlink (getcwd)
                        (string-append
                         (getcwd)
                         "/src/github.com/docker/cli"))
               (setenv "GOPATH" (getcwd))
               (invoke "./scripts/build/dynbinary")
               #t))
           (replace 'install
             (lambda* (#:key outputs #:allow-other-keys)
               (let ((bin (string-append (assoc-ref outputs "out") "/bin")))
                 (mkdir-p bin)
                 (copy-file "build/docker-linux-amd64"
                            (string-append bin "/docker"))
                 #t))))))
      (synopsis "Command line interface to Docker")
      (description "Docker is tool-set for process containerization.  This
package contains its command line interface.")
      (license license:asl2.0))))

(define-public containerd
  (package
    (name "containerd")
    (version "1.0.3")
    (home-page "https://containerd.io/")
    (source (origin
              (method git-fetch)
                (uri (git-reference
                       (url "https://github.com/containerd/containerd")
                       (commit (string-append "v" version))))
                (file-name (git-file-name name version))
                (sha256
                  (base32
                    "0k1zjn0mpd7q3p5srxld2fr4k6ijzbk0r34r6w69sh0d0rd2fvbs"))))
    (inputs
     `(("go" ,go)
       ("btrfs-progs" ,btrfs-progs)))
    (native-inputs
     `(("make" ,gnu-make)))
    (build-system go-build-system)
    (arguments
     `(#:import-path "github.com/containerd/containerd"
       #:phases
       (modify-phases %standard-phases
         (replace 'build
           (lambda* (#:key inputs outputs #:allow-other-keys)
             (chdir "src/github.com/containerd/containerd")
             (invoke "make" (string-append "GIT_COMMIT=v" ,version))
             #t))
         (replace 'install
           (lambda* (#:key inputs outputs #:allow-other-keys)
             (let ((out (string-append (assoc-ref outputs "out") "/")))
               (mkdir-p (string-append out "bin"))
               (for-each
                (lambda (file)
                  (let ((tgt (string-append out file)))
                    (copy-file file tgt)))
                '("bin/containerd"
                  "bin/containerd-release"
                  "bin/containerd-shim"
                  "bin/containerd-stress"
                  "bin/ctr"))
               #t))))))
      (synopsis "Standalone OCI Container Daemon")
      (description "Containerd is an industry-standard container runtime with
an emphasis on simplicity, robustness and portability.  It is available as a
daemon for Linux and Windows, which can manage the complete container
lifecycle of its host system: image transfer and storage, container execution
and supervision, low-level storage and network attachments, etc.  containerd
is designed to be embedded into a larger system, rather than being used
directly by developers or end-users.")
      (license license:asl2.0)))
