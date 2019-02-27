#!/usr/bin/env perl
# Author: Marcus Hancock-Gaillard
use strict;
use warnings;

use Data::Dumper;
use File::Basename qw(dirname);
use Cwd qw(abs_path);
use lib dirname( abs_path $0 ) . '/lib';

use CSFE qw( csfe_check_cookie csfe_post_request );
