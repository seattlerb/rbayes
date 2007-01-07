= rbayes

Rubyforge Project:

http://rubyforge.org/projects/seattlerb

== About

rbayes is a bayesian classifier with an email-specific tokenizer.
rbayes was originally written by Dan Peterson and later refactored
into a single class.

== Installing rbayes

Just install the gem:

  $ sudo gem install rbayes

== Using rbayes

  rb = RBayes.new 'inbox.db', 
  
  # mark a message as tasty:
  rb.update_db_with email_message, :add_tasty
  
  # mark a message as bland:
  rb.update_db_with email_message, :add_bland
  
  # remove a message's tastiness:
  rb.update_db_with email_message, :remove_tasty
  
  # remove a message's blandness:
  rb.update_db_with email_message, :remove_bland
  
  # switch a message from tasty to bland
  rb.update_db_with email_message, :remove_tasty
  rb.update_db_with email_message, :add_bland
  
  # switch a message from bland to tasty
  rb.update_db_with email_message, :remove_bland
  rb.update_db_with email_message, :add_tasty

