#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#undef printf
#include "stolen_chunk_of_toke.c"
#include <stdio.h>
#include <string.h>

#ifndef Newx
# define Newx(v,n,t) New(0,v,n,t)
#endif /* !Newx */

static int dd_debug = 0;

#define LEX_NORMAL    10
#define LEX_INTERPNORMAL   9

/* flag to trigger removal of temporary declaree sub */

static int in_declare = 0;

/* in 5.10, PL_parser will be NULL if we aren't parsing, and PL_lex_stuff
   is a lookup into it - so if anything else we can use to tell, so we
   need to be a bit more careful if PL_parser exists */

#define DD_AM_LEXING_CHECK (PL_lex_state == LEX_NORMAL || PL_lex_state == LEX_INTERPNORMAL)

#ifdef PL_parser
#define DD_HAVE_PARSER PL_parser
#define DD_HAVE_LEX_STUFF (PL_parser && PL_lex_stuff)
#define DD_AM_LEXING (PL_parser && DD_AM_LEXING_CHECK)
#else
#define DD_HAVE_PARSER 1
#define DD_HAVE_LEX_STUFF PL_lex_stuff
#define DD_AM_LEXING DD_AM_LEXING_CHECK
#endif

/* thing that decides whether we're dealing with a declarator */

int dd_is_declarator(pTHX_ char* name) {
  HV* is_declarator;
  SV** is_declarator_pack_ref;
  HV* is_declarator_pack_hash;
  SV** is_declarator_flag_ref;
  int dd_flags;

  is_declarator = get_hv("Devel::Declare::declarators", FALSE);

  if (!is_declarator)
    return -1;

  /* $declarators{$current_package_name} */

  is_declarator_pack_ref = hv_fetch(is_declarator, HvNAME(PL_curstash),
                             strlen(HvNAME(PL_curstash)), FALSE);

  if (!is_declarator_pack_ref || !SvROK(*is_declarator_pack_ref))
    return -1; /* not a hashref */

  is_declarator_pack_hash = (HV*) SvRV(*is_declarator_pack_ref);

  /* $declarators{$current_package_name}{$name} */

  is_declarator_flag_ref = hv_fetch(
    is_declarator_pack_hash, name,
    strlen(name), FALSE
  );

  /* requires SvIOK as well as TRUE since flags not being an int is useless */

  if (!is_declarator_flag_ref
        || !SvIOK(*is_declarator_flag_ref) 
        || !SvTRUE(*is_declarator_flag_ref))
    return -1;

  dd_flags = SvIVX(*is_declarator_flag_ref);

  return dd_flags;
}

/* callback thingy */

void dd_linestr_callback (pTHX_ char* type, char* name) {

  char* linestr = SvPVX(PL_linestr);
  int offset = PL_bufptr - linestr;

  dSP;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  XPUSHs(sv_2mortal(newSVpv(type, 0)));
  XPUSHs(sv_2mortal(newSVpv(name, 0)));
  XPUSHs(sv_2mortal(newSViv(offset)));
  PUTBACK;

  call_pv("Devel::Declare::linestr_callback", G_VOID|G_DISCARD);

  FREETMPS;
  LEAVE;
}

char* dd_get_linestr(pTHX) {
  if (!DD_HAVE_PARSER) {
    return NULL;
  }
  return SvPVX(PL_linestr);
}

void dd_set_linestr(pTHX_ char* new_value) {
  int new_len = strlen(new_value);

  if (SvLEN(PL_linestr) < new_len) {
    croak("forced to realloc PL_linestr for line %s, bailing out before we crash harder", SvPVX(PL_linestr));
  }

  SvGROW(PL_linestr, new_len);

  memcpy(SvPVX(PL_linestr), new_value, new_len+1);

  SvCUR_set(PL_linestr, new_len);

  PL_bufend = SvPVX(PL_linestr) + new_len;
}

char* dd_get_lex_stuff(pTHX) {
  return (DD_HAVE_LEX_STUFF ? SvPVX(PL_lex_stuff) : "");
}

void dd_clear_lex_stuff(pTHX) {
  if (DD_HAVE_PARSER)
    PL_lex_stuff = (SV*)NULL;
}

char* dd_get_curstash_name(pTHX) {
  return HvNAME(PL_curstash);
}

int dd_get_linestr_offset(pTHX) {
  char* linestr;
  if (!DD_HAVE_PARSER) {
    return -1;
  }
  linestr = SvPVX(PL_linestr);
  return PL_bufptr - linestr;
}

char* dd_move_past_token (pTHX_ char* s) {

  /*
   *   buffer will be at the beginning of the declarator, -unless- the
   *   declarator is at EOL in which case it'll be the next useful line
   *   so we don't short-circuit out if we don't find the declarator
   */

  while (s < PL_bufend && isSPACE(*s)) s++;
  if (memEQ(s, PL_tokenbuf, strlen(PL_tokenbuf)))
    s += strlen(PL_tokenbuf);
  return s;
}

int dd_toke_move_past_token (pTHX_ int offset) {
  char* base_s = SvPVX(PL_linestr) + offset;
  char* s = dd_move_past_token(aTHX_ base_s);
  return s - base_s;
}

int dd_toke_scan_word(pTHX_ int offset, int handle_package) {
  char tmpbuf[sizeof PL_tokenbuf];
  char* base_s = SvPVX(PL_linestr) + offset;
  STRLEN len;
  char* s = scan_word(base_s, tmpbuf, sizeof tmpbuf, handle_package, &len);
  return s - base_s;
}

int dd_toke_scan_str(pTHX_ int offset) {
  char* base_s = SvPVX(PL_linestr) + offset;
  char* s = scan_str(base_s, FALSE, FALSE);
  return s - base_s;
}

int dd_toke_skipspace(pTHX_ int offset) {
  char* base_s = SvPVX(PL_linestr) + offset;
  char* s = skipspace(base_s);
  return s - base_s;
}

/* replacement PL_check rv2cv entry */

STATIC OP *(*dd_old_ck_rv2cv)(pTHX_ OP *op);

STATIC OP *dd_ck_rv2cv(pTHX_ OP *o) {
  OP* kid;
  int dd_flags;

  o = dd_old_ck_rv2cv(aTHX_ o); /* let the original do its job */

  if (in_declare) {
    if (dd_debug) {
      printf("Deconstructing declare\n");
      printf("PL_bufptr: %s\n", PL_bufptr);
      printf("bufend at: %i\n", PL_bufend - PL_bufptr);
      printf("linestr: %s\n", SvPVX(PL_linestr));
      printf("linestr len: %i\n", PL_bufend - SvPVX(PL_linestr));
    }

    dSP;
  
    ENTER;
    SAVETMPS;
  
    PUSHMARK(SP);
  
    call_pv("Devel::Declare::done_declare", G_VOID|G_DISCARD);

    FREETMPS;
    LEAVE;

    if (dd_debug) {
      printf("PL_bufptr: %s\n", PL_bufptr);
      printf("bufend at: %i\n", PL_bufend - PL_bufptr);
      printf("linestr: %s\n", SvPVX(PL_linestr));
      printf("linestr len: %i\n", PL_bufend - SvPVX(PL_linestr));
      printf("actual len: %i\n", strlen(PL_bufptr));
    }
    return o;
  }

  kid = cUNOPo->op_first;

  if (kid->op_type != OP_GV) /* not a GV so ignore */
    return o;

  if (!DD_AM_LEXING)
    return o; /* not lexing? */

  if (dd_debug) {
    printf("Checking GV %s -> %s\n", HvNAME(GvSTASH(kGVOP_gv)), GvNAME(kGVOP_gv));
  }

  dd_flags = dd_is_declarator(aTHX_ GvNAME(kGVOP_gv));

  if (dd_flags == -1)
    return o;

  if (dd_debug) {
    printf("dd_flags are: %i\n", dd_flags);
    printf("PL_tokenbuf: %s\n", PL_tokenbuf);
  }

  dd_linestr_callback(aTHX_ "rv2cv", GvNAME(kGVOP_gv));

  return o;
}

STATIC OP *(*dd_old_ck_entereval)(pTHX_ OP *op);

OP* dd_pp_entereval(pTHX) {
  dSP;
  dPOPss;
  STRLEN len;
  const char* s;
  if (SvPOK(sv)) {
    if (dd_debug) {
      printf("mangling eval sv\n");
    }
    if (SvREADONLY(sv))
      sv = sv_2mortal(newSVsv(sv));
    s = SvPVX(sv);
    len = SvCUR(sv);
    if (!len || s[len-1] != ';') {
      if (!(SvFLAGS(sv) & SVs_TEMP))
        sv = sv_2mortal(newSVsv(sv));
      sv_catpvn(sv, "\n;", 2);
    }
    SvGROW(sv, 8192);
  }
  PUSHs(sv);
  return PL_ppaddr[OP_ENTEREVAL](aTHX);
}

STATIC OP *dd_ck_entereval(pTHX_ OP *o) {
  o = dd_old_ck_entereval(aTHX_ o); /* let the original do its job */
  if (o->op_ppaddr == PL_ppaddr[OP_ENTEREVAL])
    o->op_ppaddr = dd_pp_entereval;
  return o;
}

static I32 dd_filter_realloc(pTHX_ int idx, SV *sv, int maxlen)
{
  const I32 count = FILTER_READ(idx+1, sv, maxlen);
  SvGROW(sv, 8192); /* please try not to have a line longer than this :) */
  /* filter_del(dd_filter_realloc); */
  return count;
}

STATIC OP *(*dd_old_ck_const)(pTHX_ OP*op);

STATIC OP *dd_ck_const(pTHX_ OP *o) {
  int dd_flags;
  char* name;

  o = dd_old_ck_const(aTHX_ o); /* let the original do its job */

  /* if this is set, we just grabbed a delimited string or something,
     not a bareword, so NO TOUCHY */

  if (DD_HAVE_LEX_STUFF)
    return o;

  /* don't try and look this up if it's not a string const */
  if (!SvPOK(cSVOPo->op_sv))
    return o;

  name = SvPVX(cSVOPo->op_sv);

  dd_flags = dd_is_declarator(aTHX_ name);

  if (dd_flags == -1)
    return o;

  dd_linestr_callback(aTHX_ "const", name);

  return o;  
}

static int initialized = 0;

MODULE = Devel::Declare  PACKAGE = Devel::Declare

PROTOTYPES: DISABLE

void
setup()
  CODE:
  if (!initialized++) {
    dd_old_ck_rv2cv = PL_check[OP_RV2CV];
    PL_check[OP_RV2CV] = dd_ck_rv2cv;
    dd_old_ck_entereval = PL_check[OP_ENTEREVAL];
    PL_check[OP_ENTEREVAL] = dd_ck_entereval;
    dd_old_ck_const = PL_check[OP_CONST];
    PL_check[OP_CONST] = dd_ck_const;
  }
  filter_add(dd_filter_realloc, NULL);

char*
get_linestr()
  CODE:
    RETVAL = dd_get_linestr(aTHX);
  OUTPUT:
    RETVAL

void
set_linestr(char* new_value)
  CODE:
    dd_set_linestr(aTHX_ new_value);

char*
get_lex_stuff()
  CODE:
    RETVAL = dd_get_lex_stuff(aTHX);
  OUTPUT:
    RETVAL

void
clear_lex_stuff()
  CODE:
    dd_clear_lex_stuff(aTHX);

char*
get_curstash_name()
  CODE:
    RETVAL = dd_get_curstash_name(aTHX);
  OUTPUT:
    RETVAL

int
get_linestr_offset()
  CODE:
    RETVAL = dd_get_linestr_offset(aTHX);
  OUTPUT:
    RETVAL

int
toke_scan_word(int offset, int handle_package)
  CODE:
    RETVAL = dd_toke_scan_word(aTHX_ offset, handle_package);
  OUTPUT:
    RETVAL

int
toke_move_past_token(int offset);
  CODE:
    RETVAL = dd_toke_move_past_token(aTHX_ offset);
  OUTPUT:
    RETVAL

int
toke_scan_str(int offset);
  CODE:
    RETVAL = dd_toke_scan_str(aTHX_ offset);
  OUTPUT:
    RETVAL

int
toke_skipspace(int offset)
  CODE:
    RETVAL = dd_toke_skipspace(aTHX_ offset);
  OUTPUT:
    RETVAL

int
get_in_declare()
  CODE:
    RETVAL = in_declare;
  OUTPUT:
    RETVAL

void
set_in_declare(int value)
  CODE:
    in_declare = value;

BOOT:
  if (getenv ("DD_DEBUG")) {
    dd_debug = 1;
  }
