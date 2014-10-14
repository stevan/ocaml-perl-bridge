
SOURCES = template.ml
RESULT  = template

PACKS = poCaml

LIBINSTALL_FILES = template.cmi \
		           template.cma template.cmxa template.a

INCDIRS = /usr/local/lib/ocaml/site-lib/poCaml
OCAMLBLDFLAGS = poCaml.cma

all: bcl

opt: ncl

test: all
	prove t/*.ml

-include OCamlMakefile