// Copyright (c) 2013-2014 David Caldwell.
// Copyright (c) 2014-2017 Marcel Greter.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

// dont hook libc calls
#define NO_XSLOCKS

#ifdef __cplusplus
extern "C" {
#endif

#include "EXTERN.h"
#undef my_setlocale
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#ifdef __cplusplus
}
#endif

#include <stdbool.h>
#include <stdarg.h>
#include <stdio.h>
#include <sass.h>

#define isSafeSv(sv) sv && SvOK(*sv)
#define Constant(c) newCONSTSUB(stash, #c, newSViv(c))

#undef free

// implement this logic here for now
// libsass has no auto quoting concept
bool sass_string_need_quotes(char* str)
{
    char* it = str;
    if (*it == 0) return false;
    if (!(
        (*it >= 'a' && *it <= 'z') ||
        (*it >= 'A' && *it <= 'Z')
    )) return true;
    ++it;
    while (*it) {
        if (!(
            (*it >= 127) ||
            (*it >= '0' && *it <= '9') ||
            (*it >= 'a' && *it <= 'z') ||
            (*it >= 'A' && *it <= 'Z') ||
            (*it == '\\' && *(it+1) != 0)
        )) return true;
        ++it;
    }
    return false;
}

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
            char* str = SvPV_nolen(sv);
            // coerce all other scalars into a string
            // IMO there should only be strings left!?
            if (sv_derived_from(org, "CSS::Sass::Value::String::Quoted"))
            { return sass_make_qstring(str); }
            else if (sv_derived_from(org, "CSS::Sass::Value::String::Constant"))
            { return sass_make_string(str); }
            // perl-libsass autoquote behavior
            if (sass_string_need_quotes(str))
            { return sass_make_qstring(str); }
            else { return sass_make_string(str); }
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
                    // dereference
                    sv = SvRV(sv);
                    // check if it's an error struct
                    if (SvTYPE(sv) == SVt_PVAV) {
                        bool has_msg = false;
                        if (av_len((AV*)sv) >= 0) {
                            SV** value_svp = av_fetch((AV*)sv, 0, false);
                            has_msg = value_svp && *value_svp && SvOK(*value_svp);
                            return sass_make_error(has_msg ? SvPV_nolen(*value_svp) : "error");
                        } else {
                            return sass_make_error("error");
                        }
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
                int len = av_len(number);
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
                SV* sv_r = *hv_fetchs(color, "r", false);
                SV* sv_g = *hv_fetchs(color, "g", false);
                SV* sv_b = *hv_fetchs(color, "b", false);
                SV* sv_a = *hv_fetchs(color, "a", false);
                return sass_make_color(
                    SvOK(sv_r) ? SvNV(sv_r) : 0,
                    SvOK(sv_g) ? SvNV(sv_g) : 0,
                    SvOK(sv_b) ? SvNV(sv_b) : 0,
                    SvOK(sv_a) ? SvNV(sv_a) : 0
                );
            }

        }
        // EO SvROK

    }
    // perl array reference
    else if (SvTYPE(sv) == SVt_PVAV) {
        AV* av = (AV*) sv;
        enum Sass_Separator sep = SASS_COMMA;
        // special check for space separated lists
        if (sv_derived_from(org, "CSS::Sass::Value::List::Space")) sep = SASS_SPACE;
        union Sass_Value* list = sass_make_list(av_len(av) + 1, sep); // , false
        size_t i;
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
            void* key_ptr = HeKEY(key);
            // using the HePV makros gave me strange gcc warnings here:
            // dereferencing type-punned pointer will break strict-aliasing rules
            union Sass_Value* key_val = (HeKLEN(key) < 0)
              ? sv_to_sass_value((SV*) key_ptr)
              : sass_make_string((char*) key_ptr);
            sass_map_set_key(map, i, key_val);
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
    sv_bless(sv, gv_stashpv("CSS::Sass::Value::Null", GV_ADD));
    return sv;
}

SV* new_sv_sass_string (SV* string, bool quoted) {
    SV* sv = newRV_noinc(string);
    if (quoted) sv_bless(sv, gv_stashpv("CSS::Sass::Value::String::Quoted", GV_ADD));
    else { sv_bless(sv, gv_stashpv("CSS::Sass::Value::String::Constant", GV_ADD)); }
    return sv;
}

SV* new_sv_sass_boolean (SV* boolean) {
    SV* sv = newRV_noinc(newRV_noinc(boolean));
    sv_bless(sv, gv_stashpv("CSS::Sass::Value::Boolean", GV_ADD));
    return sv;
}

SV* new_sv_sass_number (SV* number, SV* unit) {
    AV* array = newAV();
    av_push(array, number);
    av_push(array, unit);
    SV* sv = newRV_noinc(newRV_noinc((SV*) array));
    sv_bless(sv, gv_stashpv("CSS::Sass::Value::Number", GV_ADD));
    return sv;
}

SV* new_sv_sass_color (SV* r, SV* g, SV* b, SV* a) {
    HV* hash = newHV();
    (void)hv_store(hash, "r", 1, r, 0);
    (void)hv_store(hash, "g", 1, g, 0);
    (void)hv_store(hash, "b", 1, b, 0);
    (void)hv_store(hash, "a", 1, a, 0);
    SV* sv = newRV_noinc(newRV_noinc((SV*) hash));
    sv_bless(sv, gv_stashpv("CSS::Sass::Value::Color", GV_ADD));
    return sv;
}

SV* new_sv_sass_error (SV* msg) {
    AV* error = newAV();
    av_push(error, msg);
    SV* sv = newRV_noinc(newRV_noinc(newRV_noinc((SV*) error)));
    sv_bless(sv, gv_stashpv("CSS::Sass::Value::Error", GV_ADD));
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
                     newSVpv(sass_string_get_value(val), 0),
                     false
                 );
        }   break;
        case SASS_LIST: {
            size_t i;
            AV* list = newAV();
            sv = newRV_noinc((SV*) list);
            if (sass_list_get_separator(val) == SASS_SPACE) {
                sv_bless(sv, gv_stashpv("CSS::Sass::Value::List::Space", GV_ADD));
            } else {
                sv_bless(sv, gv_stashpv("CSS::Sass::Value::List::Comma", GV_ADD));
            }
            for (i=0; i<sass_list_get_length(val); i++)
                av_push(list, sass_value_to_sv(sass_list_get_value(val, i)));
        }   break;
        case SASS_MAP: {
            size_t i;
            HV* map = newHV();
            sv = newRV_noinc((SV*) map);
            sv_bless(sv, gv_stashpv("CSS::Sass::Value::Map", GV_ADD));
            for (i=0; i<sass_map_get_length(val); i++) {
                // this should return a scalar sv
                union Sass_Value* key = sass_map_get_key(val, i);
                SV* sv_key = sass_value_to_sv(key);
                // call us recursive if needed to get sass values
                union Sass_Value* value = sass_map_get_value(val, i);
                SV* sv_value = sass_value_to_sv(value);
                // store the key/value pair on the hash
                (void)hv_store_ent(map, sv_key, sv_value, 0);
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


Sass_Import_List sass_importer(const char* cur_path, Sass_Importer_Entry cb, struct Sass_Compiler* comp)
{

    dSP;
    // value from perl function
    SV* perl_value = NULL;
    // value to return to libsass
    // union Sass_Value* sass_value = NULL;

    ENTER;
    SAVETMPS;

    void* cookie = sass_importer_get_cookie(cb);
    struct Sass_Import* previous = sass_compiler_get_last_import(comp);
    const char* prev_abs_path = sass_import_get_abs_path(previous);
    const char* prev_imp_path = sass_import_get_imp_path(previous);

    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(cur_path, 0)));
    XPUSHs(sv_2mortal(newSVpv(prev_abs_path, 0)));
    XPUSHs(sv_2mortal(newSVpv(prev_imp_path, 0)));
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

        int i;
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
                int len = av_len(import_av);
                SV** path_sv = len < 0 ? 0 : av_fetch(import_av, 0, false);
                SV** source_sv = len < 1 ? 0 : av_fetch(import_av, 1, false);
                SV** mapjson_sv = len < 2 ? 0 : av_fetch(import_av, 2, false);
                SV** error_msg_sv = len < 3 ? 0 : av_fetch(import_av, 3, false);
                SV** error_line_sv = len < 4 ? 0 : av_fetch(import_av, 4, false);
                SV** error_column_sv = len < 5 ? 0 : av_fetch(import_av, 5, false);
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
union Sass_Value* call_sass_function(const union Sass_Value* s_args, Sass_Function_Entry cb, struct Sass_Compiler* comp)
{

    dSP;
    // value from perl function
    SV* perl_value = NULL;
    // value to return to libsass
    union Sass_Value* sass_value = NULL;
    size_t i;

    ENTER;
    SAVETMPS;

    void* cookie = sass_function_get_cookie(cb);

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

    SV** input_path_sv           = hv_fetchs(perl_options, "input_path",           false);
    SV** output_path_sv          = hv_fetchs(perl_options, "output_path",          false);
    SV** output_style_sv         = hv_fetchs(perl_options, "output_style",         false);
    SV** source_comments_sv      = hv_fetchs(perl_options, "source_comments",      false);
    SV** omit_source_map_sv      = hv_fetchs(perl_options, "omit_source_map",      false);
    SV** omit_source_map_url_sv  = hv_fetchs(perl_options, "omit_source_map_url",  false);
    SV** source_map_file_urls_sv = hv_fetchs(perl_options, "source_map_file_urls", false);
    SV** source_map_contents_sv  = hv_fetchs(perl_options, "source_map_contents",  false);
    SV** source_map_embed_sv     = hv_fetchs(perl_options, "source_map_embed",     false);
    SV** include_paths_sv        = hv_fetchs(perl_options, "include_paths",        false);
    SV** plugin_paths_sv         = hv_fetchs(perl_options, "plugin_paths",         false);
    SV** precision_sv            = hv_fetchs(perl_options, "precision",            false);
    SV** linefeed_sv             = hv_fetchs(perl_options, "linefeed",             false);
    SV** indent_sv               = hv_fetchs(perl_options, "indent",               false);
    SV** source_map_root_sv      = hv_fetchs(perl_options, "source_map_root",      false);
    SV** source_map_file_sv      = hv_fetchs(perl_options, "source_map_file",      false);
    SV** sass_headers_sv         = hv_fetchs(perl_options, "headers",              false);
    SV** sass_importers_sv       = hv_fetchs(perl_options, "importers",            false);
    SV** sass_functions_sv       = hv_fetchs(perl_options, "functions",            false);

    if (input_path_sv)           sass_option_set_input_path           (sass_options, safe_svpv(*input_path_sv, ""));
    if (output_path_sv)          sass_option_set_output_path          (sass_options, safe_svpv(*output_path_sv, ""));
    if (output_style_sv)         sass_option_set_output_style         (sass_options, SvUV(*output_style_sv));
    if (source_comments_sv)      sass_option_set_source_comments      (sass_options, SvTRUE(*source_comments_sv));
    if (omit_source_map_sv)      sass_option_set_omit_source_map_url  (sass_options, SvTRUE(*omit_source_map_sv));
    if (omit_source_map_url_sv)  sass_option_set_omit_source_map_url  (sass_options, SvTRUE(*omit_source_map_url_sv));
    if (source_map_file_urls_sv) sass_option_set_source_map_file_urls (sass_options, SvTRUE(*source_map_file_urls_sv));
    if (source_map_contents_sv)  sass_option_set_source_map_contents  (sass_options, SvTRUE(*source_map_contents_sv));
    if (source_map_embed_sv)     sass_option_set_source_map_embed     (sass_options, SvTRUE(*source_map_embed_sv));
    if (include_paths_sv)        sass_option_set_include_path         (sass_options, safe_svpv(*include_paths_sv, ""));
    if (plugin_paths_sv)         sass_option_set_plugin_path          (sass_options, safe_svpv(*plugin_paths_sv, ""));
    if (source_map_root_sv)      sass_option_set_source_map_root      (sass_options, safe_svpv(*source_map_root_sv, ""));
    if (source_map_file_sv)      sass_option_set_source_map_file      (sass_options, safe_svpv(*source_map_file_sv, ""));

    // do not set anything if the option is set to undef
    if (isSafeSv(indent_sv))     sass_option_set_indent               (sass_options, SvPV_nolen(*indent_sv));
    if (isSafeSv(linefeed_sv))   sass_option_set_linefeed             (sass_options, SvPV_nolen(*linefeed_sv));
    if (isSafeSv(precision_sv))  sass_option_set_precision            (sass_options, SvUV(*precision_sv));

    if (sass_importers_sv) {
        int i;
        AV* sass_importers_av;
        if (!SvROK(*sass_importers_sv) || SvTYPE(SvRV(*sass_importers_sv)) != SVt_PVAV) {
            return newSVpvf("sass_importers should be an arrayref (SvTYPE=%u)", (unsigned)SvTYPE(SvRV(*sass_importers_sv)));
        }
        sass_importers_av = (AV*)SvRV(*sass_importers_sv);

        Sass_Importer_List c_importers = sass_make_importer_list(av_len(sass_importers_av) + 1);

        if (!c_importers) {
            return newSVpv("couldn't alloc memory for c_importers", 0);
        }
        for (i=0; i<=av_len(sass_importers_av); i++) {
            SV** entry_sv = av_fetch(sass_importers_av, i, false);
            AV* entry_av;
            if (!SvROK(*entry_sv) || SvTYPE(SvRV(*entry_sv)) != SVt_PVAV) {
                return newSVpvf("each sass_importer entry should be an arrayref (SvTYPE=%u)", (unsigned)SvTYPE(SvRV(*entry_sv)));
            }
            entry_av = (AV*)SvRV(*entry_sv);

            SV** importer_sv = av_fetch(entry_av, 0, false);
            SV** priority_sv = av_fetch(entry_av, 1, false);
            double priority = priority_sv ? SvNV(*priority_sv) : 0;
            if (!importer_sv) return newSVpv("custom importer without callback", 0);
            c_importers[i] = sass_make_importer(sass_importer, priority, *importer_sv);
        }

        sass_option_set_c_importers(sass_options, c_importers);
    }

    if (sass_headers_sv) {
        int i;
        AV* sass_headers_av;
        if (!SvROK(*sass_headers_sv) || SvTYPE(SvRV(*sass_headers_sv)) != SVt_PVAV) {
            return newSVpvf("sass_headers should be an arrayref (SvTYPE=%u)", (unsigned)SvTYPE(SvRV(*sass_headers_sv)));
        }
        sass_headers_av = (AV*)SvRV(*sass_headers_sv);

        Sass_Importer_List c_headers = sass_make_importer_list(av_len(sass_headers_av) + 1);

        if (!c_headers) {
            return newSVpv("couldn't alloc memory for c_headers", 0);
        }
        for (i=0; i<=av_len(sass_headers_av); i++) {
            SV** entry_sv = av_fetch(sass_headers_av, i, false);
            AV* entry_av;
            if (!SvROK(*entry_sv) || SvTYPE(SvRV(*entry_sv)) != SVt_PVAV) {
                return newSVpvf("each sass_header entry should be an arrayref (SvTYPE=%u)", (unsigned)SvTYPE(SvRV(*entry_sv)));
            }
            entry_av = (AV*)SvRV(*entry_sv);

            SV** header_sv = av_fetch(entry_av, 0, false);
            SV** priority_sv = av_fetch(entry_av, 1, false);
            double priority = priority_sv ? SvNV(*priority_sv) : 0;
            if (!header_sv) return newSVpv("custom header without callback", 0);
            c_headers[i] = sass_make_importer(sass_importer, priority, *header_sv);
        }

        sass_option_set_c_headers(sass_options, c_headers);
    }

    if (sass_functions_sv) {
        int i;
        AV* sass_functions_av;
        if (!SvROK(*sass_functions_sv) || SvTYPE(SvRV(*sass_functions_sv)) != SVt_PVAV) {
            return newSVpvf("sass_functions should be an arrayref (SvTYPE=%u)", (unsigned)SvTYPE(SvRV(*sass_functions_sv)));
        }
        sass_functions_av = (AV*)SvRV(*sass_functions_sv);

        Sass_Function_List c_functions = sass_make_function_list(av_len(sass_functions_av) + 1);

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

    SV* sv_error_status = newSViv(error_status || SvOK(err));
    SV* sv_output_string = output_string ? newSVpv(output_string, 0) : newSV(0);
    SV* sv_source_map_string = source_map_string ? newSVpv(source_map_string, 0) : newSV(0);
    SV* sv_error_line = SvOK(err) ? err : error_line ? newSViv(error_line) : newSViv(0);
    SV* sv_error_column = SvOK(err) ? err : error_column ? newSViv(error_column) : newSViv(0);
    SV* sv_error_src = SvOK(err) ? err : error_src ? newSVpv(error_src, 0) : newSViv(0);
    SV* sv_error_text = SvOK(err) ? err : error_text ? newSVpv(error_text, 0) : newSV(0);
    SV* sv_error_json = SvOK(err) ? err : error_json ? newSVpv(error_json, 0) : newSV(0);
    SV* sv_error_file = SvOK(err) ? err : error_file ? newSVpv(error_file, 0) : newSV(0);
    SV* sv_error_message = SvOK(err) ? err : error_message ? newSVpv(error_message, 0) : newSV(0);

    SvUTF8_on(sv_output_string);
    SvUTF8_on(sv_source_map_string);

    SvUTF8_on(sv_error_src);
    SvUTF8_on(sv_error_text);
    SvUTF8_on(sv_error_json);
    SvUTF8_on(sv_error_file);
    SvUTF8_on(sv_error_message);

    (void)hv_stores(RETVAL, "error_status",      sv_error_status);
    (void)hv_stores(RETVAL, "output_string",     sv_output_string);
    (void)hv_stores(RETVAL, "source_map_string", sv_source_map_string);
    (void)hv_stores(RETVAL, "error_line",        sv_error_line);
    (void)hv_stores(RETVAL, "error_column",      sv_error_column);
    (void)hv_stores(RETVAL, "error_message",     sv_error_message);
    (void)hv_stores(RETVAL, "error_src",         sv_error_src);
    (void)hv_stores(RETVAL, "error_text",        sv_error_text);
    (void)hv_stores(RETVAL, "error_json",        sv_error_json);
    (void)hv_stores(RETVAL, "error_file",        sv_error_file);
    (void)hv_stores(RETVAL, "included_files",    newRV_noinc((SV*) sv_included_files));

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

    // enum Sass_OP
    Constant(AND);
    Constant(OR);
    Constant(EQ);
    Constant(NEQ);
    Constant(GT);
    Constant(GTE);
    Constant(LT);
    Constant(LTE);
    Constant(ADD);
    Constant(SUB);
    Constant(MUL);
    Constant(DIV);
    Constant(MOD);
}


HV*
compile_sass(input_string, options)
             char* input_string
             HV* options
    CODE:
        RETVAL = newHV();
        sv_2mortal((SV*)RETVAL);
    {

        char* src = strdup(input_string);
        // input_string will be freed by libsass (first "loaded" source)
        struct Sass_Data_Context* data_ctx = sass_make_data_context(src);
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
        sass_free_memory (css);

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

        sass_free_memory (quoted);

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

        sass_free_memory (unquoted);

    }
    OUTPUT:
             RETVAL

SV*
sass_operation(op, a, b)
             SV* op
             SV* a
             SV* b
    CODE:
    {

        union Sass_Value* lhs = sv_to_sass_value(a);
        union Sass_Value* rhs = sv_to_sass_value(b);

        union Sass_Value* rv = 0;
        switch ((enum Sass_OP) SvNV(op)) {
          case ADD: rv = sass_value_op(ADD, lhs, rhs); break;
          case MUL: rv = sass_value_op(MUL, lhs, rhs); break;
          case AND: rv = sass_value_op(AND, lhs, rhs); break;
          case OR:  rv = sass_value_op(OR,  lhs, rhs); break;
          case EQ:  rv = sass_value_op(EQ,  lhs, rhs); break;
          case NEQ: rv = sass_value_op(NEQ, lhs, rhs); break;
          case GT:  rv = sass_value_op(GT,  lhs, rhs); break;
          case GTE: rv = sass_value_op(GTE, lhs, rhs); break;
          case LT:  rv = sass_value_op(LT,  lhs, rhs); break;
          case LTE: rv = sass_value_op(LTE, lhs, rhs); break;
          case SUB: rv = sass_value_op(SUB, lhs, rhs); break;
          case DIV: rv = sass_value_op(DIV, lhs, rhs); break;
          case MOD: rv = sass_value_op(MOD, lhs, rhs); break;
          default: rv = sass_make_error("invalid op"); break;
        }

        if (rv) RETVAL = sass_value_to_sv(rv);
        else RETVAL = new_sv_sass_null();

        sass_delete_value(rhs);
        sass_delete_value(lhs);
        sass_delete_value(rv);

    }
    OUTPUT:
             RETVAL

SV*
sass_stringify(v)
             SV* v
    CODE:
    {

        union Sass_Value* val = sv_to_sass_value(v);
        // ToDo: make compressed and precision option configurable
        union Sass_Value* rv = sass_value_stringify(val, false, 5);
        RETVAL = sass_value_to_sv(rv);
        sass_delete_value(val);
        sass_delete_value(rv);

    }
    OUTPUT:
             RETVAL

SV*
auto_quote(str)
             char* str
    CODE:
    {

        if (sass_string_need_quotes(str)) {

            char* string = sass_string_quote(str, '*');

            RETVAL = newSVpv(string, 0);

            sass_free_memory (string);

        } else {

            RETVAL = newSVpv(str, 0);

        }

    }
    OUTPUT:
             RETVAL

SV*
need_quotes(str)
             char* str
    CODE:
    {

      RETVAL = sass_string_need_quotes(str) ? &PL_sv_yes : &PL_sv_no;

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
