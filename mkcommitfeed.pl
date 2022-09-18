#!/usr/bin/perl
use strict;

use Getopt::Long;
use Pod::Usage;
use Time::Local;
use Path::Class;
use lib glob file (__FILE__)->dir->subdir ('modules', '*', 'lib')->stringify;

my $file_name;
my $feed_url;
my $feed_title = 'ChangeLog';
my $feed_author_name;
my $feed_author_mail;
my $feed_author_url;
my $feed_lang = 'i-default';
my $feed_related_url;
my $feed_license_url;
my $feed_rights;
my $entry_content;
my $entry_author_name;
my $entry_author_mail;
my $entry_date;
my $entry_title;

GetOptions (
  'entry-author-mail=s' => \$entry_author_mail,
  'entry-author-name=s' => \$entry_author_name,
  'entry-content=s' => \$entry_content,
  'entry-title=s' => \$entry_title,
  'feed-author-mail=s' => \$feed_author_mail,
  'feed-author-name=s' => \$feed_author_name,
  'feed-author-url=s' => \$feed_author_url,
  'feed-lang=s' => \$feed_lang,
  'feed-license-url=s' => \$feed_license_url,
  'feed-related-url=s' => \$feed_related_url,
  'feed-rights=s' => \$feed_rights,
  'feed-title=s' => \$feed_title,
  'feed-url=s' => \$feed_url,
  'file-name=s' => \$file_name,
  'help' => sub {
    pod2usage (-exitval => 0, -verbose => 2);
  },
) or pod2usage (-exitval => 1, -verbose => 1);
pod2usage (-exitval => 1, -verbose => 1,
           -msg => "Required argument --file-name is not specified.\n")
      unless defined $file_name;
pod2usage (-exitval => 1, -verbose => 1,
           -msg => "Required argument --feed-url is not specified.\n")
      unless defined $feed_url;

unless (defined $entry_content) {
  $entry_content = '';
  $entry_content .= $_ while <>;
}

if ($entry_content =~ /^(\d+)-(\d+)-(\d+)\s+(.+)<([^<>]+)>/m) {
#  $entry_date //= timegm (0, 0, 0, $3, $2-1, $1);
  $entry_author_name //= $4;
  $entry_author_mail //= $5;
  $entry_author_name =~ s/\s+$//;
}
$entry_date //= time;

pod2usage (-exitval => 1, -verbose => 1,
           -msg => "Required argument --entry-author-name is not specified.\n")
      unless defined $entry_author_name;

unless (defined $entry_title) {
  my $time = [gmtime $entry_date];
  $entry_title = sprintf '%04d-%02d-%02d %s', 1900+$time->[5], 1+$time->[4],
      $time->[3], $entry_author_name;
}

require Message::DOM::DOMImplementation;
my $dom = Message::DOM::DOMImplementation->new;
my $doc;

{
  if (-f $file_name) {
    open my $file, '<:encoding(utf8)', $file_name or die "$0: $file_name: $!";
    local $/ = undef;
    $doc = $dom->create_document;
    $doc->inner_html (<$file>);
  } else {
    $doc = $dom->create_atom_feed_document
        ($feed_url, $feed_title, $feed_lang);
  }
}

$doc->dom_config
    ->{q<http://suika.fam.cx/www/2006/dom-config/create-child-element>} = 1;
my $feed = $doc->document_element;
unless ($feed) {
  $feed = $doc->create_element_ns ('http://www.w3.org/2005/Atom', 'feed');
  $doc->append_child ($feed);
}
$feed->set_attribute_ns ('http://www.w3.org/2000/xmlns/',
                         'xmlns', $feed->namespace_uri);

unless (@{$feed->author_elements}) {
  if (defined $feed_author_name) {
    my $author = $doc->create_element_ns ($feed->namespace_uri, 'author');
    $author->name ($feed_author_name);
    $author->email ($feed_author_mail) if defined $feed_author_mail;
    $author->uri ($feed_author_url) if defined $feed_author_url;
    $feed->append_child ($author);
  }
}
unless (@{$feed->link_elements}) {
  my $link_self = $doc->create_element_ns ($feed->namespace_uri, 'link');
  $link_self->rel ('self');
  $link_self->type ('application/atom+xml');
  $link_self->hreflang ($feed_lang);
  $link_self->href ($feed_url);
  $feed->append_child ($link_self);

  if (defined $feed_related_url) {
    my $link = $doc->create_element_ns ($feed->namespace_uri, 'link');
    $link->rel ('related');
    $link->href ($feed_related_url);
    $feed->append_child ($link);
  }

  if (defined $feed_license_url) {
    my $link = $doc->create_element_ns ($feed->namespace_uri, 'link');
    $link->rel ('license');
    $link->href ($feed_license_url);
    $feed->append_child ($link);
  }
}

if (defined $feed_rights) {
  $feed->rights_element->text_content ($feed_rights);
}

my $entry_id = 'entry-' . time;
my $entry = $feed->add_new_entry ($feed_url . '#' . $entry_id,
                                  $entry_title);
$entry->set_attribute_ns ('http://www.w3.org/XML/1998/namespace',
                          'xml:id' => $entry_id);
if (defined $entry_author_name) {
  my $author = $doc->create_element_ns ($feed->namespace_uri, 'author');
  $author->name ($entry_author_name);
  $author->email ($entry_author_mail) if defined $entry_author_mail;
  $entry->append_child ($author);
}
$entry->updated_element->value ($entry_date);
my $content = $entry->content_element;
$content->type ('text');
$content->text_content ($entry_content);

my $feed_date = $entry_date;
my $feed_updated = $feed->updated_element;
my $feed_updated_value = $feed_updated->value;
if ($feed_updated_value < $feed_date) {
  $feed_updated->value ($feed_date);
}


{
  open my $file, '>:utf8', $file_name or die "$0: $file_name: $!";
  print $file $doc->inner_html;
}

__END__

=head1 NAME

mkcommitfeed.pl - Commit Log Feed Generator

=head1 SYNOPSIS

  mkcommitfeed.pl \
    --file-name filename.atom \
    --feed-url http://example.com/myproject/filename.atom \
    --feed-title "MyProject Commit Log" \
    --feed-lang langtag \
    --feed-related-url "http://example.com/myproject/" \
    --feed-license-url "http://example.com/myproject/license" \
    --feed-rights "Copyright or copyleft statement" \
    < changes-in-this-revision.txt

=head1 DESCRIPTION

The C<mkcommitfeed.pl> script provides a command-line interface to
update an Atom Feed that is intended for providing commit logs for a
software developmenet project.

The script, when invoked, adds an Atom Entry that describes a change
made to the project's repository.

=head1 STANDARD INPUT

A description for the change must be specified to the standard input.
It is used as the plain text content of the atom:content element of
the Entry for the change to add.

Non-ASCII characters are not supported in this version of this script.
Maybe a future version of this script would support UTF-8.

=head1 ARGUMENTS

There are command-line options for the script.  Some of them are
required, while the others are optional.  As a general rule, an option
whose name begins with C<--entry> specifies a property for the Entry
to add, while an option whose name begins with C<--feed> specifies a
property for the entire Feed.  Option values for Feed properties might
not be used when updating an existing Feed document.

=over 4

=item C<--entry-author-mail I<foo@domain.example>> (optional)

Specifies the mail address of the person who made a change.  It is
used as the content of the C<atom:email> element of the C<atom:author>
element of the Entry.

If this option is not specified, but the standard input includes a
ChangeLog entry in the standard GNU format, then the mail address is
taken from the ChangeLog entry.  Otherwise, C<atom:email> element is
not specified.

The option value must be an RFC 2822 C<addr-spec> that does not match
C<obs-addr-spec> (i.e. standard email address format).  Otherwise the
generated Feed would be non-conforming.

=item C<--entry-author-name I<author-name>> (conditionally required)

Specifies the human readable name of the person who made a change.  It
is used as the content of the C<atom:name> element of the
C<atom:author> element of the Entry.

If this option is not specified, but the standard input includes a
ChangeLog entry in the standard GNU format, then the name is taken
from the ChangeLog entry.  If the standard input does not include a
GNU format ChangeLog entry, then the C<--entry-author-name> option
must be specified.

Non-ASCII characters are not supported in this version of this script.

=item C<--entry-content I<description>> (optional)

Specifies the description of the change.  It is used as the content of
the C<atom:content> element of the Entry, with C<type=text>.

If this option is specified, its value is used as if it were from the
standard input and the actual standard input, if any, is ignored.  If
neither this option nor the standard input is specified, then the
description is assumed as the empty string.

Non-ASCII characters are not supported in this version of this script.

=item C<--entry-title I<title>> (optional)

Specifies the title of the change.  It is used as the content of the
C<atom:title> element of the Entry, with C<type=text>.

If this option is not specified, then the date of the change, as well
as the name of the author, is used as title.

Non-ASCII characters are not supported in this version of this script.

=item C<--feed-author-mail I<foo@domain.example>> (optional)

Specifies the mail address of the author of the Feed.  It is used as
the content of the C<atom:email> element of the C<atom:author> element
of the Feed.

This option is ignored if the C<--feed-author-name> option is not
specified.

If this option is not specified, C<atom:email> element is not
specified.

The option value must be an RFC 2822 C<addr-spec> that does not match
C<obs-addr-spec> (i.e. standard email address format).  Otherwise the
generated Feed would be non-conforming.

This option is ignored if the Feed already has an C<atom:author>
element.

=item C<--feed-author-name I<author-name>> (optional)

Specifies the human readable name of the author of the Feed.  It is
used as the content of the C<atom:name> element of the C<atom:author>
element of the Feed.

If this option is not specified, the C<atom:author> element is not
specified in the Feed.

Non-ASCII characters are not supported in this version of this script.

This option is ignored if the Feed already has an C<atom:author>
element.

=item C<--feed-author-url I<url>> (optional)

Specifies the URI for the author (e.g. URL of the Web page for the
author).  It is used as the content of the C<atom:uri> element of the
C<atom:author> element of the Feed.

If the C<--feed-author-name> option is not specified, this option is
ignored.

If this option is not specified, the C<atom:uri> element is not
specified.

The option value must be a URI reference conforming to RFC 3986.  It
should be an absolute reference unless you understand what is the base
URL that is used to resolve a relative reference.  Non-ASCII
characters (i.e. IRI references) are not supported in this version of
this script.

This option is ignored if the Feed already has an C<atom:author>
element.

=item C<--feed-lang I<langtag>> (optional)

Specifies the natural language used in textual parts of the Feed.  It
is used as the value of C<xml:lang> attribute of the root element of
the Feed.

If this option is not specified, the default value I<i-default> is used.

This option is ignored if the Feed already exists and has a
C<atom:link> element.

=item C<--feed-license-url I<url>> (optional)

Specifies the URL that describes the license of the Feed.  It is used
as the C<href> attribute value of an C<atom:link> element whose C<rel>
is C<license>.

If this option is not specified, the C<atom:link> element whose C<rel>
is C<license> is not specified.

The option value must be a URI reference conforming to RFC 3986.  It
should be an absolute reference unless you understand what is the base
URL that is used to resolve a relative reference.  Non-ASCII
characters (i.e. IRI references) are not supported in this version of
this script.

This option is ignored if the Feed already has a C<atom:link>
element.

=item C<--feed-related-url I<url>> (optional)

Specifies a related URL for the Feed.  Usually the URL for the project
Web page should be specified.  It is used as the C<href> attribute
value of an C<atom:link> element whose C<rel> is C<related>.

If this option is not specified, the C<atom:link> element whose C<rel>
is C<related> is not specified.

The option value must be a URI reference conforming to RFC 3986.  It
should be an absolute reference unless you understand what is the base
URL that is used to resolve a relative reference.  Non-ASCII
characters (i.e. IRI references) are not supported in this version of
this script.

This option is ignored if the Feed already has a C<atom:link>
element.

=item C<--feed-rights C<license-terms>> (optional)

Specifies the license terms for the Feed.  It is used as the content
of the C<atom:rights> element of the Feed.

If there is the C<atom:rights> element exists, its value is replaced
by the value of this option.

If this option is not specified, the C<atom:rights> element is not
added.  If there are already the C<atom:rights> element specified,
however, it is not removed from the Feed.

Non-ASCII characters are not supported in this version of this script.

=item C<--feed-title C<title>> (optional)

Specifies the title of the Feed.  It is used as the content of the
C<atom:title> of the Feed.

If this option is not specified, the default value "ChangeLog" is used.

If there is Feed exists, then this option is ignored.

Non-ASCII characters are not supported in this version of this script.

=item C<--feed-url C<url>> (required)

Specifies the URL of the Feed itself.  It is used in various places,
such as in the C<href> attribute of the C<atom:link> element whose
C<rel> is C<self>.

The option value must be a URI reference conforming to RFC 3986.  It
should be an absolute reference unless you understand what is the base
URL that is used to resolve a relative reference.  Non-ASCII
characters (i.e. IRI references) are not supported in this version of
this script.

=item C<--file-name C<path-to-atom-file>> (required)

Specifies the path to the file that contains the Atom Feed.

If the specified file is not found, then a new file is created.
Otherwise, the existing file is loaded as an Atom Feed and then it is
updated.

The file, if exists, must be encoded in UTF-8.  The new content of the
file generated by this script is encoded in UTF-8.

=item C<--help>

Shows a help message and aborts.

=back

=head1 DEPENDENCY

For the execution of C<mkcommitfeed.pl>, the libiraries below are
required, as well as Perl 5.10.0 or later:

manakai-core <https://suika.suikawiki.org/www/manakai-core/doc/web/>.

Whatpm <https://suika.suikawiki.org/www/markup/html/whatpm/readme>.

=head1 AVAILABILITY

The latest version of this script is available in the Git repository:
<https://suika.suikawiki.org/gate/git/wi/vc/cvscommitfeed.git/tree>.

=head1 SEE ALSO

The C<mkcommitfeed.pl> Web site
L<https://suika.suikawiki.org/commitfeed/readme>.

=head1 AUTHOR

Wakaba <wakaba@suikawiki.org>.

=head1 HISTORY

This module was originally developed as part of Whatpm
L<https://suika.suikawiki.org/www/markup/html/whatpm/readme>.

An out-of-date Atom Feed for updates of this script, which was itself
generated by this script, is available at
L<https://suika.suikawiki.org/commitfeed/commitfeed-commit>.

The script is no longer maintained as of 2012.  This script is
considered obsolete, as Web interfaces for modern version management
systems tend to have their own feeds.

=head1 LICENSE

Copyright 2008-2012 Wakaba <wakaba@suikawiki.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
