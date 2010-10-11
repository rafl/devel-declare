#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "hook_op_check.h"
#undef printf
#include "stolen_chunk_of_toke.c"
#include <stdio.h>
#include <string.h>

#define PERL_VERSION_DECIMAL(r,v,s) (r*1000000 + v*1000 + s)
#define PERL_DECIMAL_VERSION \
  PERL_VERSION_DECIMAL(PERL_REVISION,PERL_VERSION,PERL_SUBVERSION)
#define PERL_VERSION_GE(r,v,s) \
  (PERL_DECIMAL_VERSION >= PERL_VERSION_DECIMAL(r,v,s))

#ifndef Newx
# define Newx(v,n,t) New(0,v,n,t)
#endif /* !Newx */

#define DD_DEBUGf_UPDATED_LINESTR 1
#define DD_DEBUGf_TRACE 2

#define DD_DEBUG_UPDATED_LINESTR (dd_debug & DD_DEBUGf_UPDATED_LINESTR)
#define DD_DEBUG_TRACE (dd_debug & DD_DEBUGf_TRACE)
static int dd_debug = 0;

#define DD_CONST_VIA_RV2CV PERL_VERSION_GE(5,11,2)

#define LEX_NORMAL    10
#define LEX_INTERPNORMAL   9

/* flag to trigger removal of temporary declaree sub */

static int in_declare = 0;

/* in 5.10, PL_parser will be NULL if we aren't parsing, and PL_lex_stuff
   is a lookup into it - so if anything else we can use to tell, so we
   need to be a bit more careful if PL_parser exists */

#define DD_AM_LEXING_CHECK (PL_lex_state == LEX_NORMAL || PL_lex_state == LEX_INTERPNORMAL)

#if defined(PL_parser) || defined(PERL_5_9_PLUS)
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

  if (!HvNAME(PL_curstash))
    return -1;

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
  unsigned int new_len = strlen(new_value);

  if (SvLEN(PL_linestr) < new_len) {
    croak("PL_linestr not long enough, was Devel::Declare loaded soon enough in %s",
      CopFILE(&PL_compiling)
    );
  }


  memcpy(SvPVX(PL_linestr), new_value, new_len+1);

  SvCUR_set(PL_linestr, new_len);

  PL_bufend = SvPVX(PL_linestr) + new_len;

  if ( DD_DEBUG_UPDATED_LINESTR && PERLDB_LINE && PL_curstash != PL_debstash) {
    /* Cribbed from toke.c */
    SV * const sv = NEWSV(85,0);

    sv_upgrade(sv, SVt_PVMG);
    sv_setpvn(sv,PL_bufptr,PL_bufend-PL_bufptr);
    (void)SvIOK_on(sv);
    SvIV_set(sv, 0);
    av_store(CopFILEAV(&PL_compiling),(I32)CopLINE(&PL_compiling),sv);
  }
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

int dd_toke_scan_ident(pTHX_ int offset) {
    char tmpbuf[sizeof PL_tokenbuf];
    char* base_s = SvPVX(PL_linestr) + offset;
    char* s = scan_ident(base_s, PL_bufend, tmpbuf, sizeof tmpbuf, 0);
    return s - base_s;
}

int dd_toke_scan_str(pTHX_ int offset, int keep_delimiters, int keep_escapes) {
  STRLEN remaining = sv_len(PL_linestr) - offset;
  SV* line_copy = newSVsv(PL_linestr);
  char* base_s = SvPVX(PL_linestr) + offset;
  char* s = scan_str(base_s, keep_escapes, keep_delimiters); /* different argument order */
  if (s != base_s && sv_len(PL_lex_stuff) > remaining) {
    int ret = (s - SvPVX(PL_linestr)) + remaining;
    sv_catsv(line_copy, PL_linestr);
    dd_set_linestr(aTHX_ SvPV_nolen(line_copy));
    SvREFCNT_dec(line_copy);
    return ret;
  }
  return s - base_s;
}

int dd_toke_skipspace(pTHX_ int offset) {
  char* base_s = SvPVX(PL_linestr) + offset;
  char* s = skipspace_force(base_s);
  return s - base_s;
}

static void call_done_declare(pTHX) {
  dSP;

  if (DD_DEBUG_TRACE) {
    printf("Deconstructing declare\n");
    printf("PL_bufptr: %s\n", PL_bufptr);
    printf("bufend at: %i\n", PL_bufend - PL_bufptr);
    printf("linestr: %s\n", SvPVX(PL_linestr));
    printf("linestr len: %i\n", PL_bufend - SvPVX(PL_linestr));
  }

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);

  call_pv("Devel::Declare::done_declare", G_VOID|G_DISCARD);

  FREETMPS;
  LEAVE;

  if (DD_DEBUG_TRACE) {
    printf("PL_bufptr: %s\n", PL_bufptr);
    printf("bufend at: %i\n", PL_bufend - PL_bufptr);
    printf("linestr: %s\n", SvPVX(PL_linestr));
    printf("linestr len: %i\n", PL_bufend - SvPVX(PL_linestr));
    printf("actual len: %i\n", strlen(PL_bufptr));
  }
}

static int dd_handle_const(pTHX_ char *name);

/* replacement PL_check rv2cv entry */

STATIC OP *dd_ck_rv2cv(pTHX_ OP *o, void *user_data) {
  OP* kid;
  int dd_flags;

  PERL_UNUSED_VAR(user_data);

  if (in_declare) {
    call_done_declare(aTHX);
    return o;
  }

  kid = cUNOPo->op_first;

  if (kid->op_type != OP_GV) /* not a GV so ignore */
    return o;

  if (!DD_AM_LEXING)
    return o; /* not lexing? */

  if (DD_DEBUG_TRACE) {
    printf("Checking GV %s -> %s\n", HvNAME(GvSTASH(kGVOP_gv)), GvNAME(kGVOP_gv));
  }

  dd_flags = dd_is_declarator(aTHX_ GvNAME(kGVOP_gv));

  if (dd_flags == -1)
    return o;

  if (DD_DEBUG_TRACE) {
    printf("dd_flags are: %i\n", dd_flags);
    printf("PL_tokenbuf: %s\n", PL_tokenbuf);
  }

#if DD_CONST_VIA_RV2CV
  if (PL_expect != XOPERATOR) {
    if (!dd_handle_const(aTHX_ GvNAME(kGVOP_gv)))
      return o;
    CopLINE(PL_curcop) = PL_copline;
    /* The parser behaviour that we're simulating depends on what comes
       after the declarator. */
    if (*skipspace(PL_bufptr + strlen(GvNAME(kGVOP_gv))) != '(') {
      if (in_declare) {
        call_done_declare(aTHX);
      } else {
        dd_linestr_callback(aTHX_ "rv2cv", GvNAME(kGVOP_gv));
      }
    }
    return o;
  }
#endif /* DD_CONST_VIA_RV2CV */

  dd_linestr_callback(aTHX_ "rv2cv", GvNAME(kGVOP_gv));

  return o;
}

OP* dd_pp_entereval(pTHX) {
  dSP;
  STRLEN len;
  const char* s;
  SV *sv;
#ifdef PERL_5_9_PLUS
  SV *saved_hh;
  if (PL_op->op_private & OPpEVAL_HAS_HH) {
    saved_hh = POPs;
  }
#endif
  sv = POPs;
  if (SvPOK(sv)) {
    if (DD_DEBUG_TRACE) {
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
#ifdef PERL_5_9_PLUS
  if (PL_op->op_private & OPpEVAL_HAS_HH) {
    PUSHs(saved_hh);
  }
#endif
  return PL_ppaddr[OP_ENTEREVAL](aTHX);
}

STATIC OP *dd_ck_entereval(pTHX_ OP *o, void *user_data) {
  PERL_UNUSED_VAR(user_data);

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

static int dd_handle_const(pTHX_ char *name) {
  switch (PL_lex_inwhat) {
    case OP_QR:
    case OP_MATCH:
    case OP_SUBST:
    case OP_TRANS:
    case OP_BACKTICK:
    case OP_STRINGIFY:
      return 0;
      break;
    default:
      break;
  }

  if (strnEQ(PL_bufptr, "->", 2)) {
    return 0;
  }

  {
    char buf[256];
    STRLEN len;
    char *s = PL_bufptr;
    STRLEN old_offset = PL_bufptr - SvPVX(PL_linestr);

    s = scan_word(s, buf, sizeof buf, FALSE, &len);
    if (strnEQ(buf, name, len)) {
      char *d;
      SV *inject = newSVpvn(SvPVX(PL_linestr), PL_bufptr - SvPVX(PL_linestr));
      sv_catpvn(inject, buf, len);

      d = peekspace(s);
      sv_catpvn(inject, s, d - s);

      if ((PL_bufend - d) >= 2 && strnEQ(d, "=>", 2)) {
        return 0;
      }

      sv_catpv(inject, d);
      dd_set_linestr(aTHX_ SvPV_nolen(inject));
      PL_bufptr = SvPVX(PL_linestr) + old_offset;
      SvREFCNT_dec (inject);
    }
  }

  dd_linestr_callback(aTHX_ "const", name);

  return 1;
}

#if !DD_CONST_VIA_RV2CV

STATIC OP *dd_ck_const(pTHX_ OP *o, void *user_data) {
  int dd_flags;
  char* name;

  PERL_UNUSED_VAR(user_data);

  if (DD_HAVE_PARSER && PL_expect == XOPERATOR) {
    return o;
  }

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

  dd_handle_const(aTHX_ name);

  return o;
}

#endif /* !DD_CONST_VIA_RV2CV */

static int initialized = 0;

MODULE = Devel::Declare  PACKAGE = Devel::Declare

PROTOTYPES: DISABLE

void
setup()
  CODE:
  if (!initialized++) {
    hook_op_check(OP_RV2CV, dd_ck_rv2cv, NULL);
    hook_op_check(OP_ENTEREVAL, dd_ck_entereval, NULL);
#if !DD_CONST_VIA_RV2CV
    hook_op_check(OP_CONST, dd_ck_const, NULL);
#endif /* !DD_CONST_VIA_RV2CV */
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
toke_scan_str(int offset, ...);
    PROTOTYPE: $;%
    PREINIT:
        int keep_delimiters = 0;
        int keep_escapes = 0;
    CODE:
        if (items > 1) {
            int i;
            for (i = 1; i < items; i += 2) {
                STRLEN keylen;
                const char * key = SvPV(ST(i), keylen);

                if (strnEQ(key, "keep_delimiters", keylen)) {
                    keep_delimiters = SvTRUE(ST(i + 1));
                } else if (strnEQ(key, "keep_escapes", keylen)) {
                    keep_escapes = SvTRUE(ST(i + 1));
                } else {
                    warn("unrecognized option: %s", key);
                }
            }
        }
        RETVAL = dd_toke_scan_str(aTHX_ offset, keep_delimiters, keep_escapes);
   OUTPUT:
        RETVAL

int
toke_scan_ident(int offset)
  CODE:
    RETVAL = dd_toke_scan_ident(aTHX_ offset);
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
{
  char *endptr;
  char *debug_str = getenv ("DD_DEBUG");
  if (debug_str) {
    dd_debug = strtol (debug_str, &endptr, 10);
    if (*endptr != '\0') {
      dd_debug = 0;
    }
  }
}
