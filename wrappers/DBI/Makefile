
SOURCES = dBI.ml
RESULT  = dBI

PACKS = poCaml

LIBINSTALL_FILES = dBI.cmi \
		           dBI.cma dBI.cmxa dBI.a

INCDIRS = /usr/local/lib/ocaml/site-lib/poCaml
OCAMLBLDFLAGS = poCaml.cma

all: bcl

opt: ncl

test: all
	prove t/*.ml

-include OCamlMakefile