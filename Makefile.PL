use inc::Module::Install;
name 'F4';
all_from 'lib/F4.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
