#define PERL_CORE
#define PERL_NO_GET_CONTEXT
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

#if 1
#define DD_HAS_TRAITS
#endif

#if 0
#define DD_DEBUG
#endif

#define DD_HANDLE_NAME 1
#define DD_HANDLE_PROTO 2
#define DD_HANDLE_PACKAGE 8

#ifdef DD_DEBUG
#define DD_DEBUG_S printf("Buffer: %s\n", s);
#else
#define DD_DEBUG_S
#endif

#define LEX_NORMAL    10
#define LEX_INTERPNORMAL   9

/* flag to trigger removal of temporary declaree sub */

static int in_declare = 0;

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

void dd_linestr_callback (pTHX_ char* type, char* name, char* s) {

  char* linestr = SvPVX(PL_linestr);
  int offset = s - linestr;

  char* new_linestr;
  int count;

  dSP;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  XPUSHs(sv_2mortal(newSVpv(type, 0)));
  XPUSHs(sv_2mortal(newSVpv(name, 0)));
  XPUSHs(sv_2mortal(newSViv(offset)));
  PUTBACK;

  count = call_pv("Devel::Declare::linestr_callback", G_SCALAR);

  SPAGAIN;

  if (count != 1)
    Perl_croak(aTHX_ "linestr_callback didn't return a value, bailing out");

  printf("linestr_callback returned: %s\n", POPp);

  PUTBACK;
  FREETMPS;
  LEAVE;
}

char* dd_get_linestr(pTHX) {
  return SvPVX(PL_linestr);
}

void dd_set_linestr(pTHX_ char* new_value) {
  int new_len = strlen(new_value);
  char* old_linestr = SvPVX(PL_linestr);

  SvGROW(PL_linestr, strlen(new_value));

  if (SvPVX(PL_linestr) != old_linestr)
    Perl_croak(aTHX_ "forced to realloc PL_linestr for line %s, bailing out before we crash harder", SvPVX(PL_linestr));

  memcpy(SvPVX(PL_linestr), new_value, new_len+1);

  SvCUR_set(PL_linestr, new_len);

  PL_bufend = SvPVX(PL_linestr) + new_len;
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
  char* s;
  char* save_s;
  char tmpbuf[sizeof PL_tokenbuf];
  char found_name[sizeof PL_tokenbuf];
  char* found_proto = NULL, *found_traits = NULL;
  STRLEN len = 0;
  int dd_flags;
  char* cb_args[6];
  dSP; /* define stack pointer for later call stuff */
  char* retstr;
  STRLEN n_a; /* for POPpx */

  o = dd_old_ck_rv2cv(aTHX_ o); /* let the original do its job */

  if (in_declare) {
    cb_args[0] = NULL;
#ifdef DD_DEBUG
    printf("Deconstructing declare\n");
    printf("PL_bufptr: %s\n", PL_bufptr);
    printf("bufend at: %i\n", PL_bufend - PL_bufptr);
    printf("linestr: %s\n", SvPVX(PL_linestr));
    printf("linestr len: %i\n", PL_bufend - SvPVX(PL_linestr));
#endif
    call_argv("Devel::Declare::done_declare", G_VOID|G_DISCARD, cb_args);
    in_declare--;
#ifdef DD_DEBUG
    printf("PL_bufptr: %s\n", PL_bufptr);
    printf("bufend at: %i\n", PL_bufend - PL_bufptr);
    printf("linestr: %s\n", SvPVX(PL_linestr));
    printf("linestr len: %i\n", PL_bufend - SvPVX(PL_linestr));
    printf("actual len: %i\n", strlen(PL_bufptr));
#endif
    return o;
  }

  kid = cUNOPo->op_first;

  if (kid->op_type != OP_GV) /* not a GV so ignore */
    return o;

  if (PL_lex_state != LEX_NORMAL && PL_lex_state != LEX_INTERPNORMAL)
    return o; /* not lexing? */

  /* I was doing this, but the CONST wrap can't so it didn't gain anything
  stash = GvSTASH(kGVOP_gv); */

#ifdef DD_DEBUG
  printf("Checking GV %s -> %s\n", HvNAME(GvSTASH(kGVOP_gv)), GvNAME(kGVOP_gv));
#endif

  dd_flags = dd_is_declarator(aTHX_ GvNAME(kGVOP_gv));

  if (dd_flags == -1)
    return o;

#ifdef DD_DEBUG
  printf("dd_flags are: %i\n", dd_flags);
#endif

  s = PL_bufptr; /* copy the current buffer pointer */

  DD_DEBUG_S

#ifdef DD_DEBUG
  printf("PL_tokenbuf: %s\n", PL_tokenbuf);
#endif

  s = dd_move_past_token(aTHX_ s);

  DD_DEBUG_S

  if (dd_flags & DD_HANDLE_NAME) {

    /* find next word */

    s = skipspace(s);

    DD_DEBUG_S

    /* kill the :: added in the ck_const */
    if (*s == ':')
      *s++ = ' ';
    if (*s == ':')
      *s++ = ' ';

    /* arg 4 is allow_package */

    s = scan_word(s, tmpbuf, sizeof tmpbuf, dd_flags & DD_HANDLE_PACKAGE, &len);

    DD_DEBUG_S

    if (len) {
      strcpy(found_name, tmpbuf);
#ifdef DD_DEBUG
      printf("Found %s\n", found_name);
#endif
    }
  }

  if (dd_flags & DD_HANDLE_PROTO) {

    s = skipspace(s);

    if (*s == '(') { /* found a prototype-ish thing */
      save_s = s;
      s = scan_str(s, FALSE, FALSE); /* no keep_quoted, no keep_delims */
#ifdef DD_HAS_TRAITS
      {
          char *traitstart = s = skipspace(s);

          while (*s && *s != '{') ++s;
          if (*s) {
              int tlen = s - traitstart;
              Newx(found_traits, tlen+1, char);
              Copy(traitstart, found_traits, tlen, char);
              found_traits[tlen] = 0;
#ifdef DD_DEBUG
              printf("found traits..... (%s)\n", found_traits);
#endif
          }
      }
#endif
      
      if (SvPOK(PL_lex_stuff)) {
#ifdef DD_DEBUG
        printf("Found proto %s\n", SvPVX(PL_lex_stuff));
#endif
        found_proto = SvPVX(PL_lex_stuff);
        if (len) /* foo name () => foo name  X, only foo parsed so works */
          *save_s++ = ' ';
        else /* foo () => foo =X, TOKEN('&') won't handle foo X */
          *save_s++ = '=';
        *save_s++ = 'X';
        while (save_s < s) {
          *save_s++ = ' ';
        }
#ifdef DD_DEBUG
        printf("Curbuf %s\n", PL_bufptr);
#endif
      }
    }
  }

  if (!len)
    found_name[0] = 0;

#ifdef DD_DEBUG
  printf("Calling init_declare\n");
#endif
  cb_args[0] = HvNAME(PL_curstash);
  cb_args[1] = GvNAME(kGVOP_gv);
  cb_args[2] = HvNAME(PL_curstash);
  cb_args[3] = found_name;
  cb_args[4] = found_proto;
  cb_args[5] = found_traits;
  cb_args[6] = NULL;

  if (len && found_proto)
    in_declare = 2;
  else if (len || found_proto)
    in_declare = 1;
  if (found_proto)
    PL_lex_stuff = Nullsv;
  s = skipspace(s);
#ifdef DD_DEBUG
  printf("cur buf: %s\n", s);
  printf("bufend at: %i\n", PL_bufend - s);
  printf("linestr: %s\n", SvPVX(PL_linestr));
  printf("linestr len: %i\n", PL_bufend - SvPVX(PL_linestr));
#endif
  
  if (*s++ == '{') {
    call_argv("Devel::Declare::init_declare", G_SCALAR, cb_args);
    SPAGAIN;
    retstr = POPpx;
    PUTBACK;
    if (retstr && strlen(retstr)) {
      const char* old_start = SvPVX(PL_linestr);
      int start_diff;
      const int old_len = SvCUR(PL_linestr);
#ifdef DD_DEBUG
      printf("Got string %s\n", retstr);
#endif
      SvGROW(PL_linestr, (STRLEN)(old_len + strlen(retstr)));
      if (start_diff = SvPVX(PL_linestr) - old_start) {
        Perl_croak(aTHX_ "forced to realloc PL_linestr for line %s, bailing out before we crash harder", SvPVX(PL_linestr));
      }
      memmove(s+strlen(retstr), s, (PL_bufend - s)+1);
      memmove(s, retstr, strlen(retstr));
      SvCUR_set(PL_linestr, old_len + strlen(retstr));
      PL_bufend += strlen(retstr);
#ifdef DD_DEBUG
  printf("cur buf: %s\n", s);
  printf("PL_bufptr: %s\n", PL_bufptr);
  printf("bufend at: %i\n", PL_bufend - s);
  printf("linestr: %s\n", SvPVX(PL_linestr));
  printf("linestr len: %i\n", PL_bufend - SvPVX(PL_linestr));
  printf("tokenbuf now: %s\n", PL_tokenbuf);
#endif
    }
  } else {
    call_argv("Devel::Declare::init_declare", G_VOID|G_DISCARD, cb_args);
  }
  return o;
}

STATIC OP *(*dd_old_ck_entereval)(pTHX_ OP *op);

OP* dd_pp_entereval(pTHX) {
  dSP;
  dPOPss;
  STRLEN len;
  const char* s;
  if (SvPOK(sv)) {
#ifdef DD_DEBUG
    printf("mangling eval sv\n");
#endif
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
  char* s;
  char tmpbuf[sizeof PL_tokenbuf];
  char found_name[sizeof PL_tokenbuf];
  STRLEN len = 0;

  o = dd_old_ck_const(aTHX_ o); /* let the original do its job */

  /* don't try and look this up if it's not a string const */
  if (!SvPOK(cSVOPo->op_sv))
    return o;

  dd_flags = dd_is_declarator(aTHX_ SvPVX(cSVOPo->op_sv));

  if (dd_flags == -1)
    return o;

  if (!(dd_flags & DD_HANDLE_NAME))
    return o; /* if we're not handling name, method intuiting not an issue */

#ifdef DD_DEBUG
  printf("Think I found a declarator %s\n", PL_tokenbuf);
  printf("linestr: %s\n", SvPVX(PL_linestr));
#endif

  s = PL_bufptr;

  s = dd_move_past_token(aTHX_ s);

  /* dd_linestr_callback(aTHX_ "const", SvPVX(cSVOPo->op_sv), s); */

  DD_DEBUG_S

  /* find next word */

  s = skipspace(s);

  DD_DEBUG_S

  /* arg 4 is allow_package */

  s = scan_word(s, tmpbuf, sizeof tmpbuf, dd_flags & DD_HANDLE_PACKAGE, &len);

  DD_DEBUG_S

  if (len) {
    const char* old_start = SvPVX(PL_linestr);
    int start_diff;
    const int old_len = SvCUR(PL_linestr);

    strcpy(found_name, tmpbuf);
#ifdef DD_DEBUG
    printf("Found %s\n", found_name);
#endif

    s -= len;
    SvGROW(PL_linestr, (STRLEN)(old_len + 2));
    if (start_diff = SvPVX(PL_linestr) - old_start) {
      Perl_croak(aTHX_ "forced to realloc PL_linestr for line %s, bailing out before we crash harder", SvPVX(PL_linestr));
    }
    memmove(s+2, s, (PL_bufend - s)+1);
    *s = ':';
    s++;
    *s = ':';
    SvCUR_set(PL_linestr, old_len + 2);
    PL_bufend += 2;
  }
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

int
toke_scan_word(int offset, int handle_package)
  CODE:
    RETVAL = dd_toke_scan_word(aTHX_ offset, handle_package);
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
