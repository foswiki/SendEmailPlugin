#---+ SendEmailPlugin
# **BOOLEAN**
# Enable debugging (debug messages will be written to data/debug.txt)
$Foswiki::cfg{Plugins}{SendEmailPlugin}{Debug} = '1';
#
# **STRING 300**
# Regular expression of mail addresses that we are allowed to send to. To send to multiple addresses you can write (address1|address2).
$Foswiki::cfg{Plugins}{SendEmailPlugin}{Permissions}{Allow}{MailTo} = '';
#
# **STRING 300**
# Regular expression of mail addresses that we want to deny to send to. To send to multiple addresses you can write (address1|address2). To deny everyone use '.*'.
$Foswiki::cfg{Plugins}{SendEmailPlugin}{Permissions}{Deny}{MailTo} = '.*';
#
# **STRING 300**
# Regular expression of mail addresses that we are allowed to send from. To send to multiple addresses you can write (address1|address2).
$Foswiki::cfg{Plugins}{SendEmailPlugin}{Permissions}{Allow}{MailFrom} = '';
#
# **STRING 300**
# Regular expression of mail addresses that we want to deny to send from. To send to multiple addresses you can write (address1|address2). To deny everyone use '.*'.
$Foswiki::cfg{Plugins}{SendEmailPlugin}{Permissions}{Deny}{MailFrom} = '.*';
#
# **STRING 300**
# Regular expression of mail addresses that we are allowed to send to by cc. To send to multiple addresses you can write (address1|address2).
$Foswiki::cfg{Plugins}{SendEmailPlugin}{Permissions}{Allow}{MailCc} = '';
#
# **STRING 300**
# Regular expression of mail addresses that we want to deny to send to by cc. To send to multiple addresses you can write (address1|address2). To deny everyone use '.*'.
$Foswiki::cfg{Plugins}{SendEmailPlugin}{Permissions}{Deny}{MailCc} = '.*';
#
# **STRING 300**
# Localized error message (English)
$Foswiki::cfg{Plugins}{SendEmailPlugin}{Messages}{SendError}{en} = '[[%SYSTEMWEB%.SendEmailPlugin]] send error';
#
# **STRING 300**
# Localized button label (English)
$Foswiki::cfg{Plugins}{SendEmailPlugin}{Messages}{ButtonLabel}{en} = 'Show error message';
#
# **STRING 300**
# Localized message mail sent successfully (English)
$Foswiki::cfg{Plugins}{SendEmailPlugin}{Messages}{SentSuccess}{en} = 'Email sent!';
#
# **STRING 300**
# Localized message mail sent error (English)
$Foswiki::cfg{Plugins}{SendEmailPlugin}{Messages}{SentError}{en} = 'Could not send email.';
#
# **STRING 300**
# Localized message invalid mail address (English). $EMAIL is a placeholder and must be in the text.
$Foswiki::cfg{Plugins}{SendEmailPlugin}{Messages}{InvalidAddress}{en} = '\'$EMAIL\' is not a valid e-mail address or account.';
#
# **STRING 300**
# Localized message empty 'to' field (English). $EMAIL is a placeholder and must be in the text.
$Foswiki::cfg{Plugins}{SendEmailPlugin}{Messages}{EmptyTo}{en} = 'You must pass a \'to\' e-mail address.';
#
# **STRING 300**
# Localized message empty 'from' field (English). $EMAIL is a placeholder and must be in the text.
$Foswiki::cfg{Plugins}{SendEmailPlugin}{Messages}{EmptyFrom}{en} = 'You must pass a \'from\' e-mail address.';
#
# **STRING 300**
# Localized message no permission to send email from the given address (English). $EMAIL is a placeholder and must be in the text.
$Foswiki::cfg{Plugins}{SendEmailPlugin}{Messages}{NoPermissionFrom}{en} = 'No permission to send an e-mail from \'$EMAIL\'.';
#
# **STRING 300**
# Localized message no permission to send email to the given address (English). $EMAIL is a placeholder and must be in the text.
$Foswiki::cfg{Plugins}{SendEmailPlugin}{Messages}{NoPermissionTo}{en} = 'No permission to send an e-mail to \'$EMAIL\'.';
#
# **STRING 300**
# Localized message no permission to send email to the given cc address (English). $EMAIL is a placeholder and must be in the text.
$Foswiki::cfg{Plugins}{SendEmailPlugin}{Messages}{NoPermissionCc}{en} = 'No permission to cc an e-mail to \'$EMAIL\'.';
#
# **PERL**
# This setting is required to enable executing the compare script from the bin directory
$Foswiki::cfg{SwitchBoard}{sendemail} = [
          'Foswiki::Plugins::SendEmailPlugin::Core',
          'sendEmail',
          {
            'sendemail' => 1
          }
        ];
1;
