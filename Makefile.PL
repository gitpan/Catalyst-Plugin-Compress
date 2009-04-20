use strict;
use warnings;
use inc::Module::Install 0.65;

name 'Catalyst-Plugin-Compress';
all_from 'lib/Catalyst/Plugin/Compress.pm';

requires 'Compress::Zlib';
recommends 'Compress::Bzip2' => 2;
requires 'MRO::Compat';
requires 'Catalyst::Runtime' => '5.80001';

auto_install;
WriteAll;

