use strict;
use warnings;
use inc::Module::Install 0.65;

name 'Catalyst-Plugin-Compress';
all_from 'lib/Catalyst/Plugin/Compress.pm';

requires 'Compress::Zlib';
recommends 'Compress::Bzip2' => 2;
requires 'Catalyst::Runtime' => '5.7006';

auto_install;
WriteAll;

