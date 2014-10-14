
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <unistd.h>
#include <alloca.h>

#define CAML_NAME_SPACE 1

/* Fix me (probably needs some setting the Makefile) */ 
#include </usr/local/lib/ocaml/caml/alloc.h>
#include </usr/local/lib/ocaml/caml/callback.h>
#include </usr/local/lib/ocaml/caml/custom.h>
#include </usr/local/lib/ocaml/caml/fail.h>
#include </usr/local/lib/ocaml/caml/memory.h>
#include </usr/local/lib/ocaml/caml/mlvalues.h>

#include <EXTERN.h>
#include <perl.h>

/* Perl requires the interpreter to be called literally 'my_perl'! */
static PerlInterpreter *my_perl;

/* Get the concrete value from an optional field. */
static value unoption (value option, value deflt);

/* Wrap up an arbitrary void pointer in an opaque OCaml object. */
static value Val_voidptr (void *ptr);

/* Unwrap an arbitrary void pointer from an opaque OCaml object. */
#define Voidptr_val(type,rv) ((type *) Field ((rv), 0))

#if PERL4CAML_REFCOUNTING_EXPERIMENTAL

/* Unwrap a custom block. */
#define Xv_val(rv) (*((void **)Data_custom_val(rv)))

/* Wrap up an SV, AV or HV in a custom OCaml object which will decrement
 * the reference count on finalization.
 */
static value Val_xv (SV *sv);

#else

#define Xv_val(rv) Voidptr_val (SV, (rv))
#define Val_xv(sv) Val_voidptr ((sv))

#endif

/* Hide Perl types in opaque OCaml objects. */
#define Val_perl(pl) (Val_voidptr ((pl)))
#define Perl_val(plv) (Voidptr_val (PerlInterpreter, (plv)))
#define Val_sv(sv) (Val_xv ((sv)))
#define Sv_val(svv) ((SV *) Xv_val (svv))
#define Val_av(av) (Val_xv ((SV *)(av)))
#define Av_val(avv) ((AV *) Xv_val (avv))
#define Val_hv(hv) (Val_xv ((SV *)(hv)))
#define Hv_val(hvv) ((HV *) Xv_val (hvv))
#define Val_he(he) (Val_voidptr ((he)))
#define He_val(hev) (Voidptr_val (HE, (hev)))

static void
xs_init (pTHX)
{
  char *file = __FILE__;
  EXTERN_C void boot_DynaLoader (pTHX_ CV* cv);

  newXS("DynaLoader::boot_DynaLoader", boot_DynaLoader, file);
}

CAMLprim value
pocaml_init (value unit)
{
  CAMLparam1 (unit);
  int argc = 4;
  static char *argv[] = { "", "-w", "-e", "0", NULL };

  PERL_SYS_INIT (&argc, &argv);
  my_perl = perl_alloc ();
  perl_construct (my_perl);
  PL_exit_flags |= PERL_EXIT_DESTRUCT_END;
  perl_parse (my_perl, xs_init, argc, argv, (char **) NULL);
  /*perl_run (my_perl);*/

  CAMLreturn (Val_unit);
}

CAMLprim value
pocaml_int_of_sv (value svv)
{
  CAMLparam1 (svv);
  SV *sv = Sv_val (svv);
  CAMLreturn (Val_int (SvIV (sv)));
}

CAMLprim value
pocaml_sv_of_int (value iv)
{
  CAMLparam1 (iv);
  CAMLreturn (Val_sv (newSViv (Int_val (iv))));
}

CAMLprim value
pocaml_float_of_sv (value svv)
{
  CAMLparam1 (svv);
  SV *sv = Sv_val (svv);
  CAMLlocal1 (f);
  f = caml_copy_double (SvNV (sv));
  CAMLreturn (f);
}

CAMLprim value
pocaml_sv_of_float (value fv)
{
  CAMLparam1 (fv);
  CAMLreturn (Val_sv (newSVnv (Double_val (fv))));
}

CAMLprim value
pocaml_string_of_sv (value svv)
{
  CAMLparam1 (svv);
  SV *sv = Sv_val (svv);
  char *str;
  STRLEN len;
  CAMLlocal1 (strv);
  str = SvPV (sv, len);
  strv = caml_alloc_string (len);
  memcpy (String_val (strv), str, len);
  CAMLreturn (strv);
}

CAMLprim value
pocaml_sv_of_string (value strv)
{
  CAMLparam1 (strv);
  CAMLreturn (Val_sv (newSVpv (String_val (strv), caml_string_length (strv))));
}

CAMLprim value
pocaml_sv_is_true (value svv)
{
  CAMLparam1 (svv);
  SV *sv = Sv_val (svv);
  CAMLreturn (SvTRUE (sv) ? Val_true : Val_false);
}

CAMLprim value
pocaml_sv_undef (value unit)
{
  CAMLparam1 (unit);
  /*CAMLreturn (Val_sv (newSV (0)));*/
  CAMLreturn (Val_sv (&PL_sv_undef));
}

CAMLprim value
pocaml_sv_is_undef (value svv)
{
  CAMLparam1 (svv);
  SV *sv = Sv_val (svv);
  CAMLreturn (!SvPOK (sv) && !SvIOK (sv) && SvTYPE (sv) == SVt_NULL
	      ? Val_true : Val_false);
}

CAMLprim value
pocaml_sv_yes (value unit)
{
  CAMLparam1 (unit);
  CAMLreturn (Val_sv (&PL_sv_yes));
}

CAMLprim value
pocaml_sv_no (value unit)
{
  CAMLparam1 (unit);
  CAMLreturn (Val_sv (&PL_sv_no));
}

CAMLprim value
pocaml_sv_type (value svv)
{
  CAMLparam1 (svv);
  SV *sv = Sv_val (svv);

  switch (SvTYPE (sv))
    {
    case SVt_IV: CAMLreturn (Val_int (1));
    case SVt_NV: CAMLreturn (Val_int (2));
    case SVt_PV: CAMLreturn (Val_int (3));
    case SVt_RV: CAMLreturn (Val_int (4));
    case SVt_PVAV: CAMLreturn (Val_int (5));
    case SVt_PVHV: CAMLreturn (Val_int (6));
    case SVt_PVCV: CAMLreturn (Val_int (7));
    case SVt_PVGV: CAMLreturn (Val_int (8));
    case SVt_PVMG: CAMLreturn (Val_int (9));
    default: CAMLreturn (Val_int (0));
    }
}

CAMLprim value
pocaml_address_of_sv (value svv)
{
  CAMLparam1 (svv);
  SV *sv = Sv_val (svv);
  CAMLreturn (caml_copy_nativeint ((long) sv));
}

CAMLprim value
pocaml_address_of_av (value avv)
{
  CAMLparam1 (avv);
  AV *av = Av_val (avv);
  CAMLreturn (caml_copy_nativeint ((long) av));
}

CAMLprim value
pocaml_address_of_hv (value hvv)
{
  CAMLparam1 (hvv);
  HV *hv = Hv_val (hvv);
  CAMLreturn (caml_copy_nativeint ((long) hv));
}

CAMLprim value
pocaml_scalarref (value svv)
{
  CAMLparam1 (svv);
  CAMLlocal1 (rsvv);
  SV *sv = Sv_val (svv);
  rsvv = Val_sv (newRV_inc (sv));
  CAMLreturn (rsvv);
}

CAMLprim value
pocaml_arrayref (value avv)
{
  CAMLparam1 (avv);
  CAMLlocal1 (rsvv);
  AV *av = Av_val (avv);
  rsvv = Val_sv (newRV_inc ((SV *) av));
  CAMLreturn (rsvv);
}

CAMLprim value
pocaml_hashref (value hvv)
{
  CAMLparam1 (hvv);
  CAMLlocal1 (rsvv);
  HV *hv = Hv_val (hvv);
  rsvv = Val_sv (newRV_inc ((SV *) hv));
  CAMLreturn (rsvv);
}

CAMLprim value
pocaml_deref (value svv)
{
  CAMLparam1 (svv);
  CAMLlocal1 (rsvv);
  SV *sv = Sv_val (svv);

  if (!SvROK (sv))
    caml_invalid_argument ("deref: SV is not a reference");
  switch (SvTYPE (SvRV (sv))) {
  case SVt_NULL: // << added by SL 1/22/2007 (\undef is a SCALAR ref)
  case SVt_IV:
  case SVt_NV:
  case SVt_PV:
  case SVt_RV:
  case SVt_PVMG:
    break;
  default:
    caml_invalid_argument ("deref: SV is not a reference to a scalar");
  }
  sv = SvRV (sv);
  /* Increment the reference count because we're creating another
   * value pointing at the referenced SV.
   */
  sv = SvREFCNT_inc (sv);
  rsvv = Val_sv (sv);
  CAMLreturn (rsvv);
}

CAMLprim value
pocaml_deref_array (value svv)
{
  CAMLparam1 (svv);
  CAMLlocal1 (ravv);
  SV *sv = Sv_val (svv);

  if (!SvROK (sv))
    caml_invalid_argument ("deref_array: SV is not a reference");
  switch (SvTYPE (SvRV (sv))) {
  case SVt_PVAV:
    break;
  default:
    caml_invalid_argument ("deref_array: SV is not a reference to an array");
  }
  sv = SvRV (sv);
  /* Increment the reference count because we're creating another
   * value pointing at the referenced AV.
   */
  sv = SvREFCNT_inc (sv);
  ravv = Val_av ((AV *) sv);
  CAMLreturn (ravv);
}

CAMLprim value
pocaml_deref_hash (value svv)
{
  CAMLparam1 (svv);
  CAMLlocal1 (rhvv);
  SV *sv = Sv_val (svv);

  if (!SvROK (sv))
    caml_invalid_argument ("deref_hash: SV is not a reference");
  switch (SvTYPE (SvRV (sv))) {
  case SVt_PVHV:
    break;
  default:
    caml_invalid_argument ("deref_hash: SV is not a reference to a hash");
  }
  sv = SvRV (sv);
  /* Increment the reference count because we're creating another
   * value pointing at the referenced HV.
   */
  sv = SvREFCNT_inc (sv);
  rhvv = Val_hv ((HV *) sv);
  CAMLreturn (rhvv);
}

CAMLprim value
pocaml_av_empty (value unit)
{
  CAMLparam1 (unit);
  AV *av = newAV ();
  CAMLreturn (Val_av (av));
}

/* We don't know in advance how long the list will be, which makes this
 * a little harder.
 */
CAMLprim value
pocaml_av_of_sv_list (value svlistv)
{
  CAMLparam1 (svlistv);
  CAMLlocal1 (svv);
  SV *sv, **svlist = 0;
  int alloc = 0, size = 0;
  AV *av;

  for (; svlistv != Val_int (0); svlistv = Field (svlistv, 1))
    {
      svv = Field (svlistv, 0);
      sv = Sv_val (svv);
      if (size >= alloc) {
	alloc = alloc == 0 ? 1 : alloc * 2;
	svlist = realloc (svlist, alloc * sizeof (SV *));
      }
      svlist[size++] = sv;
    }

  av = av_make (size, svlist);

  if (alloc > 0) free (svlist);	/* Free memory allocated to SV list. */

  CAMLreturn (Val_av (av));
}

/* XXX av_map would be faster if we also had sv_list_of_av. */

CAMLprim value
pocaml_av_push (value avv, value svv)
{
  CAMLparam2 (avv, svv);
  AV *av = Av_val (avv);
  SV *sv = Sv_val (svv);
  av_push (av, sv);
  CAMLreturn (Val_unit);
}

CAMLprim value
pocaml_av_pop (value avv)
{
  CAMLparam1 (avv);
  AV *av = Av_val (avv);
  SV *sv = av_pop (av);
  /* Increment the reference count because we're creating another
   * value pointing at the referenced AV.
   */
  sv = SvREFCNT_inc (sv);
  CAMLreturn (Val_sv (sv));
}

CAMLprim value
pocaml_av_unshift (value avv, value svv)
{
  CAMLparam2 (avv, svv);
  AV *av = Av_val (avv);
  SV *sv = Sv_val (svv);
  av_unshift (av, 1);
  SvREFCNT_inc (sv);
  if (av_store (av, 0, sv) == 0)
    SvREFCNT_dec (sv);
  CAMLreturn (Val_unit);
}

CAMLprim value
pocaml_av_shift (value avv)
{
  CAMLparam1 (avv);
  AV *av = Av_val (avv);
  SV *sv = av_shift (av);
  /* Increment the reference count because we're creating another
   * value pointing at the referenced AV.
   */
  sv = SvREFCNT_inc (sv);
  CAMLreturn (Val_sv (sv));
}

CAMLprim value
pocaml_av_length (value avv)
{
  CAMLparam1 (avv);
  AV *av = Av_val (avv);
  CAMLreturn (Val_int (av_len (av) + 1));
}

CAMLprim value
pocaml_av_set (value avv, value i, value svv)
{
  CAMLparam3 (avv, i, svv);
  AV *av = Av_val (avv);
  SV *sv = Sv_val (svv);
  SvREFCNT_inc (sv);
  if (av_store (av, Int_val (i), sv) == 0)
    SvREFCNT_dec (sv);
  CAMLreturn (Val_unit);
}

CAMLprim value
pocaml_av_get (value avv, value i)
{
  CAMLparam2 (avv, i);
  AV *av = Av_val (avv);
  SV **svp = av_fetch (av, Int_val (i), 0);
  if (svp == 0) caml_invalid_argument ("av_get: index out of bounds");
  /* Increment the reference count because we're creating another
   * value pointing at the referenced AV.
   */
  *svp = SvREFCNT_inc (*svp);
  CAMLreturn (Val_sv (*svp));
}

CAMLprim value
pocaml_av_clear (value avv)
{
  CAMLparam1 (avv);
  AV *av = Av_val (avv);
  av_clear (av);
  CAMLreturn (Val_unit);
}

CAMLprim value
pocaml_av_undef (value avv)
{
  CAMLparam1 (avv);
  AV *av = Av_val (avv);
  av_undef (av);
  CAMLreturn (Val_unit);
}

CAMLprim value
pocaml_av_extend (value avv, value i)
{
  CAMLparam2 (avv, i);
  AV *av = Av_val (avv);
  av_extend (av, Int_val (i));
  CAMLreturn (Val_unit);
}

CAMLprim value
pocaml_hv_empty (value unit)
{
  CAMLparam1 (unit);
  HV *hv = newHV ();
  CAMLreturn (Val_hv (hv));
}

CAMLprim value
pocaml_hv_set (value hvv, value key, value svv)
{
  CAMLparam3 (hvv, key, svv);
  HV *hv = Hv_val (hvv);
  SV *sv = Sv_val (svv);
  SvREFCNT_inc (sv);
  if (hv_store (hv, String_val (key), caml_string_length (key), sv, 0) == 0)
    SvREFCNT_dec (sv);
  CAMLreturn (Val_unit);
}

CAMLprim value
pocaml_hv_get (value hvv, value key)
{
  CAMLparam2 (hvv, key);
  HV *hv = Hv_val (hvv);
  SV **svp = hv_fetch (hv, String_val (key), caml_string_length (key), 0);
  if (svp == 0) caml_raise_not_found ();
  /* Increment the reference count because we're creating another
   * value pointing at the referenced SV.
   */
  SvREFCNT_inc (*svp);
  CAMLreturn (Val_sv (*svp));
}

CAMLprim value
pocaml_hv_exists (value hvv, value key)
{
  CAMLparam2 (hvv, key);
  HV *hv = Hv_val (hvv);
  bool r = hv_exists (hv, String_val (key), caml_string_length (key));
  CAMLreturn (r ? Val_true : Val_false);
}

CAMLprim value
pocaml_hv_delete (value hvv, value key)
{
  CAMLparam2 (hvv, key);
  HV *hv = Hv_val (hvv);
  hv_delete (hv, String_val (key), caml_string_length (key), G_DISCARD);
  CAMLreturn (Val_unit);
}

CAMLprim value
pocaml_hv_clear (value hvv)
{
  CAMLparam1 (hvv);
  HV *hv = Hv_val (hvv);
  hv_clear (hv);
  CAMLreturn (Val_unit);
}

CAMLprim value
pocaml_hv_undef (value hvv)
{
  CAMLparam1 (hvv);
  HV *hv = Hv_val (hvv);
  hv_undef (hv);
  CAMLreturn (Val_unit);
}

CAMLprim value
pocaml_hv_iterinit (value hvv)
{
  CAMLparam1 (hvv);
  HV *hv = Hv_val (hvv);
  int i = hv_iterinit (hv);
  CAMLreturn (caml_copy_int32 (i));
}

CAMLprim value
pocaml_hv_iternext (value hvv)
{
  CAMLparam1 (hvv);
  CAMLlocal1 (hev);
  HV *hv = Hv_val (hvv);
  HE *he = hv_iternext (hv);
  if (he == NULL) caml_raise_not_found ();
  hev = Val_he (he);
  CAMLreturn (hev);
}

CAMLprim value
pocaml_hv_iterkey (value hev)
{
  CAMLparam1 (hev);
  CAMLlocal1 (strv);
  HE *he = He_val (hev);
  I32 len;
  char *str = hv_iterkey (he, &len);
  strv = caml_alloc_string (len);
  memcpy (String_val (strv), str, len);
  CAMLreturn (strv);
}

CAMLprim value
pocaml_hv_iterval (value hvv, value hev)
{
  CAMLparam2 (hvv, hev);
  CAMLlocal1 (svv);
  HV *hv = Hv_val (hvv);
  HE *he = He_val (hev);
  SV *sv = hv_iterval (hv, he);
  SvREFCNT_inc (sv);
  svv = Val_sv (sv);
  CAMLreturn (svv);
}

CAMLprim value
pocaml_hv_iternextsv (value hvv)
{
  CAMLparam1 (hvv);
  CAMLlocal3 (strv, svv, rv);
  HV *hv = Hv_val (hvv);
  char *str; I32 len;
  SV *sv = hv_iternextsv (hv, &str, &len);
  if (sv == NULL) caml_raise_not_found ();
  SvREFCNT_inc (sv);
  svv = Val_sv (sv);
  strv = caml_alloc_string (len);
  memcpy (String_val (strv), str, len);
  /* Construct a tuple (strv, svv). */
  rv = caml_alloc_tuple (2);
  Field (rv, 0) = strv;
  Field (rv, 1) = svv;
  CAMLreturn (rv);
}

CAMLprim value
pocaml_get_sv (value optcreate, value name)
{
  CAMLparam2 (optcreate, name);
  CAMLlocal1 (create);
  SV *sv;

  create = unoption (optcreate, Val_false);
  sv = get_sv (String_val (name), create == Val_true ? TRUE : FALSE);
  if (sv == NULL) caml_raise_not_found ();

  /* Increment the reference count because we're creating another
   * value pointing at the referenced SV.
   */
  SvREFCNT_inc (sv);

  CAMLreturn (Val_sv (sv));
}

CAMLprim value
pocaml_get_av (value optcreate, value name)
{
  CAMLparam2 (optcreate, name);
  CAMLlocal1 (create);
  AV *av;

  create = unoption (optcreate, Val_false);
  av = get_av (String_val (name), create == Val_true ? TRUE : FALSE);
  if (av == NULL) caml_raise_not_found ();

  /* Increment the reference count because we're creating another
   * value pointing at the AV.
   */
  SvREFCNT_inc (av);

  CAMLreturn (Val_av (av));
}

CAMLprim value
pocaml_get_hv (value optcreate, value name)
{
  CAMLparam2 (optcreate, name);
  CAMLlocal1 (create);
  HV *hv;

  create = unoption (optcreate, Val_false);
  hv = get_hv (String_val (name), create == Val_true ? TRUE : FALSE);
  if (hv == NULL) caml_raise_not_found ();

  /* Increment the reference count because we're creating another
   * value pointing at the HV.
   */
  SvREFCNT_inc (hv);

  CAMLreturn (Val_hv (hv));
}

static inline void
check_perl_failure ()
{
  SV *errsv = get_sv ("@", TRUE);

  if (SvTRUE (errsv))		/* Equivalent of $@ in Perl. */
    {
      CAMLlocal1 (errv);
      STRLEN n_a;
      const char *err = SvPV (errsv, n_a);

      errv = caml_copy_string (err);

      caml_raise_with_arg (*caml_named_value ("pocaml_perl_failure"), errv);
    }
}

CAMLprim value
pocaml_call (value optsv, value optfnname, value arglist)
{
  CAMLparam3 (optsv, optfnname, arglist);
  dSP;
  int count;
  SV *sv;
  CAMLlocal3 (errv, svv, fnname);

  ENTER;
  SAVETMPS;

  /* Push the parameter list. */
  PUSHMARK (SP);

  /* Iteration over the linked list. */
  for (; arglist != Val_int (0); arglist = Field (arglist, 1))
    {
      svv = Field (arglist, 0);
      sv = Sv_val (svv);
      XPUSHs (sv_2mortal (newSVsv (sv)));
    }

  PUTBACK;

  if (optsv != Val_int (0))
    {
      svv = unoption (optsv, Val_false);
      sv = Sv_val (svv);
      count = call_sv (sv, G_EVAL|G_SCALAR);
    }
  else if (optfnname != Val_int (0))
    {
      fnname = unoption (optfnname, Val_false);
      count = call_pv (String_val (fnname), G_EVAL|G_SCALAR);
    }
  else
    {
      fprintf (stderr,
	       "Perl.call: must supply either 'sv' or 'fn' parameters.");
      abort ();
    }

  SPAGAIN;

  assert (count == 1); /* Pretty sure it should never be anything else. */

  /* Pop return value off the stack. Note that the return value on the
   * stack is mortal, so we need to take a copy.
   */
  sv = newSVsv (POPs);
  PUTBACK;
  FREETMPS;
  LEAVE;

  check_perl_failure ();

  svv = Val_sv (sv);
  CAMLreturn (svv);
}

CAMLprim value
pocaml_call_array (value optsv, value optfnname, value arglist)
{
  CAMLparam3 (optsv, optfnname, arglist);
  dSP;
  int i, count;
  SV *sv;
  CAMLlocal5 (errv, svv, fnname, list, cons);

  ENTER;
  SAVETMPS;

  /* Push the parameter list. */
  PUSHMARK (SP);

  /* Iteration over the linked list. */
  for (; arglist != Val_int (0); arglist = Field (arglist, 1))
    {
      svv = Field (arglist, 0);
      sv = Sv_val (svv);
      XPUSHs (sv_2mortal (newSVsv (sv)));
    }

  PUTBACK;

  if (optsv != Val_int (0))
    {
      svv = unoption (optsv, Val_false);
      sv = Sv_val (svv);
      count = call_sv (sv, G_EVAL|G_ARRAY);
    }
  else if (optfnname != Val_int (0))
    {
      fnname = unoption (optfnname, Val_false);
      count = call_pv (String_val (fnname), G_EVAL|G_ARRAY);
    }
  else
    {
      fprintf (stderr,
	       "Perl.call_array: must supply either 'sv' or 'fn' parameters.");
      abort ();
    }

  SPAGAIN;

  /* Pop all the return values off the stack into a list. Values on the
   * stack are mortal, so we must copy them.
   */
  list = Val_int (0);
  for (i = 0; i < count; ++i) {
    SV *sv;

    cons = caml_alloc (2, 0);
    Field (cons, 1) = list;
    list = cons;
    sv = newSVsv (POPs);
    Field (cons, 0) = Val_sv (sv);
  }

  /* Restore the stack. */
  PUTBACK;
  FREETMPS;
  LEAVE;

  check_perl_failure ();

  CAMLreturn (list);
}

CAMLprim value
pocaml_call_void (value optsv, value optfnname, value arglist)
{
  CAMLparam3 (optsv, optfnname, arglist);
  dSP;
  int count;
  SV *sv;
  CAMLlocal3 (errv, svv, fnname);

  ENTER;
  SAVETMPS;

  /* Push the parameter list. */
  PUSHMARK (SP);

  /* Iteration over the linked list. */
  for (; arglist != Val_int (0); arglist = Field (arglist, 1))
    {
      svv = Field (arglist, 0);
      sv = Sv_val (svv);
      XPUSHs (sv_2mortal (newSVsv (sv)));
    }

  PUTBACK;

  if (optsv != Val_int (0))
    {
      svv = unoption (optsv, Val_false);
      sv = Sv_val (svv);
      count = call_sv (sv, G_EVAL|G_VOID);
    }
  else if (optfnname != Val_int (0))
    {
      fnname = unoption (optfnname, Val_false);
      count = call_pv (String_val (fnname), G_EVAL|G_VOID|G_DISCARD);
    }
  else
    {
      fprintf (stderr,
	       "Perl.call_void: must supply either 'sv' or 'fn' parameters.");
      abort ();
    }

  SPAGAIN;

  assert (count == 0);

  /* Restore the stack. */
  PUTBACK;
  FREETMPS;
  LEAVE;

  check_perl_failure ();

  CAMLreturn (Val_unit);
}

CAMLprim value
pocaml_eval (value expr)
{
  CAMLparam1 (expr);
  dSP;
  SV *sv;
  CAMLlocal2 (errv, svv);

  sv = eval_pv (String_val (expr), G_SCALAR);

  check_perl_failure ();

  svv = Val_sv (sv);
  CAMLreturn (svv);
}

CAMLprim value
pocaml_call_method (value ref, value name, value arglist)
{
  CAMLparam3 (ref, name, arglist);
  dSP;
  int count;
  SV *sv;
  CAMLlocal2 (errv, svv);

  ENTER;
  SAVETMPS;

  /* Push the parameter list. */
  PUSHMARK (SP);

  sv = Sv_val (ref);
  XPUSHs (sv_2mortal (newSVsv (sv)));

  /* Iteration over the linked list. */
  for (; arglist != Val_int (0); arglist = Field (arglist, 1))
    {
      svv = Field (arglist, 0);
      sv = Sv_val (svv);
      XPUSHs (sv_2mortal (newSVsv (sv)));
    }

  PUTBACK;

  count = call_method (String_val (name), G_EVAL|G_SCALAR);

  SPAGAIN;

  assert (count == 1); /* Pretty sure it should never be anything else. */

  /* Pop return value off the stack. Note that the return value on the
   * stack is mortal, so we need to take a copy.
   */
  sv = newSVsv (POPs);
  PUTBACK;
  FREETMPS;
  LEAVE;

  check_perl_failure ();

  svv = Val_sv (sv);
  CAMLreturn (svv);
}

CAMLprim value
pocaml_call_method_array (value ref, value name, value arglist)
{
  CAMLparam3 (ref, name, arglist);
  dSP;
  int count, i;
  SV *sv;
  CAMLlocal4 (errv, svv, list, cons);

  ENTER;
  SAVETMPS;

  /* Push the parameter list. */
  PUSHMARK (SP);

  sv = Sv_val (ref);
  XPUSHs (sv_2mortal (newSVsv (sv)));

  /* Iteration over the linked list. */
  for (; arglist != Val_int (0); arglist = Field (arglist, 1))
    {
      svv = Field (arglist, 0);
      sv = Sv_val (svv);
      XPUSHs (sv_2mortal (newSVsv (sv)));
    }

  PUTBACK;

  count = call_method (String_val (name), G_EVAL|G_ARRAY);

  SPAGAIN;

  /* Pop all return values off the stack. Note that the return values on the
   * stack are mortal, so we need to take a copy.
   */
  list = Val_int (0);
  for (i = 0; i < count; ++i) {
    SV *sv;

    cons = caml_alloc (2, 0);
    Field (cons, 1) = list;
    list = cons;
    sv = newSVsv (POPs);
    Field (cons, 0) = Val_sv (sv);
  }

  /* Restore the stack. */
  PUTBACK;
  FREETMPS;
  LEAVE;

  check_perl_failure ();

  CAMLreturn (list);
}

CAMLprim value
pocaml_call_method_void (value ref, value name, value arglist)
{
  CAMLparam3 (ref, name, arglist);
  dSP;
  int count;
  SV *sv;
  CAMLlocal2 (errv, svv);

  ENTER;
  SAVETMPS;

  /* Push the parameter list. */
  PUSHMARK (SP);

  sv = Sv_val (ref);
  XPUSHs (sv_2mortal (newSVsv (sv)));

  /* Iteration over the linked list. */
  for (; arglist != Val_int (0); arglist = Field (arglist, 1))
    {
      svv = Field (arglist, 0);
      sv = Sv_val (svv);
      XPUSHs (sv_2mortal (newSVsv (sv)));
    }

  PUTBACK;

  count = call_method (String_val (name), G_EVAL|G_VOID|G_DISCARD);

  SPAGAIN;

  assert (count == 0);

  /* Restore the stack. */
  PUTBACK;
  FREETMPS;
  LEAVE;

  check_perl_failure ();

  CAMLreturn (Val_unit);
}

CAMLprim value
pocaml_call_class_method (value classname, value name, value arglist)
{
  CAMLparam3 (classname, name, arglist);
  dSP;
  int count;
  SV *sv;
  CAMLlocal2 (errv, svv);

  ENTER;
  SAVETMPS;

  /* Push the parameter list. */
  PUSHMARK (SP);

  XPUSHs (sv_2mortal (newSVpv (String_val (classname), 0)));

  /* Iteration over the linked list. */
  for (; arglist != Val_int (0); arglist = Field (arglist, 1))
    {
      svv = Field (arglist, 0);
      sv = Sv_val (svv);
      XPUSHs (sv_2mortal (newSVsv (sv)));
    }

  PUTBACK;

  count = call_method (String_val (name), G_EVAL|G_SCALAR);

  SPAGAIN;

  assert (count == 1); /* Pretty sure it should never be anything else. */

  /* Pop return value off the stack. Note that the return value on the
   * stack is mortal, so we need to take a copy.
   */
  sv = newSVsv (POPs);
  PUTBACK;
  FREETMPS;
  LEAVE;

  check_perl_failure ();

  svv = Val_sv (sv);
  CAMLreturn (svv);
}

CAMLprim value
pocaml_call_class_method_array (value classname, value name, value arglist)
{
  CAMLparam3 (classname, name, arglist);
  dSP;
  int count, i;
  SV *sv;
  CAMLlocal4 (errv, svv, list, cons);

  ENTER;
  SAVETMPS;

  /* Push the parameter list. */
  PUSHMARK (SP);

  XPUSHs (sv_2mortal (newSVpv (String_val (classname), 0)));

  /* Iteration over the linked list. */
  for (; arglist != Val_int (0); arglist = Field (arglist, 1))
    {
      svv = Field (arglist, 0);
      sv = Sv_val (svv);
      XPUSHs (sv_2mortal (newSVsv (sv)));
    }

  PUTBACK;

  count = call_method (String_val (name), G_EVAL|G_ARRAY);

  SPAGAIN;

  /* Pop all return values off the stack. Note that the return values on the
   * stack are mortal, so we need to take a copy.
   */
  list = Val_int (0);
  for (i = 0; i < count; ++i) {
    cons = caml_alloc (2, 0);
    Field (cons, 1) = list;
    list = cons;
    Field (cons, 0) = Val_sv (newSVsv (POPs));
  }

  /* Restore the stack. */
  PUTBACK;
  FREETMPS;
  LEAVE;

  check_perl_failure ();

  CAMLreturn (list);
}

CAMLprim value
pocaml_call_class_method_void (value classname, value name, value arglist)
{
  CAMLparam3 (classname, name, arglist);
  dSP;
  int count;
  SV *sv;
  CAMLlocal2 (errv, svv);

  ENTER;
  SAVETMPS;

  /* Push the parameter list. */
  PUSHMARK (SP);

  XPUSHs (sv_2mortal (newSVpv (String_val (classname), 0)));

  /* Iteration over the linked list. */
  for (; arglist != Val_int (0); arglist = Field (arglist, 1))
    {
      svv = Field (arglist, 0);
      sv = Sv_val (svv);
      XPUSHs (sv_2mortal (newSVsv (sv)));
    }

  PUTBACK;

  count = call_method (String_val (name), G_EVAL|G_VOID|G_DISCARD);

  SPAGAIN;

  assert (count == 0);

  /* Restore the stack. */
  PUTBACK;
  FREETMPS;
  LEAVE;

  check_perl_failure ();

  CAMLreturn (Val_unit);
}

static value
Val_voidptr (void *ptr)
{
  CAMLparam0 ();
  CAMLlocal1 (rv);
  rv = caml_alloc (1, Abstract_tag);
  Field(rv, 0) = (value) ptr;
  CAMLreturn (rv);
}

#if PERL4CAML_REFCOUNTING_EXPERIMENTAL

static void
xv_finalize (value v)
{
  /*fprintf (stderr, "about to decrement %p\n", Xv_val (v));*/
  SvREFCNT_dec ((SV *) Xv_val (v));
}

static struct custom_operations xv_custom_operations = {
  "xv_custom_operations",
  xv_finalize,
  custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};

static value
Val_xv (SV *sv)
{
  CAMLparam0 ();
  CAMLlocal1 (rv);
  rv = caml_alloc_custom (&xv_custom_operations, sizeof (void *), 0, 1);
  Xv_val (rv) = sv;
  CAMLreturn (rv);
}

#endif /* PERL4CAML_REFCOUNTING_EXPERIMENTAL */

static value
unoption (value option, value deflt)
{
  if (option == Val_int (0))	/* "None" */
    return deflt;
  else				/* "Some 'a" */
    return Field (option, 0);
}
