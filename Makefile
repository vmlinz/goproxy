DEBUG ?= 0
REVSION = $(shell git rev-list HEAD | wc -l | xargs)

PACKAGE = goproxy
REPO = $(shell git rev-parse --show-toplevel)
BUILDROOT = $(REPO)/build
STAGEDIR = $(BUILDROOT)/stage
OBJECTDIR = $(BUILDROOT)/obj
DISTDIR = $(BUILDROOT)/dist

GOOS ?= $(shell go env GOOS)
GOARCH ?= $(shell go env GOARCH)

ifeq ($(GOOS), windows)
	GOPROXY_EXE = $(PACKAGE).exe
	GOPROXY_STAGEDIR = $(STAGEDIR)
	GOPROXY_DISTCMD = 7za a -y -t7z -mx=9 -m0=lzma2 -mfb=128 -md=64m -ms=on -aoa
	GOPROXY_DISTEXT = .7z
else ifeq ($(GOOS), darwin)
	GOPROXY_EXE = $(PACKAGE)
	GOPROXY_STAGEDIR = $(STAGEDIR)
	GOPROXY_DISTCMD = BZIP=-9 tar cvjpf
	GOPROXY_DISTEXT = .tar.bz2
else
	GOPROXY_EXE = $(PACKAGE)
	GOPROXY_STAGEDIR = $(STAGEDIR)/goproxy
	GOPROXY_DISTCMD = XZ_OPT=-9 tar cvJpf
	GOPROXY_DISTEXT = .tar.xz
endif

OBJECTS :=
OBJECTS += $(OBJECTDIR)/$(GOPROXY_EXE)

SOURCES :=
SOURCES += $(REPO)/README.md
SOURCES += $(REPO)/httpproxy/httpproxy.json
SOURCES += $(wildcard $(REPO)/httpproxy/filters/*/*.json)
SOURCES += $(REPO)/httpproxy/filters/autoproxy/gfwlist.txt

ifeq ($(GOOS), windows)
	SOURCES += $(REPO)/assets/gui/goproxy-gui.exe
	SOURCES += $(REPO)/assets/scripts/addto-startup.vbs
else ifeq ($(GOOS), darwin)
	SOURCES += $(REPO)/assets/gui/goproxy-osx.command
else
	SOURCES += $(REPO)/assets/gui/goproxy-gtk.py
	SOURCES += $(REPO)/assets/scripts/goproxy.sh
endif

LDFLAGS = -X main.version=r$(REVSION)
ifeq ($(DEBUG), 0)
	LDFLAGS += -s -w
endif

.PHONY: build
build: $(DISTDIR)/$(PACKAGE)_$(GOOS)_$(GOARCH)-r$(REVSION)$(GOPROXY_DISTEXT)
	ls -lht $(DISTDIR)

.PHONY: clean
clean:
	$(RM) -rf $(BUILDROOT)

$(DISTDIR)/$(PACKAGE)_$(GOOS)_$(GOARCH)-r$(REVSION)$(GOPROXY_DISTEXT): $(OBJECTS)
	mkdir -p $(DISTDIR) $(STAGEDIR) $(GOPROXY_STAGEDIR)
	cp $(OBJECTS) $(SOURCES) $(GOPROXY_STAGEDIR)
	cd $(STAGEDIR) && $(GOPROXY_DISTCMD) $@ *

$(OBJECTDIR)/$(GOPROXY_EXE):
	mkdir -p $(OBJECTDIR)
	go build -v -ldflags="$(LDFLAGS)" -o $@ .
