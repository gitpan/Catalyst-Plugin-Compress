package Catalyst::Plugin::Compress;

use strict;
use Catalyst::Utils;
use NEXT;

our $VERSION = '0.001';

my $_method;
my %_compression_lib = (
    gzip => 'Compress::Zlib',
    deflate => 'Compress::Zlib',
    bzip2 => 'Compress::Bzip2',
);

sub _gzip_compress {
    Compress::Zlib::memGzip(shift);
}

sub _bzip2_compress {
    Compress::Bzip2::memBzip(shift);
}

sub _deflate_compress {
    my $content = shift;
    my $result;

    my ($d, $out, $status);
    ($d, $status) = Compress::Zlib::deflateInit(
        -WindowBits => -Compress::Zlib::MAX_WBITS(),
    );
    unless ($status == Compress::Zlib::Z_OK()) {
        die("Cannot create a deflation stream. Error: $status");
    }

    ($out, $status) = $d->deflate($content);
    unless ($status == Compress::Zlib::Z_OK()) {
        die("Deflation failed. Error: $status");
    }
    $result .= $out;

    ($out, $status) = $d->flush;
    unless ($status == Compress::Zlib::Z_OK()) {
        die("Deflation failed. Error: $status");
    }

    return $result . $out;
}

sub setup {
    my $c = shift;
    if ($_method = $c->config->{compression_format}) {
        $_method = 'gzip'
            if $_method eq 'zlib';

        my $lib_name = $_compression_lib{$_method};
        die qq{No compression_format named "$_method"}
            unless $lib_name;
        Catalyst::Utils::ensure_class_loaded($lib_name);

        *_do_compress = \&{"_${_method}_compress"};
    }
    $c->NEXT::setup(@_);
}

sub finalize {
    my $c = shift;

    if ((not defined $_method)
        or $c->res->content_encoding
        or (not $c->res->body)
        or ($c->res->status != 200)
        or ($c->res->content_type !~ /^text|xml$|javascript$/)
    ) {
        return $c->NEXT::finalize;
    }

    my $accept = $c->request->header('Accept-Encoding') || '';

    unless (index($accept, $_method) >= 0) {
        return $c->NEXT::finalize;
    }

    my $body = $c->res->body;
    if (ref $body) {
        eval { local $/; $body = <$body> };
        die "Unknown type of ref in body."
            if ref $body;
    }

    my $compressed = _do_compress($body);
    $c->response->body($compressed);
    $c->response->content_length(length($compressed));
    $c->response->content_encoding($_method);
    $c->response->headers->push_header('Vary', 'Accept-Encoding');

    $c->NEXT::finalize;
}

1;

__END__

=head1 NAME

Catalyst::Plugin::Compress - Compress response

=head1 SYNOPSIS

    use Catalyst qw/Compress/;

or

    use Catalyst qw/
        Unicode
        Compress
    /;

If you want to use this plugin with L<Catalyst::Plugin::Unicode>.

Remember to specify compression_format with:

    __PACKAGE__->config(
        compression_format => $format,
    );

$format can be either gzip bzip2 zlib or deflate.  bzip2 is B<*only*> supported
by lynx and some other console text-browsers.

=head1 DESCRIPTION

This module combines L<Catalyst::Plugin::Deflate> L<Catalyst::Plugin::Gzip>
L<Catalyst::Plugin::Zlib> into one.

It compress response to [gzip bzip2 zlib deflate] if client supports it.

B<NOTE>: If you want to use this module with L<Catalyst::Plugin::Unicode>, You
B<MUST> load this plugin B<AFTER> L<Catalyst::Plugin::Unicode>.

    use Catalyst qw/
        Unicode
        Compress
    /;

If you don't, You'll get error which is like:

[error] Caught exception in engine "Wide character in subroutine entry at
/usr/lib/perl5/site_perl/5.8.8/Compress/Zlib.pm line xxx."

=head1 SEE ALSO

L<Catalyst>.

=head1 AUTHOR

Yiyi Hu C<yiyihu@gmail.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under
the same terms as perl itself.

=cut

