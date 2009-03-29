# Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# Copyright (c) 2007-2009 by Arthur Clemens, Michael Daum
#
# and Foswiki Contributors. All Rights Reserved. Foswiki Contributors
# are listed in the AUTHORS file in the root of this distribution.
# NOTE: Please extend that file, not this notice.
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
# For licensing info read LICENSE file in the Foswiki root.

package Foswiki::Plugins::SendEmailPlugin::Core;

# Always use strict to enforce variable scoping
use strict;
use Foswiki::Func;
use Foswiki::Plugins;

use vars qw( $debug $emailRE );

my $RETRY_COUNT                  = 5;
my $ERROR_STATUS_TAG             = 'SendEmailErrorStatus';
my $ERROR_MESSAGE_TAG            = 'SendEmailErrorMessage';
my $NOTIFICATION_CSS_CLASS       = 'sendEmailPluginNotification';
my $NOTIFICATION_ERROR_CSS_CLASS = 'sendEmailPluginError';
my $NOTIFICATION_ANCHOR_NAME     = 'FormPluginNotification';
my %ERROR_STATUS                 = (
    'noerror' => 1,
    'error'   => 2,
);
my $ERROR_TITLE;
my $ERROR_BUTTON_LABEL;
my $EMAIL_SENT_SUCCESS_MESSAGE;
my $EMAIL_SENT_ERROR_MESSAGE;
my $ERROR_INVALID_ADDRESS;
my $ERROR_EMPTY_TO_EMAIL;
my $ERROR_EMPTY_FROM_EMAIL;
my $ERROR_NO_PERMISSION_FROM;
my $ERROR_NO_PERMISSION_TO;
my $ERROR_NO_PERMISSION_CC;

=pod

writes a debug message if the $debug flag is set

=cut

sub writeDebug {
    Foswiki::Func::writeDebug("SendEmailPlugin -- $_[0]")
      if $debug;
}

=pod

some init steps

=cut

sub init {
    my $session = shift;
    $Foswiki::Plugins::SESSION ||= $session;
    my $pluginName = $Foswiki::Plugins::SendEmailPlugin::pluginName;
    $debug = $Foswiki::cfg{Plugins}{$pluginName}{Debug} || 0;
    $emailRE = Foswiki::Func::getRegularExpression('emailAddrRegex');
    initMessageStrings();
}

sub initMessageStrings {
    my $session = shift;

    my $language = Foswiki::Func::getPreferencesValue("LANGUAGE") || 'en';
    my $pluginName = $Foswiki::Plugins::SendEmailPlugin::pluginName;

    $ERROR_TITLE =
      $Foswiki::cfg{Plugins}{$pluginName}{Messages}{SendError}{$language};
    $ERROR_BUTTON_LABEL =
      $Foswiki::cfg{Plugins}{$pluginName}{Messages}{ButtonLabel}{$language};
    $EMAIL_SENT_SUCCESS_MESSAGE =
      $Foswiki::cfg{Plugins}{$pluginName}{Messages}{SentSuccess}{en};
    $EMAIL_SENT_ERROR_MESSAGE =
      $Foswiki::cfg{Plugins}{$pluginName}{Messages}{SentError}{$language};
    $ERROR_INVALID_ADDRESS =
      $Foswiki::cfg{Plugins}{$pluginName}{Messages}{InvalidAddress}{$language};
    $ERROR_EMPTY_TO_EMAIL =
      $Foswiki::cfg{Plugins}{$pluginName}{Messages}{EmptyTo}{$language};
    $ERROR_EMPTY_FROM_EMAIL =
      $Foswiki::cfg{Plugins}{$pluginName}{Messages}{EmptyFrom}{$language};
    $ERROR_NO_PERMISSION_FROM =
      $Foswiki::cfg{Plugins}{$pluginName}{Messages}{NoPermissionFrom}
      {$language};
    $ERROR_NO_PERMISSION_TO =
      $Foswiki::cfg{Plugins}{$pluginName}{Messages}{NoPermissionTo}{$language};
    $ERROR_NO_PERMISSION_CC =
      $Foswiki::cfg{Plugins}{$pluginName}{Messages}{NoPermissionCc}{$language};
}

=pod

Invoked by bin/sendemail

=cut

sub sendEmail {
    my $session = shift;

    writeDebug("called sendEmail()");
    init($session);

    my $query        = Foswiki::Func::getCgiQuery();
    my $errorMessage = '';

    return finishSendEmail( $session, $ERROR_STATUS{'error'} )
      unless $query;

    # get TO
    my $to = $query->param('to') || $query->param('To');

    return finishSendEmail( $session, $ERROR_STATUS{'error'},
        $ERROR_EMPTY_TO_EMAIL )
      unless $to;

    my @toEmails = ();
    foreach my $thisTo ( split( /\s*,\s*/, $to ) ) {
        my $addrs;

        if ( $thisTo =~ /$emailRE/ ) {

            # regular address
            $addrs = $thisTo;
        }
        else {

            # get TO user info
            my $wikiName = Foswiki::Func::getWikiName($thisTo);
            my @addrs    = Foswiki::Func::wikinameToEmails($wikiName);
            $addrs = $addrs[0] if @addrs;

            unless ($addrs) {

                # no regular address and no address found in user info

                $errorMessage = $ERROR_INVALID_ADDRESS;
                $errorMessage =~ s/\$EMAIL/$thisTo/go;
                return finishSendEmail( $session, $ERROR_STATUS{'error'},
                    $errorMessage );
            }
        }

        # validate TO
        if (  !matchesPreference( 'Allow', 'MailTo', $thisTo )
            || matchesPreference( 'Deny', 'MailTo', $thisTo ) )
        {
            $errorMessage = $ERROR_NO_PERMISSION_TO;
            $errorMessage =~ s/\$EMAIL/$thisTo/go;
            Foswiki::Func::writeWarning($errorMessage);
            return finishSendEmail( $session, $ERROR_STATUS{'error'},
                $errorMessage );
        }

        push @toEmails, $addrs;
    }
    $to = join( ', ', @toEmails );
    writeDebug("to=$to");

    # get FROM
    my $from = $query->param('from') || $query->param('From');

    unless ($from) {

        # get from user settings
        my $emails = Foswiki::Func::wikiToEmail();
        my @emails = split( /\s*,*\s/, $emails );
        $from = shift @emails if @emails;
    }

    unless ($from) {

        # fallback to webmaster
        $from = $Foswiki::cfg{WebMasterEmail}
          || Foswiki::Func::getPreferencesValue('WIKIWEBMASTER');
    }

    # validate FROM
    return finishSendEmail( $session, $ERROR_STATUS{'error'},
        $ERROR_EMPTY_FROM_EMAIL )
      unless $from;

    if (  !matchesPreference( 'Allow', 'MailFrom', $from )
        || matchesPreference( 'Deny', 'MailFrom', $from ) )
    {
        $errorMessage = $ERROR_NO_PERMISSION_FROM;
        $errorMessage =~ s/\$EMAIL/$from/go;
        Foswiki::Func::writeWarning($errorMessage);
        return finishSendEmail( $session, $ERROR_STATUS{'error'},
            $errorMessage );
    }

    unless ( $from =~ m/$emailRE/ ) {
        $errorMessage = $ERROR_INVALID_ADDRESS;
        $errorMessage =~ s/\$EMAIL/$from/go;
        return finishSendEmail( $session, $ERROR_STATUS{'error'},
            $errorMessage );
    }
    writeDebug("from=$from");

    # get CC
    my $cc = $query->param('cc') || $query->param('CC') || '';

    if ($cc) {
        my @ccEmails = ();
        foreach my $thisCC ( split( /\s*,\s*/, $cc ) ) {
            my $addrs;

            if ( $thisCC =~ /$emailRE/ ) {

                # normal email address
                $addrs = $thisCC;

            }
            else {

                # get from user info
                my $wikiName = Foswiki::Func::getWikiName($thisCC);
                my @addrs    = Foswiki::Func::wikinameToEmails($wikiName);
                $addrs = $addrs[0] if @addrs;

                unless ($addrs) {

                    # no regular address and no address found in user info

                    $errorMessage = $ERROR_INVALID_ADDRESS;
                    $errorMessage =~ s/\$EMAIL/$thisCC/go;
                    return finishSendEmail( $session, $ERROR_STATUS{'error'},
                        $errorMessage );
                }
            }

            # validate CC
            if (  !matchesPreference( 'Allow', 'MailCc', $thisCC )
                || matchesPreference( 'Deny', 'MailCc', $thisCC ) )
            {
                $errorMessage = $ERROR_NO_PERMISSION_CC;
                $errorMessage =~ s/\$EMAIL/$thisCC/go;
                Foswiki::Func::writeWarning($errorMessage);
                return finishSendEmail( $session, $ERROR_STATUS{'error'},
                    $errorMessage );
            }

            push @ccEmails, $addrs;
        }
        $cc = join( ', ', @ccEmails );
        writeDebug("cc=$cc");
    }

    # get SUBJECT
    my $subject = $query->param('subject') || $query->param('Subject') || '';
    writeDebug("subject=$subject") if $subject;

    # get BODY
    my $body = $query->param('body') || $query->param('Body') || '';
    writeDebug("body=$body") if $body;

    # get template
    my $templateName = $query->param('template') || 'sendemail';
    my $template = Foswiki::Func::readTemplate($templateName);
    unless ($template) {
        $template = <<'HERE';
From: %FROM%
To: %TO%
CC: %CC%
Subject: %SUBJECT%

%BODY%
HERE
    }

    # format email
    my $mail = $template;
    $mail =~ s/%FROM%/$from/go;
    $mail =~ s/%TO%/$to/go;
    $mail =~ s/%CC%/$cc/go;
    $mail =~ s/%SUBJECT%/$subject/go;
    $mail =~ s/%BODY%/$body/go;

    writeDebug("mail=\n$mail");

    # send email
    $errorMessage = Foswiki::Func::sendEmail( $mail, $RETRY_COUNT );

    # finally
    my $errorStatus =
      $errorMessage ? $ERROR_STATUS{'error'} : $ERROR_STATUS{'noerror'};

    writeDebug("errorStatus=$errorStatus");
    my $redirectUrl = $query->param('redirectto');
    finishSendEmail( $session, $errorStatus, $errorMessage, $redirectUrl );
}

=pod

Checks if a given value matches a preferences pattern. The pref pattern
actually is a list of patterns. The function returns true if 
at least one of the patterns in the list matches.

=cut

sub matchesPreference {
    my ( $mode, $key, $value ) = @_;

    my $pluginName = $Foswiki::Plugins::SendEmailPlugin::pluginName;
    my $pattern = $Foswiki::cfg{Plugins}{$pluginName}{Permissions}{$mode}{$key};

    writeDebug("called matchesPreference($mode, $key, $value)");
    writeDebug("matching pattern=$pattern");
    writeDebug( "mode=" . ( $mode =~ /Allow/i ? 1 : 0 ) );

	if ($mode =~ /Deny/i && !$pattern) {
	    # no pattern, so noone is denied
	    return 0;
	}

    $pattern =~ s/^\s//o;
    $pattern =~ s/\s$//o;
    $pattern = '(' . join( ')|(', split( /\s*,\s*/, $pattern ) ) . ')';

    writeDebug("final matching pattern=$pattern");

    my $result = ( $value =~ /$pattern/ ) ? 1 : 0;
    
    writeDebug( "result=$result");

    return $result;
}

=pod

=cut

sub handleSendEmailTag {
    my ( $session, $params, $topic, $web ) = @_;

    init();
    addHeader();

    my $query = Foswiki::Func::getCgiQuery();
    return '' if !$query;

    my $errorStatus = $query->param($ERROR_STATUS_TAG);

    writeDebug("handleSendEmailTag; errorStatus=$errorStatus")
      if $errorStatus;

    return '' if !defined $errorStatus;

    my $feedbackSuccess = $params->{'feedbackSuccess'};

    unless ( defined $feedbackSuccess ) {
        $feedbackSuccess = $EMAIL_SENT_SUCCESS_MESSAGE
          || '';
    }
    $feedbackSuccess =~ s/^\s*(.*?)\s*$/$1/go;    # remove surrounding spaces

    my $feedbackError = $params->{'feedbackError'};
    unless ( defined $feedbackError ) {
        $feedbackError = $EMAIL_SENT_ERROR_MESSAGE || '';
    }

    my $userMessage =
      ( $errorStatus == $ERROR_STATUS{'error'} )
      ? $feedbackError
      : $feedbackSuccess;
    $userMessage =~ s/^\s*(.*?)\s*$/$1/go;        # remove surrounding spaces
    my $errorMessage = $query->param($ERROR_MESSAGE_TAG) || '';

    return wrapHtmlNotificationContainer( $userMessage, $errorStatus,
        $errorMessage, $topic, $web );
}

=pod

=cut

sub finishSendEmail {
    my ( $session, $errorStatus, $errorMessage, $redirectUrl ) = @_;

    my $query = Foswiki::Func::getCgiQuery();

    writeDebug("_finishSendEmail errorStatus=$errorStatus;")
      if $errorStatus;

    $query->param( -name => $ERROR_STATUS_TAG, -value => $errorStatus )
      if $query;

    $errorMessage ||= '';
    writeDebug("_finishSendEmail errorMessage=$errorMessage;")
      if $errorMessage;

    $query->param( -name => $ERROR_MESSAGE_TAG, -value => $errorMessage )
      if $query;

    my $web     = $session->{webName};
    my $topic   = $session->{topicName};
    my $origUrl = Foswiki::Func::getScriptUrl( $web, $topic, 'view' );

    $query->param( -name => 'origurl', -value => $origUrl );

    my $section =
      $query->param( ( $errorStatus == $ERROR_STATUS{'error'} )
        ? 'errorsection'
        : 'successsection' );

    $query->param( -name => 'section', -value => $section )
      if $section;

    $redirectUrl ||= $origUrl;
    Foswiki::Func::redirectCgiQuery( undef, $redirectUrl, 1 );

    # would pass '#'=>$NOTIFICATION_ANCHOR_NAME but the anchor removes
    # the ERROR_STATUS_TAG param
}

=pod

=cut

sub addHeader {

    my $header = <<'EOF';
<style type="text/css" media="all">
@import url("%PUBURL%/%SYSTEMWEB%/SendEmailPlugin/sendemailplugin.css");
</style>
EOF
    Foswiki::Func::addToHEAD( 'SENDEMAILPLUGIN', $header );
}

=pod

=cut

sub wrapHtmlNotificationContainer {
    my ( $text, $errorStatus, $errorMessage, $topic, $web ) = @_;

    my $cssClass = $NOTIFICATION_CSS_CLASS;
    $cssClass .= ' ' . $NOTIFICATION_ERROR_CSS_CLASS
      if ( $errorStatus == $ERROR_STATUS{'error'} );

    my $message = $text;

    if ($errorMessage) {
        if ( length $errorMessage < 256 ) {
            $message .= ' ' . $errorMessage;
        }
        else {
            my $oopsUrl =
              Foswiki::Func::getOopsUrl( $web, $topic, 'oopsgeneric' );
            $errorMessage = '<verbatim>' . $errorMessage . '</verbatim>';
            my $errorForm = <<'HERE';
<form enctype="application/x-www-form-urlencoded" name="mailerrorfeedbackform" action="%OOPSURL%" method="POST">
<input type="hidden" name="template" value="oopsgeneric" />
<input type="hidden" name="param1" value="%ERRORTITLE%" />
<input type="hidden" name="param2" value="%ERRORMESSAGE%" />
<input type="hidden" name="param3" value="" />
<input type="hidden" name="param4" value="" />
<input type="submit" class="foswikiButton" value="%ERRORBUTTON%"  />
</form>
HERE
            $errorForm =~ s/%OOPSURL%/$oopsUrl/go;
            $errorForm =~ s/%ERRORTITLE%/ $ERROR_TITLE /go;
            $errorForm =~ s/%ERRORMESSAGE%/$errorMessage/go;
            $errorForm =~ s/%ERRORBUTTON%/$ERROR_BUTTON_LABEL/go;
            $message .= ' ' . $errorForm;
        }
    }

    return
        "#$NOTIFICATION_ANCHOR_NAME\n"
      . '<div class="'
      . $cssClass . '">'
      . $message
      . '</div>';
}

1;
