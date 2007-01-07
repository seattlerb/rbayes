require 'hoe'

require './lib/rbayes'

Hoe.new 'rbayes', RBayes::VERSION do |p|
  p.summary = 'An email-focused bayesian filter'
  p.description = 'An bayesian filter fed by a tokenizer that throws crap out you\'d find in emails.  Originally by Dan Peterson'
  p.author = 'Eric Hodel'
  p.email = 'drbrain@segment7.net'
  p.url = 'http://seattlerb.rubyforge.org/rbayes/'
  p.changes = File.read('History.txt').scan(/\A(=.*?)(=|\Z)/m).first.first

  p.rubyforge_name = 'seattlerb'
end

