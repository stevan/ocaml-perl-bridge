
SOURCES = excelReader.ml
RESULT  = excelReader

PACKS = poCaml

LIBINSTALL_FILES = excelReader.cmi \
		           excelReader.cma excelReader.cmxa excelReader.a

INCDIRS = /usr/local/lib/ocaml/site-lib/poCaml
OCAMLBLDFLAGS = poCaml.cma

all: bcl

opt: ncl

test: all
	prove t/*.ml

-include OCamlMakefile