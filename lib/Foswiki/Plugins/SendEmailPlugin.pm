# Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# Copyright (C) 2007-2009 Arthur Clemens (arthur@visiblearea.com), Michael Daum and Foswiki contributors
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version. For
# more details read LICENSE in the root of this distribution.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# As per the GPL, removal of this notice is prohibited.

package Foswiki::Plugins::SendEmailPlugin;

use strict;
use Foswiki::Func;

our $VERSION    = '$Rev: 11069$';
our $RELEASE    = '1.4.1';
our $pluginName = 'SendEmailPlugin';
our $NO_PREFS_IN_TOPIC = 1;

sub initPlugin {

    # check for Plugins.pm versions
    if ( $Foswiki::Plugins::VERSION < 1.026 ) {
        Foswiki::Func::writeWarning(
            "Version mismatch between SendEmailPlugin and Plugins.pm");
        return 0;
    }

    Foswiki::Func::registerTagHandler( 'SENDEMAIL', \&handleSendEmailTag );

    # Plugin correctly initialized
    return 1;
}

sub handleSendEmailTag {
    require Foswiki::Plugins::SendEmailPlugin::Core;
    Foswiki::Plugins::SendEmailPlugin::Core::handleSendEmailTag(@_);
}

1;
