#!/usr/bin/perl
use strict;
use warnings;
use DynaLoader;

my ($library, $command) = @ARGV;
die "Usage: MediaBridge.pl LIBRARY [toggle]\n" unless $library;

$ENV{MEDIAREMOTEADAPTER_OPTION_no_artwork} = "";
my $symbol = "adapter_get_env";
if (defined $command && $command eq "toggle") {
  $ENV{MEDIAREMOTEADAPTER_PARAM_adapter_send_0_command} = "2";
  $symbol = "adapter_send_env";
}

my $handle = DynaLoader::dl_load_file($library, 0)
  or die "Failed to load media bridge\n";
my $function = DynaLoader::dl_find_symbol($handle, $symbol)
  or die "Failed to load media bridge command\n";
DynaLoader::dl_install_xsub("main::$symbol", $function);
no strict "refs";
&{"main::$symbol"}();
