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

#include "sass2scss.h"
#include "sass_context.h"

#define Constant(c) newCONSTSUB(stash, #c, newSViv(c))

#undef free

char* safe_svpv(SV* sv, char* _default)
{

    size_t length;
    char* str = SvPV(sv, length);
    // NULL Terminated "array"
    if (memchr(str, 0, length + 1))
        return str;
    return _default;
}

union Sass_Value* sass_make_error_f(char* format,...)
{
    va_list ap;
    va_start(ap, format);
    SV* res = vnewSVpvf(format, &ap);
    va_end(ap);
    return sass_make_error(SvPV_nolen(res));
}

// convert from perl to libsass
union Sass_Value* sv_to_sass_value(SV* sv)
{

    // remember me
    SV* org = sv;

    // dereference if possible
    if (SvROK(sv)) sv = SvRV(sv);

    // have a scalar value
    if (SvTYPE(sv) < SVt_PVAV) {

        // if scalar is undef we return a null type
        if (!SvOK(sv)) return sass_make_null();

        // perl double
        else if (SvNOK(sv)) { // i.e. 4.2
            // perl doesn't know numbers with units
            return sass_make_number(SvNV(sv), "");
        }
        // perl integer
        else if (SvIOK(sv)) { // i.e. 42
            // perl doesn't know numbers with units
            return sass_make_number(SvIV(sv), "");
        }
        // perl string
        else if (SvPOK(sv)) { // i.e. "foobar"
            // coerce all other scalars into a string
            // IMO there should only be strings left!?
            return sass_make_string(SvPV_nolen(sv));
        }

        // perl reference
        else if (SvROK(sv)) {

            // dereference
            sv = SvRV(sv);

            // check out scalar value
            if (SvTYPE(sv) < SVt_PVAV) {
                // if scalar is undef we return a null type
                if (!SvOK(sv)) return sass_make_null();
                // perl reference
                if (SvROK(sv)) {
                    // check if it's an error struct
                    if (SvTYPE(SvRV(sv)) == SVt_PVAV) {
                        SV** value_svp = av_fetch((AV*)SvRV(sv), 0, false);
                        SV* value_sv = value_svp ? *value_svp : &PL_sv_undef;
                        return sass_make_error(SvPV_nolen(value_sv));
                    }
                // if we have a scalar
                } else if (!SvROK(sv)) {
                    // then it is a boolean type
                    return sass_make_boolean(SvTRUE(sv));
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
                    if (len > 0) {
                      SV** unit_svp = av_fetch(number, 1, false);
                      SV* unit_sv = unit_svp ? *unit_svp : newSVpv("", 0);
                      return sass_make_number(val, SvPV_nolen(unit_sv));
                    }
                    return sass_make_number(val, "");
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
                return sass_make_color(r, g, b, a);
            }

        }
        // EO SvROK

    }
    // perl array reference
    else if (SvTYPE(sv) == SVt_PVAV) {
        AV* av = (AV*) sv;
        enum Sass_Separator sep = SASS_COMMA;
        // special check for space separated lists
        if (sv_derived_from(org, "CSS::Sass::Type::List::Space")) sep = SASS_SPACE;
        union Sass_Value* list = sass_make_list(av_len(av) + 1, sep);
        int i;
        for (i = 0; i < sass_list_get_length(list); i++) {
            SV** value_svp = av_fetch(av, i, false);
            SV* value_sv = value_svp ? *value_svp : &PL_sv_undef;
            sass_list_set_value(list, i, sv_to_sass_value(value_sv));
        }
        return list;
    }
    // perl hash reference
    else if (SvTYPE(sv) == SVt_PVHV) {
        HV* hv = (HV*) sv;
        union Sass_Value* map = sass_make_map(HvUSEDKEYS(hv));
        HE* key;
        int i = 0;
        hv_iterinit(hv);
        while (NULL != (key = hv_iternext(hv))) {
            sass_map_set_key(map, i, sv_to_sass_value(HeSVKEY_force(key)));
            sass_map_set_value(map, i,  sv_to_sass_value(HeVAL(key)));
            i++;
        }
        return map;
    }

    // if scalar is undef we return a null type
    if (!SvOK(sv)) return sass_make_null();

    // stringify anything else
    // can be usefull for soft-refs
    return sass_make_string(SvPV_nolen(sv));

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
SV* sass_value_to_sv(union Sass_Value* val)
{
    SV* sv;
    switch(sass_value_get_tag(val)) {
        case SASS_NULL: {
            sv = new_sv_sass_null();
        }   break;
        case SASS_BOOLEAN: {
            sv = new_sv_sass_boolean(
                     newSViv(sass_boolean_get_value(val))
                 );
        }   break;
        case SASS_NUMBER: {
            sv = new_sv_sass_number(
                     newSVnv(sass_number_get_value(val)),
                     newSVpv(sass_number_get_unit(val), 0)
                 );
        }   break;
        case SASS_COLOR: {
            sv = new_sv_sass_color(
                     newSVnv(sass_color_get_r(val)),
                     newSVnv(sass_color_get_g(val)),
                     newSVnv(sass_color_get_b(val)),
                     newSVnv(sass_color_get_a(val))
                 );
        }   break;
        case SASS_STRING: {
            sv = new_sv_sass_string(
                     newSVpv(sass_string_get_value(val), 0)
                 );
        }   break;
        case SASS_LIST: {
            int i;
            AV* list = newAV();
            sv = newRV_noinc((SV*) list);
            if (sass_list_get_separator(val) == SASS_SPACE) {
                sv_bless(sv, gv_stashpv("CSS::Sass::Type::List::Space", GV_ADD));
            } else {
                sv_bless(sv, gv_stashpv("CSS::Sass::Type::List::Comma", GV_ADD));
            }
            for (i=0; i<sass_list_get_length(val); i++)
                av_push(list, sass_value_to_sv(sass_list_get_value(val, i)));
        }   break;
        case SASS_MAP: {
            int i;
            HV* map = newHV();
            sv = newRV_noinc((SV*) map);
            sv_bless(sv, gv_stashpv("CSS::Sass::Type::Map", GV_ADD));
            for (i=0; i<sass_map_get_length(val); i++) {
                // this should return a scalar sv
                union Sass_Value* key = sass_map_get_key(val, i);
                SV* sv_key = sass_value_to_sv(key);
                // call us recursive if needed to get sass values
                union Sass_Value* value = sass_map_get_value(val, i);
                SV* sv_value = sass_value_to_sv(value);
                // store the key/value pair on the hash
                hv_store_ent(map, sv_key, sv_value, 0);
                // make key sv mortal
                sv_2mortal(sv_key);
            }
        }   break;
        case SASS_ERROR: {
            sv = new_sv_sass_error(
                newSVpv(sass_error_get_message(val), 0)
            );
        }   break;
        default:
            sv = new_sv_sass_error(
                newSVpvf("BUG: Sass_Value type is unknown (%d)", sass_value_get_tag(val))
            );
            break;
    }

    return sv;
}


struct Sass_Import** sass_importer(const char* url, const char* prev, void* cookie)
{

    dSP;
    // value from perl function
    SV* perl_value = NULL;
    // value to return to libsass
    // union Sass_Value* sass_value = NULL;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(url, 0)));
    XPUSHs(sv_2mortal(newSVpv(prev, 0)));
    PUTBACK;

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

    // dereference if possible
    if (perl_value && SvROK(perl_value)) {
        perl_value = SvRV(perl_value);
    }

    size_t len = 0;
    struct Sass_Import** incs = 0;

    if (SvTRUE(ERRSV)) {
        char* message = SvPV_nolen(ERRSV);
        incs = sass_make_import_list(1);
        incs[0] = sass_make_import_entry(0, 0, 0);
        sass_import_set_error(incs[0], message, -1, -1);
    }

    // do nothing if we got undef retuned
    else if (SvTYPE(perl_value) == SVt_NULL) { }
    // we may have gotten a single path
    else if (SvTYPE(perl_value) < SVt_PVAV) {

        // try to load the filename
        incs = sass_make_import_list(1);
        char* path = SvPV_nolen(perl_value);
        incs[0] = sass_make_import_entry(path, 0, 0);

    }
    // the expected type is an array
    else if (SvTYPE(perl_value) == SVt_PVAV) {

        size_t i;
        AV* sass_imports_av = (AV*) perl_value;
        size_t length = av_len(sass_imports_av);
        incs = sass_make_import_list(length + 1);

        // process all import statements returned by perl
        for (i = 0; i <= av_len(sass_imports_av); i++) {

            char* path = 0;
            char* source = 0;
            char* mapjson = 0;
            char* error_msg = 0;
            size_t error_line = -1;
            size_t error_column = -1;

            // get the entry from the array
            // can either be another array or a path string
            SV** import_svp = av_fetch(sass_imports_av, i, false);

            // error fetching entry?
            if (!import_svp) continue;

            SV* import_sv = *import_svp;

            // dereference if possible
            if (SvROK(import_sv)) {
                import_sv = SvRV(import_sv);
            }

            // we may have gotten a single path
            if (SvTYPE(import_sv) < SVt_PVAV) {
                path = SvPV_nolen(import_sv);
            }
            // the expected type is an array
            else if (SvTYPE(import_sv) == SVt_PVAV) {
                AV* import_av = (AV*) import_sv;
                SV** path_sv = av_fetch(import_av, 0, false);
                SV** source_sv = av_fetch(import_av, 1, false);
                SV** mapjson_sv = av_fetch(import_av, 2, false);
                SV** error_msg_sv = av_fetch(import_av, 3, false);
                SV** error_line_sv = av_fetch(import_av, 4, false);
                SV** error_column_sv = av_fetch(import_av, 5, false);
                if (path_sv && SvOK(*path_sv)) path = SvPV_nolen(*path_sv);
                if (source_sv && SvOK(*source_sv)) source = SvPV_nolen(*source_sv);
                if (mapjson_sv && SvOK(*mapjson_sv)) mapjson = SvPV_nolen(*mapjson_sv);
                if (error_msg_sv && SvOK(*error_msg_sv)) error_msg = SvPV_nolen(*error_msg_sv);
                if (error_line_sv && SvOK(*error_line_sv)) error_line = SvNV(*error_line_sv);
                if (error_column_sv && SvOK(*error_column_sv)) error_column = SvNV(*error_column_sv);
            }
            // error
            else {
                // output a warning to inform the implementer of his mischief
                // vwarn seems to have a bug (expects char** but needs char***)
                vwarn("Importer returned invalid data type", 0);
            }

            // check valid import statement
            if (!path && !source) continue;
            // push new import on to the importer list
            // need to make copy of blobs handled by perl
            char* cp_source = source ? strdup(source) : 0;
            char* cp_mapjson = mapjson ? strdup(mapjson) : 0;
            incs[len] = sass_make_import_entry(path, cp_source, cp_mapjson);
            if (error_msg && strlen(error_msg) > 0) {
              sass_import_set_error(incs[len], error_msg, error_line, error_column);
            }
            ++len;
        }
        // EO each SV in AV

    }
    // error
    else {
        // output a warning to inform the implementer of his mischief
        // vwarn seems to have a bug (expects char** but needs char***)
        vwarn("Importer returned invalid data type", 0);
    }

    PUTBACK;
    FREETMPS;
    LEAVE;

    return incs;

}


// we are called by libsass to dispatch to registered functions
union Sass_Value* call_sass_function(const union Sass_Value* s_args, void* cookie)
{

    dSP;
    // value from perl function
    SV* perl_value = NULL;
    // value to return to libsass
    union Sass_Value* sass_value = NULL;
    int i;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    for (i=0; i<sass_list_get_length(s_args); i++) {
        // get the Sass_Value from libsass
        union Sass_Value* arg = sass_list_get_value(s_args, i);
        // convert and add argument for perl
        XPUSHs(sv_2mortal(sass_value_to_sv(arg)));
    }
    PUTBACK;

    // free input values
    // free_sass_value(s_args);

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
        sass_value = sass_make_error_f("%s:%d %s: Perl sub died with message: %s!\n", __FILE__, __LINE__, __func__, SvPV_nolen(ERRSV));
    } else if (count > 1) {
        // perl function returned a list of values (undefined behaviour)
        sass_value = sass_make_error_f("%s:%d %s: Perl sub must not return a list of values!\n", __FILE__, __LINE__, __func__);
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

SV* init_sass_options(struct Sass_Options* sass_options, HV* perl_options)
{

    SV** input_path_sv          = hv_fetchs(perl_options, "input_path",           false);
    SV** output_path_sv         = hv_fetchs(perl_options, "output_path",          false);
    SV** output_style_sv        = hv_fetchs(perl_options, "output_style",         false);
    SV** source_comments_sv     = hv_fetchs(perl_options, "source_comments",      false);
    SV** omit_source_map_sv     = hv_fetchs(perl_options, "omit_source_map",      false);
    SV** omit_source_map_url_sv = hv_fetchs(perl_options, "omit_source_map_url",  false);
    SV** source_map_contents_sv = hv_fetchs(perl_options, "source_map_contents",  false);
    SV** source_map_embed_sv    = hv_fetchs(perl_options, "source_map_embed",     false);
    SV** include_paths_sv       = hv_fetchs(perl_options, "include_paths",        false);
    SV** plugin_paths_sv        = hv_fetchs(perl_options, "plugin_paths",         false);
    SV** precision_sv           = hv_fetchs(perl_options, "precision",            false);
    SV** source_map_root_sv     = hv_fetchs(perl_options, "source_map_root",      false);
    SV** source_map_file_sv     = hv_fetchs(perl_options, "source_map_file",      false);
    SV** sass_functions_sv      = hv_fetchs(perl_options, "sass_functions",       false);
    SV** importer_sv            = hv_fetchs(perl_options, "importer",             false);

    if (input_path_sv)          sass_option_set_input_path          (sass_options, safe_svpv(*input_path_sv, ""));
    if (output_path_sv)         sass_option_set_output_path         (sass_options, safe_svpv(*output_path_sv, ""));
    if (output_style_sv)        sass_option_set_output_style        (sass_options, SvUV(*output_style_sv));
    if (source_comments_sv)     sass_option_set_source_comments     (sass_options, SvTRUE(*source_comments_sv));
    if (omit_source_map_sv)     sass_option_set_omit_source_map_url (sass_options, SvTRUE(*omit_source_map_sv));
    if (omit_source_map_url_sv) sass_option_set_omit_source_map_url (sass_options, SvTRUE(*omit_source_map_url_sv));
    if (source_map_contents_sv) sass_option_set_source_map_contents (sass_options, SvTRUE(*source_map_contents_sv));
    if (source_map_embed_sv)    sass_option_set_source_map_embed    (sass_options, SvTRUE(*source_map_embed_sv));
    if (include_paths_sv)       sass_option_set_include_path        (sass_options, safe_svpv(*include_paths_sv, ""));
    if (plugin_paths_sv)        sass_option_set_plugin_path         (sass_options, safe_svpv(*plugin_paths_sv, ""));
    if (precision_sv)           sass_option_set_precision           (sass_options, SvUV(*precision_sv));
    if (source_map_root_sv)     sass_option_set_source_map_root     (sass_options, safe_svpv(*source_map_root_sv, ""));
    if (source_map_file_sv)     sass_option_set_source_map_file     (sass_options, safe_svpv(*source_map_file_sv, ""));

    if (importer_sv) { sass_option_set_importer(sass_options, sass_make_importer(sass_importer, *importer_sv)); }

    if (sass_functions_sv) {
        int i;
        AV* sass_functions_av;
        if (!SvROK(*sass_functions_sv) || SvTYPE(SvRV(*sass_functions_sv)) != SVt_PVAV) {
            return newSVpvf("sass_functions should be an arrayref (SvTYPE=%u)", (unsigned)SvTYPE(SvRV(*sass_functions_sv)));
        }
        sass_functions_av = (AV*)SvRV(*sass_functions_sv);

        Sass_C_Function_List c_functions = sass_make_function_list(av_len(sass_functions_av) + 1);

        if (!c_functions) {
            return newSVpv("couldn't alloc memory for c_functions", 0);
        }
        for (i=0; i<=av_len(sass_functions_av); i++) {
            SV** entry_sv = av_fetch(sass_functions_av, i, false);
            AV* entry_av;
            if (!SvROK(*entry_sv) || SvTYPE(SvRV(*entry_sv)) != SVt_PVAV) {
                return newSVpvf("each sass_function entry should be an arrayref (SvTYPE=%u)", (unsigned)SvTYPE(SvRV(*entry_sv)));
            }
            entry_av = (AV*)SvRV(*entry_sv);

            SV** sig_sv = av_fetch(entry_av, 0, false);
            SV** sub_sv = av_fetch(entry_av, 1, false);
            if (!sig_sv) return newSVpv("custom function without prototype", 0);
            if (!sub_sv) return newSVpv("custom function without callback", 0);
            c_functions[i] = sass_make_function(safe_svpv(*sig_sv, ""), call_sass_function, *sub_sv);
        }

        sass_option_set_c_functions(sass_options, c_functions);
    }

    return &PL_sv_undef;

}

void finalize_sass_context(struct Sass_Context* ctx, HV* RETVAL, SV* err)
{

    const int error_status = sass_context_get_error_status(ctx);
    const char* error_json = sass_context_get_error_json(ctx);
    const char* error_file = sass_context_get_error_file(ctx);
    size_t error_line = sass_context_get_error_line(ctx);
    size_t error_column = sass_context_get_error_column(ctx);
    const char* error_text = sass_context_get_error_text(ctx);
    const char* error_message = sass_context_get_error_message(ctx);
    const char* error_src = 0; // sass_context_get_error_src(ctx);
    const char* output_string = sass_context_get_output_string(ctx);
    const char* source_map_string = sass_context_get_source_map_string(ctx);
    char** included_files = sass_context_get_included_files(ctx);

    AV* sv_included_files = newAV();
    char** it = included_files;
    while (it && (*it) != 0) {
      av_push(sv_included_files, newSVpv(*it, 0));
      ++it;
    }

    hv_stores(RETVAL, "error_status",      newSViv(error_status || SvOK(err)));
    hv_stores(RETVAL, "output_string",     output_string ? newSVpv(output_string, 0) : newSV(0));
    hv_stores(RETVAL, "source_map_string", source_map_string ? newSVpv(source_map_string, 0) : newSV(0));
    hv_stores(RETVAL, "error_line",        SvOK(err) ? err : error_line ? newSViv(error_line) : newSViv(0));
    hv_stores(RETVAL, "error_column",      SvOK(err) ? err : error_column ? newSViv(error_column) : newSViv(0));
    hv_stores(RETVAL, "error_src",         SvOK(err) ? err : error_src ? newSVpv(error_src, 0) : newSViv(0));
    hv_stores(RETVAL, "error_text",        SvOK(err) ? err : error_text ? newSVpv(error_text, 0) : newSV(0));
    hv_stores(RETVAL, "error_message",     SvOK(err) ? err : error_message ? newSVpv(error_message, 0) : newSV(0));
    hv_stores(RETVAL, "error_json",        SvOK(err) ? err : error_json ? newSVpv(error_json, 0) : newSV(0));
    hv_stores(RETVAL, "error_file",        SvOK(err) ? err : error_file ? newSVpv(error_file, 0) : newSV(0));
    hv_stores(RETVAL, "included_files",    newRV_noinc((SV*) sv_included_files));

}

MODULE = CSS::Sass		PACKAGE = CSS::Sass

BOOT:
{
    HV* stash = gv_stashpv("CSS::Sass", 0);

    Constant(SASS_STYLE_NESTED);
    Constant(SASS_STYLE_EXPANDED);
    Constant(SASS_STYLE_COMPACT);
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
             char* input_string
             HV* options
    CODE:
        RETVAL = newHV();
        sv_2mortal((SV*)RETVAL);
    {

        struct Sass_Data_Context* data_ctx = sass_make_data_context(strdup(input_string));
        struct Sass_Context* ctx = sass_data_context_get_context(data_ctx);
        struct Sass_Options* ctx_opt = sass_context_get_options(ctx);
        SV* err = init_sass_options(ctx_opt, options);
        if (!SvTRUE(err)) {
          struct Sass_Compiler* compiler = sass_make_data_compiler(data_ctx);
          sass_compiler_parse(compiler);
          sass_compiler_execute(compiler);
          sass_delete_compiler(compiler);
        }
        // if (!SvTRUE(err)) sass_compile_data_context(data_ctx);
        finalize_sass_context(ctx, RETVAL, err);
        sass_delete_data_context(data_ctx);

    }
    OUTPUT:
             RETVAL


HV*
compile_sass_file(input_path, options)
             char* input_path
             HV* options
    CODE:
        RETVAL = newHV();
        sv_2mortal((SV*)RETVAL);
    {

        struct Sass_File_Context* file_ctx = sass_make_file_context(input_path);
        struct Sass_Context* ctx = sass_file_context_get_context(file_ctx);
        struct Sass_Options* ctx_opt = sass_context_get_options(ctx);
        SV* err = init_sass_options(ctx_opt, options);
        if (!SvTRUE(err)) {
          struct Sass_Compiler* compiler = sass_make_file_compiler(file_ctx);
          sass_compiler_parse(compiler);
          sass_compiler_execute(compiler);
          sass_delete_compiler(compiler);
        }
        finalize_sass_context(ctx, RETVAL, err);
        sass_delete_file_context(file_ctx);

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
        RETVAL = newSVpv(css, 0);
        free (css);

    }
    OUTPUT:
             RETVAL

SV*
quote(str)
             char* str
    CODE:
    {

        char* quoted = sass_string_quote(str, '*');

        RETVAL = newSVpv(quoted, 0);

        free (quoted);

    }
    OUTPUT:
             RETVAL

SV*
unquote(str)
             char* str
    CODE:
    {

        char* unquoted = sass_string_unquote(str);

        RETVAL = newSVpv(unquoted, 0);

        free (unquoted);

    }
    OUTPUT:
             RETVAL

SV*
import_sv(sv)
             SV* sv
    CODE:
    {

        union Sass_Value* value = sv_to_sass_value(sv);

        RETVAL = sass_value_to_sv(value);

        sass_delete_value(value);

    }
    OUTPUT:
             RETVAL

SV*
libsass_version()
    CODE:
    {

        RETVAL = newSVpv(libsass_version(), 0);

    }
    OUTPUT:
             RETVAL

SV*
sass2scss_version()
    CODE:
    {

        RETVAL = newSVpv(sass2scss_version(), 0);

    }
    OUTPUT:
             RETVAL
