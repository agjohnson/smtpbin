#!/usr/bin/env perl

use SMTPbin::Daemon;
SMTPbin::Model::connect;
SMTPbin::Daemon::mail;
