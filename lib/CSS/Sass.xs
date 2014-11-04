// Copyright © 2013 David Caldwell.
// Copyright © 2014 Marcel Greter.
//
// This library is free software; you can redistribute it and/or modify
// it under the same terms as Perl itself, either Perl version 5.12.4 or,
// at your option, any later version of Perl 5 you may have available.

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <stdbool.h>
#include <stdarg.h>
#include <stdio.h>

#include "ppport.h"

#include "sass_interface.h"

#define Constant(c) newCONSTSUB(stash, #c, newSViv(c))

#undef free

char *safe_svpv(SV *sv, char *_default)
{
    size_t length;
    char *str = SvPV(sv, length);
    if (memchr(str, 0, length+1)) // NULL Terminated?
        return str;
    return _default;
}

union Sass_Value make_sass_error_f(char *format,...)
{
    va_list ap;
    va_start(ap, format);
    char msg[100];
    vsnprintf(msg, sizeof(msg), format, ap);
    va_end(ap);
    union Sass_Value err = make_sass_error(msg ? msg : format);
    return err;
}

// determine the type first with the actual data sctructure
// check some special types with if (sv_isobject(sv) && sv_derived_from(sv, class)) { ... }

// convert from perl to libsass
union Sass_Value sv_to_sass_value(SV *sv)
{

    // remember me
    SV *org = sv;

    // dereference if possible
    if (SvROK(sv)) sv = SvRV(sv);

    // have a scalar value
    if (SvTYPE(sv) < SVt_PVAV) {

        // if scalar is undef we return a null type
        if (!SvOK(sv)) return make_sass_null();

        // perl double
        else if (SvNOK(sv)) { // i.e. 4.2
            // perl doesn't know numbers with units
            return make_sass_number(SvNV(sv), "");
        }
        // perl integer
        else if (SvIOK(sv)) { // i.e. 42
            // perl doesn't know numbers with units
            return make_sass_number(SvIV(sv), "");
        }
        // perl string
        else if (SvPOK(sv)) { // i.e. "foobar"
            // coerce all other scalars into a string
            // IMO there should only be strings left!?
            return make_sass_string(SvPV_nolen(sv));
        }

        // perl reference
        else if (SvROK(sv)) {

            // dereference
            sv = SvRV(sv);

            // check out scalar value
            if (SvTYPE(sv) < SVt_PVAV) {
                // if scalar is undef we return a null type
                if (!SvOK(sv)) return make_sass_null();
                // perl reference
                if (SvROK(sv)) {
                    if (SvTYPE(SvRV(sv)) == SVt_PVAV) {
                        return make_sass_error(SvPV_nolen(*av_fetch((AV*)SvRV(sv), 0, false)));
                    }
                // if we have a scalar
                } else if (!SvROK(sv)) {
                    // then it is a boolean type
                    return make_sass_boolean(SvTRUE(sv));
                }
            }
            // an array means we have a number
            else if (SvTYPE(sv) == SVt_PVAV) {
                AV* number = (AV*) sv;
                size_t len = av_len(number);
                if (len >= 0) {
                  SV* num = *av_fetch(number, 0, false);
                  if (SvIOK(num) || SvNOK(num)) {
                    double val = SvNV(num);
                    char* unit = len > 0 ? SvPV_nolen(*av_fetch(number, 1, false)) : "";
                    return make_sass_number(val, unit);
                  }
                }
            }
            // a hash means we have a color
            else if (SvTYPE(sv) == SVt_PVHV) {
                HV* color = (HV*) sv;
                double r = SvNV(*hv_fetchs(color, "r", false));
                double g = SvNV(*hv_fetchs(color, "g", false));
                double b = SvNV(*hv_fetchs(color, "b", false));
                double a = SvNV(*hv_fetchs(color, "a", false));
                return make_sass_color(r, g, b, a);
            }

        }
        // EO SvROK

    }
    else if (SvTYPE(sv) == SVt_PVAV) {
        AV* av = (AV*) sv;
        enum Sass_Separator sepa = SASS_COMMA;
        // special check for space separated lists
        if (sv_derived_from(org, "CSS::Sass::Type::List::Space")) sepa = SASS_SPACE;
        union Sass_Value list = make_sass_list(1 + av_len(av), sepa);
        int i;
        for (i = 0; i < list.list.length; i++)
            list.list.values[i] = sv_to_sass_value(*av_fetch(av, i, false));
        return list;
    }
    // perl hash reference
    else if (SvTYPE(sv) == SVt_PVHV) {
        HV* hv = (HV*) sv;
        union Sass_Value map = make_sass_map(HvUSEDKEYS(hv));
        HE *key;
        int i = 0;
        hv_iterinit(hv);
        while (NULL != (key = hv_iternext(hv))) {
            map.map.pairs[i].key = sv_to_sass_value(HeSVKEY_force(key));
            map.map.pairs[i].value = sv_to_sass_value(HeVAL(key));
            i++;
        }
        return map;
    }

    // if scalar is undef we return a null type
    if (!SvOK(sv)) return make_sass_null();

    // stringify anything else
    // can be usefull for soft-refs
    return make_sass_string(SvPV_nolen(sv));
    // return make_sass_error_f("could not convert value");

}

SV* new_sv_sass_null () {
    SV* sv = newRV_noinc(newRV_noinc(newSV(0)));
    sv_bless(sv, gv_stashpv("CSS::Sass::Type::Null", GV_ADD));
    return sv;
}

SV* new_sv_sass_string (SV* string) {
    SV* sv = newRV_noinc(string);
    sv_bless(sv, gv_stashpv("CSS::Sass::Type::String", GV_ADD));
    return sv;
}

SV* new_sv_sass_boolean (SV* boolean) {
    SV* sv = newRV_noinc(newRV_noinc(boolean));
    sv_bless(sv, gv_stashpv("CSS::Sass::Type::Boolean", GV_ADD));
    return sv;
}

SV* new_sv_sass_number (SV* number, SV* unit) {
    AV* array = newAV();
    av_push(array, number);
    av_push(array, unit);
    SV* sv = newRV_noinc(newRV_noinc((SV*) array));
    sv_bless(sv, gv_stashpv("CSS::Sass::Type::Number", GV_ADD));
    return sv;
}

SV* new_sv_sass_color (SV* r, SV* g, SV* b, SV* a) {
    HV* hash = newHV();
    hv_store(hash, "r", 1, r, 0);
    hv_store(hash, "g", 1, g, 0);
    hv_store(hash, "b", 1, b, 0);
    hv_store(hash, "a", 1, a, 0);
    SV* sv = newRV_noinc(newRV_noinc((SV*) hash));
    sv_bless(sv, gv_stashpv("CSS::Sass::Type::Color", GV_ADD));
    return sv;
}

SV* new_sv_sass_error (SV* msg) {
    AV* error = newAV();
    av_push(error, msg);
    SV* sv = newRV_noinc(newRV_noinc(newRV_noinc((SV*) error)));
    sv_bless(sv, gv_stashpv("CSS::Sass::Type::Error", GV_ADD));
    return sv;
}

// convert from libsass to perl
SV *sass_value_to_sv(union Sass_Value val)
{
    SV* sv;
    switch(val.unknown.tag) {
        case SASS_NULL: {
            sv = new_sv_sass_null();
        }   break;
        case SASS_BOOLEAN: {
            sv = new_sv_sass_boolean(
                     newSViv(val.boolean.value)
                 );
        }   break;
        case SASS_NUMBER: {
            sv = new_sv_sass_number(
                     newSVnv(val.number.value),
                     newSVpv(val.number.unit, 0)
                 );
        }   break;
        case SASS_COLOR: {
            sv = new_sv_sass_color(
                     newSVnv(val.color.r),
                     newSVnv(val.color.g),
                     newSVnv(val.color.b),
                     newSVnv(val.color.a)
                 );
        }   break;
        case SASS_STRING: {
            sv = new_sv_sass_string(
                     newSVpv(val.string.value, 0)
                 );
        }   break;
        case SASS_LIST: {
            int i;
            AV* list = newAV();
            sv = newRV_noinc((SV*) list);
            if (val.list.separator == SASS_SPACE) {
                sv_bless(sv, gv_stashpv("CSS::Sass::Type::List::Space", GV_ADD));
            } else {
                sv_bless(sv, gv_stashpv("CSS::Sass::Type::List::Comma", GV_ADD));
            }
            for (i=0; i<val.list.length; i++)
                av_push(list, sass_value_to_sv(val.list.values[i]));
        }   break;
        case SASS_MAP: {
            int i;
            HV* map = newHV();
            sv = newRV_noinc((SV*) map);
            sv_bless(sv, gv_stashpv("CSS::Sass::Type::Map", GV_ADD));
            for (i=0; i<val.map.length; i++) {
                // this should return a scalar sv
                SV* sv_key = sass_value_to_sv(val.map.pairs[i].key);
                // call us recursive if needed to get sass values
                SV* sv_value = sass_value_to_sv(val.map.pairs[i].value);
                // store the key/value pair on the hash
                hv_store_ent(map, sv_key, sv_value, 0);
                // make key sv mortal
                sv_2mortal(sv_key);
            }
        }   break;
        case SASS_ERROR: {
            sv = new_sv_sass_error(
                newSVpv(val.error.message, 0)
            );
        }   break;
        default:
            sv = new_sv_sass_string(
                newSVpv("BUG: Sass_Value type is unknown", 0)
            );
            break;
    }

    return sv;
}

// we are called by libsass to dispatch to registered functions
union Sass_Value call_sass_function(const union Sass_Value s_args, void *cookie)
{

    dSP;
    // value from perl function
    SV *perl_value = NULL;
    // value to return to libsass
    union Sass_Value sass_value;
    int i;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    for (i=0; i<s_args.list.length; i++) {
        // get the Sass_Value from libsass
        union Sass_Value arg = s_args.list.values[i];
        // convert and add argument for perl
        XPUSHs(sv_2mortal(sass_value_to_sv(arg)));
    }
    PUTBACK;

    // free input values
    free_sass_value(s_args);

    // call the static function by soft name reference
    // force array context since we want to check for errors
    // in scalar context it would take the last value from list
    // also enable eval context to catch any major problems
    int count = call_sv(cookie, G_EVAL | G_ARRAY);

    SPAGAIN;
    if (!SvTRUE(ERRSV)) {
        if (count == 0)
            perl_value = &PL_sv_undef;
        else if (count == 1)
            perl_value = POPs;
    }

    if (SvTRUE(ERRSV)) {
        // perl function died or had some other major problem
        sass_value = make_sass_error_f("%s:%d %s: Perl sub died with message: %s!\n", __FILE__, __LINE__, __func__, SvPV_nolen(ERRSV));
    } else if (count > 1) {
        // perl function returned a list of values (undefined behaviour)
        sass_value = make_sass_error_f("%s:%d %s: Perl sub must not return a list of values!\n", __FILE__, __LINE__, __func__);
    } else {
        // convert returned sv to Sass_Value
        sass_value = sv_to_sass_value(perl_value);
    }

    PUTBACK;
    FREETMPS;
    LEAVE;

    // union Sass_Value
    return sass_value;

}


MODULE = CSS::Sass		PACKAGE = CSS::Sass

BOOT:
{
    HV *stash = gv_stashpv("CSS::Sass", 0);

    Constant(SASS_STYLE_NESTED);
    //Constant(stash, SASS_STYLE_EXPANDED); // not implemented in libsass yet
    //Constant(stash, SASS_STYLE_COMPACT);  // not implemented in libsass yet
    Constant(SASS_STYLE_COMPRESSED);

    Constant(SASS_BOOLEAN);
    Constant(SASS_NUMBER);
    Constant(SASS_COLOR);
    Constant(SASS_STRING);
    Constant(SASS_LIST);
    Constant(SASS_MAP);
    Constant(SASS_NULL);
    Constant(SASS_ERROR);

    // sass list types
    Constant(SASS_COMMA);
    Constant(SASS_SPACE);

    // sass2scss constants
    Constant(SASS2SCSS_PRETTIFY_0);
    Constant(SASS2SCSS_PRETTIFY_1);
    Constant(SASS2SCSS_PRETTIFY_2);
    Constant(SASS2SCSS_PRETTIFY_3);
    // more options for sass2scss
    Constant(SASS2SCSS_KEEP_COMMENT);
    Constant(SASS2SCSS_STRIP_COMMENT);
    Constant(SASS2SCSS_CONVERT_COMMENT);
}


HV*
compile_sass(input_string, options)
             char *input_string
             HV *options
    CODE:
        RETVAL = newHV();
        sv_2mortal((SV*)RETVAL);
    {
        struct sass_context *ctx = sass_new_context();
        char error[100] = "";
        ctx->source_string = input_string;

        SV **input_path_sv      = hv_fetchs(options, "input_path",      false);
        if (input_path_sv)
            ctx->input_path = safe_svpv(*input_path_sv, "");

        SV **output_path_sv           = hv_fetchs(options, "output_path",          false);
        SV **output_style_sv          = hv_fetchs(options, "output_style",         false);
        SV **source_comments_sv       = hv_fetchs(options, "source_comments",      false);
        SV **omit_source_map_sv       = hv_fetchs(options, "omit_source_map",      false);
        SV **omit_source_map_url_sv   = hv_fetchs(options, "omit_source_map_url",  false);
        SV **source_map_contents_sv   = hv_fetchs(options, "source_map_contents",  false);
        SV **source_map_embed_sv      = hv_fetchs(options, "source_map_embed",     false);
        SV **include_paths_sv         = hv_fetchs(options, "include_paths",        false);
        SV **precision_sv             = hv_fetchs(options, "precision",            false);
        SV **image_path_sv            = hv_fetchs(options, "image_path",           false);
        SV **source_map_file_sv       = hv_fetchs(options, "source_map_file",      false);
        SV **sass_functions_sv        = hv_fetchs(options, "sass_functions",       false);
        if (output_path_sv)
            ctx->output_path = safe_svpv(*output_path_sv, "");
        if (output_style_sv)
            ctx->options.output_style = SvUV(*output_style_sv);
        if (source_comments_sv)
            ctx->options.source_comments = SvTRUE(*source_comments_sv);
        if (omit_source_map_sv)
            ctx->options.omit_source_map_url = SvTRUE(*omit_source_map_sv);
        if (omit_source_map_url_sv)
            ctx->options.omit_source_map_url = SvTRUE(*omit_source_map_url_sv);
        if (source_map_contents_sv)
            ctx->options.source_map_contents = SvTRUE(*source_map_contents_sv);
        if (source_map_embed_sv)
            ctx->options.source_map_embed = SvTRUE(*source_map_embed_sv);
        if (include_paths_sv)
            ctx->options.include_paths = safe_svpv(*include_paths_sv, "");
        if (precision_sv)
            ctx->options.precision = SvUV(*precision_sv);
        if (image_path_sv)
            ctx->options.image_path = safe_svpv(*image_path_sv, "");
        if (source_map_file_sv)
            ctx->options.source_map_file = safe_svpv(*source_map_file_sv, "");
        if (sass_functions_sv) {
            int i;
            AV* sass_functions_av;
            if (!SvROK(*sass_functions_sv) || SvTYPE(SvRV(*sass_functions_sv)) != SVt_PVAV) {
                snprintf(error, sizeof(error), "sass_functions should be an arrayref (SvTYPE=%u)", (unsigned)SvTYPE(SvRV(*sass_functions_sv)));
                goto fail;
            }
            sass_functions_av = (AV*)SvRV(*sass_functions_sv);

            ctx->c_functions = calloc(sizeof(struct Sass_C_Function_Descriptor), av_len(sass_functions_av) + 1/*av_len() is $#av*/ + 1/*null terminated array*/);
            if (!ctx->c_functions) {
                snprintf(error, sizeof(error), "couldn't alloc memory for c_functions");
                goto fail;
            }
            for (i=0; i<=av_len(sass_functions_av); i++) {
                SV** entry_sv = av_fetch(sass_functions_av, i, false);
                AV* entry_av;
                if (!SvROK(*entry_sv) || SvTYPE(SvRV(*entry_sv)) != SVt_PVAV) {
                    snprintf(error, sizeof(error), "each sass_function entry should be an arrayref (SvTYPE=%u)", (unsigned)SvTYPE(SvRV(*entry_sv)));
                    goto fail;
                }
                entry_av = (AV*)SvRV(*entry_sv);

                SV **sig_sv = av_fetch(entry_av, 0, false);
                SV **sub_sv = av_fetch(entry_av, 1, false);

                ctx->c_functions[i].signature = safe_svpv(*sig_sv, "");
                ctx->c_functions[i].function = call_sass_function;
                ctx->c_functions[i].cookie = *sub_sv;
            }
        }

        sass_compile(ctx); // Always returns zero. What's the point??

      fail:
        hv_stores(RETVAL, "error_status", newSViv(ctx->error_status || !!*error));
        hv_stores(RETVAL, "output_string", ctx->output_string ? newSVpv(ctx->output_string, 0) : newSV(0));
        hv_stores(RETVAL, "source_map_string", ctx->source_map_string ? newSVpv(ctx->source_map_string, 0) : newSV(0));
        hv_stores(RETVAL, "error_message", *error             ? newSVpv(error, 0)              :
                                              ctx->error_message ? newSVpv(ctx->error_message, 0) : newSV(0));

        sass_free_context(ctx);
    }
    OUTPUT:
             RETVAL


HV*
compile_sass_file(input_path, options)
             char *input_path
             HV *options
    CODE:
        RETVAL = newHV();
        sv_2mortal((SV*)RETVAL);
    {
        struct sass_file_context *ctx = sass_new_file_context();
        char error[100] = "";
        ctx->input_path = input_path;

        SV **output_path_sv           = hv_fetchs(options, "output_path",          false);
        SV **output_style_sv          = hv_fetchs(options, "output_style",         false);
        SV **source_comments_sv       = hv_fetchs(options, "source_comments",      false);
        SV **omit_source_map_sv       = hv_fetchs(options, "omit_source_map",      false);
        SV **omit_source_map_url_sv   = hv_fetchs(options, "omit_source_map_url",  false);
        SV **source_map_contents_sv   = hv_fetchs(options, "source_map_contents",  false);
        SV **source_map_embed_sv      = hv_fetchs(options, "source_map_embed",     false);
        SV **include_paths_sv         = hv_fetchs(options, "include_paths",        false);
        SV **precision_sv             = hv_fetchs(options, "precision",            false);
        SV **image_path_sv            = hv_fetchs(options, "image_path",           false);
        SV **source_map_file_sv       = hv_fetchs(options, "source_map_file",      false);
        SV **sass_functions_sv        = hv_fetchs(options, "sass_functions",       false);
        if (output_path_sv)
            ctx->output_path = safe_svpv(*output_path_sv, "");
        if (output_style_sv)
            ctx->options.output_style = SvUV(*output_style_sv);
        if (source_comments_sv)
            ctx->options.source_comments = SvTRUE(*source_comments_sv);
        if (omit_source_map_sv)
            ctx->options.omit_source_map_url = SvTRUE(*omit_source_map_sv);
        if (omit_source_map_url_sv)
            ctx->options.omit_source_map_url = SvTRUE(*omit_source_map_url_sv);
        if (source_map_contents_sv)
            ctx->options.source_map_contents = SvTRUE(*source_map_contents_sv);
        if (source_map_embed_sv)
            ctx->options.source_map_embed = SvTRUE(*source_map_embed_sv);
        if (include_paths_sv)
            ctx->options.include_paths = safe_svpv(*include_paths_sv, "");
        if (precision_sv)
            ctx->options.precision = SvUV(*precision_sv);
        if (image_path_sv)
            ctx->options.image_path = safe_svpv(*image_path_sv, "");
        if (source_map_file_sv)
            ctx->options.source_map_file = safe_svpv(*source_map_file_sv, "");
        if (sass_functions_sv) {
            int i;
            AV* sass_functions_av;
            if (!SvROK(*sass_functions_sv) || SvTYPE(SvRV(*sass_functions_sv)) != SVt_PVAV) {
                snprintf(error, sizeof(error), "sass_functions should be an arrayref (SvTYPE=%u)", (unsigned)SvTYPE(SvRV(*sass_functions_sv)));
                goto fail;
            }
            sass_functions_av = (AV*)SvRV(*sass_functions_sv);

            ctx->c_functions = calloc(sizeof(struct Sass_C_Function_Descriptor), av_len(sass_functions_av) + 1/*av_len() is $#av*/ + 1/*null terminated array*/);
            if (!ctx->c_functions) {
                snprintf(error, sizeof(error), "couldn't alloc memory for c_functions");
                goto fail;
            }
            for (i=0; i<=av_len(sass_functions_av); i++) {
                SV** entry_sv = av_fetch(sass_functions_av, i, false);
                AV* entry_av;
                if (!SvROK(*entry_sv) || SvTYPE(SvRV(*entry_sv)) != SVt_PVAV) {
                    snprintf(error, sizeof(error), "each sass_function entry should be an arrayref (SvTYPE=%u)", (unsigned)SvTYPE(SvRV(*entry_sv)));
                    goto fail;
                }
                entry_av = (AV*)SvRV(*entry_sv);

                SV **sig_sv = av_fetch(entry_av, 0, false);
                SV **sub_sv = av_fetch(entry_av, 1, false);

                ctx->c_functions[i].signature = safe_svpv(*sig_sv, "");
                ctx->c_functions[i].function = call_sass_function;
                ctx->c_functions[i].cookie = *sub_sv;
            }
        }

        sass_compile_file(ctx); // Always returns zero. What's the point??

      fail:
        hv_stores(RETVAL, "error_status", newSViv(ctx->error_status || !!*error));
        hv_stores(RETVAL, "output_string", ctx->output_string ? newSVpv(ctx->output_string, 0) : newSV(0));
        hv_stores(RETVAL, "source_map_string", ctx->source_map_string ? newSVpv(ctx->source_map_string, 0) : newSV(0));
        hv_stores(RETVAL, "error_message", *error             ? newSVpv(error, 0)              :
                                              ctx->error_message ? newSVpv(ctx->error_message, 0) : newSV(0));

        sass_free_file_context(ctx);
    }
    OUTPUT:
             RETVAL

SV*
sass2scss(sass, options = SASS2SCSS_PRETTIFY_1)
             const char* sass
             int options
    CODE:
    {

        char* css = sass2scss(sass, options);
        RETVAL = newSVpv(css, strlen(css));
        free (css);

    }
    OUTPUT:
             RETVAL

SV*
quote(str)
             char *str
    CODE:
    {

        char* quoted = quote(str, '"');

        RETVAL = newSVpv(quoted, strlen(quoted));

        free (quoted);

    }
    OUTPUT:
             RETVAL

SV*
unquote(str)
             char *str
    CODE:
    {

        char* unquoted = unquote(str);

        RETVAL = newSVpv(unquoted, strlen(unquoted));

        free (unquoted);

    }
    OUTPUT:
             RETVAL

SV*
import_sv(sv)
             SV* sv
    CODE:
    {

        union Sass_Value value = sv_to_sass_value(sv);

        RETVAL = sass_value_to_sv(value);

        free_sass_value(value);

    }
    OUTPUT:
             RETVAL
