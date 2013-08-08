#!/usr/bin/env perl

use lib 'lib';

use SMTPbin::Daemon;
SMTPbin::Model->connect;
SMTPbin::Daemon::mail;
