
include Makefile.config

OCAMLC := ocamlc
OCAMLOPT := ocamlopt
OCAMLMKLIB := ocamlmklib
OCAMLDEP := ocamldep
OCAMLDOC := ocamldoc

OCAMLCFLAGS := -w s -g
OCAMLOPTFLAGS := -w s

PERLCFLAGS := $(shell perl -e 'use Config; print $$Config{ccflags};')

CC := gcc
CFLAGS := -fPIC -Wall -Wno-unused -I$(PERLINCDIR) $(PERLCFLAGS) $(EXTRA_CFLAGS)

LIBPERL := $(shell perl -MExtUtils::Embed -e ldopts)

SED := sed

OCAMLDOCFLAGS := -html -stars -sort $(OCAMLCINCS)

all:	poCaml.cma

opt:    poCaml.cmxa

poCaml.cma: poCaml.cmo pocaml_c.o
	$(OCAMLMKLIB) -o poCaml $(LIBPERL) $^

poCaml.cmxa: poCaml.cmx pocaml_c.o
	$(OCAMLMKLIB) -o poCaml $(LIBPERL) $^

%.bc: %.cmo
	$(OCAMLC) $(OCAMLCFLAGS) poCaml.cma $^ -o $@

%.opt: %.cmx
	$(OCAMLOPT) $(OCAMLOPTFLAGS) -cclib -L. poCaml.cmxa \
	$(DYNALOADER_HACK) $^ -o $@

%.cmi: %.mli
	$(OCAMLC) $(OCAMLCFLAGS) -c $<

%.cmo: %.ml
	$(OCAMLC) $(OCAMLCFLAGS) -c $<

%.cmx: %.ml
	$(OCAMLOPT) $(OCAMLOPTFLAGS) -c $<

.SUFFIXES: .mli .ml .cmi .cmo .cmx

# Tests

test: all
	prove t/*.ml

# Clean.

JUNKFILES = core *~ *.bak *.cmi *.cmo *.cmx *.cma *.cmxa *.o *.a *.so \
	*.bc *.opt

clean:
	for d in .; do \
	  (cd $$d; rm -f $(JUNKFILES)); \
	done

# Build dependencies.

ifeq ($(wildcard .depend),.depend)
include .depend
endif

depend:	.depend

.depend: $(wildcard *.ml) $(wildcard *.mli)
	$(OCAMLDEP) $(OCAMLCINCS) *.mli *.ml
	> .depend

# Install.

install:
	rm -rf $(DESTDIR)$(OCAMLLIBDIR)/site-lib/poCaml
	install -c -m 0755 -d $(DESTDIR)$(OCAMLLIBDIR)/site-lib/poCaml
	install -c -m 0755 -d $(DESTDIR)$(OCAMLLIBDIR)/stublibs
	install -c -m 0644 poCaml.cmi poCaml.cma poCaml.cmxa \
	  poCaml.a libpoCaml.a META \
	  $(DESTDIR)$(OCAMLLIBDIR)/site-lib/poCaml
	install -c -m 0644 dllpoCaml.so $(DESTDIR)$(OCAMLLIBDIR)/stublibs
