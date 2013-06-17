// Copyright © 2013 David Caldwell.
//
// This library is free software; you can redistribute it and/or modify
// it under the same terms as Perl itself, either Perl version 5.12.4 or,
// at your option, any later version of Perl 5 you may have available.

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <stdbool.h>

#include "ppport.h"

#include "sass_interface.h"

#define hv_fetch_key(hv, key, lval)     hv_fetch((hv), (key), sizeof(key)-1, (lval))
#define hv_store_key(hv, key, sv, hash) hv_store((hv), (key), sizeof(key)-1, (sv), (hash))

#define Constant(c) newCONSTSUB(stash, #c, newSViv(c))

char *safe_svpv(SV *sv)
{
    size_t length;
    char *str = SvPV(sv, length);
    if (memchr(str, 0, length+1)) // NULL Terminated?
        return str;
    return NULL;
}


MODULE = CSS::Sass		PACKAGE = CSS::Sass

BOOT:
{
    HV *stash = gv_stashpv("CSS::Sass", 0);
    Constant(SASS_STYLE_NESTED);
    //Constant(stash, SASS_STYLE_EXPANDED); // not implemented in libsass yet
    //Constant(stash, SASS_STYLE_COMPACT);  // not implemented in libsass yet
    Constant(SASS_STYLE_COMPRESSED);
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
        ctx->source_string = input_string;
        SV **output_style_sv    = hv_fetch_key(options, "output_style",    false);
        SV **source_comments_sv = hv_fetch_key(options, "source_comments", false);
        SV **include_paths_sv   = hv_fetch_key(options, "include_paths",   false);
        SV **image_path_sv      = hv_fetch_key(options, "image_path",      false);
        if (output_style_sv)
            ctx->options.output_style = SvUV(*output_style_sv);
        if (source_comments_sv)
            ctx->options.source_comments = SvTRUE(*source_comments_sv);
        if (include_paths_sv)
            ctx->options.include_paths = safe_svpv(*include_paths_sv);
        if (image_path_sv)
            ctx->options.image_path = safe_svpv(*image_path_sv);
        }

        sass_compile(ctx); // Always returns zero. What's the point??

        hv_store_key(RETVAL, "error_status", newSViv(ctx->error_status), 0);
        hv_store_key(RETVAL, "output_string", ctx->output_string ? newSVpv(ctx->output_string, 0) : newSV(0), 0);
        hv_store_key(RETVAL, "error_message", ctx->error_message ? newSVpv(ctx->error_message, 0) : newSV(0), 0);

        sass_free_context(ctx);
    }
    OUTPUT:
             RETVAL
