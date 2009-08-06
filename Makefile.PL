use inc::Module::Install;
name 'F4';
all_from 'lib/F4.pm';

requires 'Any::Moose';
requires 'Path::Class';
requires 'FindBin::libs';
requires 'HTTP::Engine';
requires 'String::Random';
requires 'Class::Singleton';
requires 'Digest::HMAC_SHA1';
requires 'Amazon::S3';

test_requires 'Test::TCP';
tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
