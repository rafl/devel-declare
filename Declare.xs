#define PERL_CORE
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#undef printf
#include "stolen_chunk_of_toke.c"
#include <stdio.h>
#include <string.h>

#define DD_HAS_TRAITS
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

/* placeholders for PL_check entries we wrap */

STATIC OP *(*dd_old_ck_rv2cv)(pTHX_ OP *op);
STATIC OP *(*dd_old_ck_lineseq)(pTHX_ OP *op);

/* flag to trigger removal of temporary declaree sub */

static int in_declare = 0;

/* replacement PL_check rv2cv entry */

STATIC OP *dd_ck_rv2cv(pTHX_ OP *o) {
  OP* kid;
  char* s;
  char* save_s;
  char tmpbuf[sizeof PL_tokenbuf];
  char found_name[sizeof PL_tokenbuf];
  char* found_proto = NULL, *found_traits = NULL;
  STRLEN len = 0;
  HV *stash;
  HV* is_declarator;
  SV** is_declarator_pack_ref;
  HV* is_declarator_pack_hash;
  SV** is_declarator_flag_ref;
  int dd_flags;
  char* cb_args[6];
  dSP; /* define stack pointer for later call stuff */
  char* retstr;
  STRLEN n_a; /* for POPpx */

  o = dd_old_ck_rv2cv(aTHX_ o); /* let the original do its job */

  if (in_declare) {
    cb_args[0] = NULL;
    call_argv("Devel::Declare::done_declare", G_VOID|G_DISCARD, cb_args);
    in_declare--;
    return o;
  }

  kid = cUNOPo->op_first;

  if (kid->op_type != OP_GV) /* not a GV so ignore */
    return o;

  if (PL_lex_state != LEX_NORMAL && PL_lex_state != LEX_INTERPNORMAL)
    return o; /* not lexing? */

  stash = GvSTASH(kGVOP_gv);

#ifdef DD_DEBUG
  printf("Checking GV %s -> %s\n", HvNAME(stash), GvNAME(kGVOP_gv));
#endif

  is_declarator = get_hv("Devel::Declare::declarators", FALSE);

  if (!is_declarator)
    return o;

  is_declarator_pack_ref = hv_fetch(is_declarator, HvNAME(stash),
                             strlen(HvNAME(stash)), FALSE);

  if (!is_declarator_pack_ref || !SvROK(*is_declarator_pack_ref))
    return o; /* not a hashref */

  is_declarator_pack_hash = (HV*) SvRV(*is_declarator_pack_ref);

  is_declarator_flag_ref = hv_fetch(is_declarator_pack_hash, GvNAME(kGVOP_gv),
                                strlen(GvNAME(kGVOP_gv)), FALSE);

  /* requires SvIOK as well as TRUE since flags not being an int is useless */

  if (!is_declarator_flag_ref
        || !SvIOK(*is_declarator_flag_ref) 
        || !SvTRUE(*is_declarator_flag_ref))
    return o;

  dd_flags = SvIVX(*is_declarator_flag_ref);

#ifdef DD_DEBUG
  printf("dd_flags are: %i\n", dd_flags);
#endif

  s = PL_bufptr; /* copy the current buffer pointer */

  DD_DEBUG_S

#ifdef DD_DEBUG
  printf("PL_tokenbuf: %s\n", PL_tokenbuf);
#endif

  /*
   *   buffer will be at the beginning of the declarator, -unless- the
   *   declarator is at EOL in which case it'll be the next useful line
   *   so we don't short-circuit out if we don't find the declarator
   */

  while (s < PL_bufend && isSPACE(*s)) s++;
  if (memEQ(s, PL_tokenbuf, strlen(PL_tokenbuf)))
    s += strlen(PL_tokenbuf);

  DD_DEBUG_S

  if (dd_flags & DD_HANDLE_NAME) {

    /* find next word */

    s = skipspace(s);

    DD_DEBUG_S

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
  cb_args[0] = HvNAME(stash);
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
      const int old_len = SvCUR(PL_linestr);
#ifdef DD_DEBUG
      printf("Got string %s\n", retstr);
      printf("retstr len: %d, old_len %d\n", strlen(retstr), old_len);
#endif
      SvGROW(PL_linestr, (STRLEN)(old_len + strlen(retstr)));
      memmove(s+strlen(retstr), s, (PL_bufend - s)+1);
      memmove(s, retstr, strlen(retstr));
      SvCUR_set(PL_linestr, old_len + strlen(retstr));
      PL_bufend += strlen(retstr);
#ifdef DD_DEBUG
  printf("cur buf: %s\n", s);
  printf("bufend at: %i\n", PL_bufend - s);
  printf("linestr: %s\n", SvPVX(PL_linestr));
  printf("linestr len: %i\n", PL_bufend - SvPVX(PL_linestr));
#endif
    }
  } else {
    call_argv("Devel::Declare::init_declare", G_VOID|G_DISCARD, cb_args);
  }
  return o;
}

STATIC OP *dd_ck_lineseq(pTHX_ OP *o) {
  AV* pad_inject_list;
  SV** to_inject_ref;
  int i, pad_inject_list_last;

  o = dd_old_ck_lineseq(aTHX_ o);

  pad_inject_list = get_av("Devel::Declare::next_pad_inject", FALSE);
  if (!pad_inject_list)
    return o;

  pad_inject_list_last = av_len(pad_inject_list);

  if (pad_inject_list_last == -1)
    return o;

  for (i = 0; i <= pad_inject_list_last; i++) {
    to_inject_ref = av_fetch(pad_inject_list, i, FALSE);
    if (to_inject_ref && SvPOK(*to_inject_ref)) {
#ifdef DD_DEBUG
  printf("Injecting %s into pad\n", SvPVX(*to_inject_ref));
#endif
      allocmy(SvPVX(*to_inject_ref));
    }
  }

  av_clear(pad_inject_list);

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
    dd_old_ck_lineseq = PL_check[OP_LINESEQ];
    PL_check[OP_LINESEQ] = dd_ck_lineseq;
  }

void
teardown()
  CODE:
  /* ensure we only uninit when number of teardown calls matches 
     number of setup calls */
  if (initialized && !--initialized) {
    PL_check[OP_RV2CV] = dd_old_ck_rv2cv;
  }
