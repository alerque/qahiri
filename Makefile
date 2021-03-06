# Copyright (c) 2020 Khaled Hosny
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

MAKEFLAGS := -sr
SHELL = bash

BUILDDIR = build
CONFIG = _config.yml
VERSION = $(shell python version.py $(CONFIG))

.SECONDARY:
.ONESHELL:
.PHONY: all

space :=
space +=

all: Qahiri-Regular.otf Qahiri-Regular.ttx

$(BUILDDIR)/%.unhinted.otf: Qahiri.glyphs $(CONFIG)
	$(info $(space) BUILD  $(*F))
	mkdir -p $(BUILDDIR)
	python build.py $< ${VERSION} $@ $(BUILDDIR)/$(*F).cidinfo $(BUILDDIR)/$(*F).cidmap

$(BUILDDIR)/%.unhinted.cff: $(BUILDDIR)/%.unhinted.otf
	$(info $(space) CFF    $(*F))
	tx -cff +b -no_opt +d $< $@ 2>/dev/null

$(BUILDDIR)/%.hinted.cff: $(BUILDDIR)/%.unhinted.cff
	$(info $(space) HINT   $(*F))
	psautohint $< -o $@

$(BUILDDIR)/%.hinted.cid: $(BUILDDIR)/%.hinted.cff
	$(info $(space) CID    $(*F))
	mergefonts -cid $(BUILDDIR)/$(*F).cidinfo $@ $(BUILDDIR)/$(*F).cidmap $< 2>/dev/null

$(BUILDDIR)/%.cff: $(BUILDDIR)/%.hinted.cid
	$(info $(space) SUBR   $(*F))
	tx -cff +S +b $< $@

%.otf: $(BUILDDIR)/%.cff $(BUILDDIR)/%.unhinted.otf
	sfntedit -a CFF=$+ $@

%.ttx: $(BUILDDIR)/%.unhinted.otf
	$(info $(space) TTX    $(*F))
	ttx -q -o $@ $<

dist:
	mkdir Qahiri-$(VERSION)
	cp Qahiri-Regular.otf README.txt README-Arabic.txt Qahiri-$(VERSION)
	zip -r Qahiri-$(VERSION).zip Qahiri-$(VERSION)
