// Copyright © 2013 David Caldwell.
//
// This library is free software; you can redistribute it and/or modify
// it under the same terms as Perl itself, either Perl version 5.12.4 or,
// at your option, any later version of Perl 5 you may have available.

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "sass_interface.h"

#define hv_fetch_key(hv, key, lval)     hv_fetch((hv), (key), sizeof(key)-1, (lval))
#define hv_store_key(hv, key, sv, hash) hv_store((hv), (key), sizeof(key)-1, (sv), (hash))

MODULE = CSS::Sass		PACKAGE = CSS::Sass

int
SASS_STYLE_NESTED()
    CODE:
        RETVAL = SASS_STYLE_NESTED;
    OUTPUT:
        RETVAL

#// These are in sass_interface.h but aren't implemented:
#//
#// int
#// SASS_STYLE_EXPANDED()
#//     CODE:
#//         RETVAL = SASS_STYLE_EXPANDED
#//     OUTPUT:
#//         RETVAL
#//
#// int
#// SASS_STYLE_COMAPCT()
#//     CODE:
#//         RETVAL = SASS_STYLE_COMPACT
#//     OUTPUT:
#//         RETVAL

int
SASS_STYLE_COMPRESSED()
    CODE:
        RETVAL = SASS_STYLE_COMPRESSED;
    OUTPUT:
        RETVAL

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
        if (include_paths_sv) {
            size_t include_paths_length;
            char *include_paths = SvPV(*include_paths_sv, include_paths_length);
            if (memchr(include_paths, 0, include_paths_length+1)) // NULL Terminated?
                ctx->options.include_paths = include_paths;
        }
        if (image_path_sv) {
            size_t image_path_length;
            char *image_path = SvPV(*image_path_sv, image_path_length);
            if (memchr(image_path, 0, image_path_length+1)) // NULL Terminated?
                ctx->options.image_path = image_path;
        }

        sass_compile(ctx); // Always returns zero. What's the point??

        hv_store_key(RETVAL, "error_status", newSViv(ctx->error_status), 0);
        hv_store_key(RETVAL, "output_string", ctx->output_string ? newSVpv(ctx->output_string, 0) : newSV(0), 0);
        hv_store_key(RETVAL, "error_message", ctx->error_message ? newSVpv(ctx->error_message, 0) : newSV(0), 0);

        sass_free_context(ctx);
    }
    OUTPUT:
             RETVAL
