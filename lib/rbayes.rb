#!/usr/bin/env ruby -w

# Dan Peterson <danp@danp.net>
# you can do whatever you want with this file but i appreciate credit
#
# Refactored by Eric Hodel <drbrain@segment7.net>

class RBayes

  ##
  # The version of RBayes you are using.

  VERSION = '1.0.0'

  # :stopdoc:
  COUNT_BLAND = " count_bland "
  COUNT_TASTY = " count_tasty "
  # :startdoc:

  ##
  # Bland tokens

  attr_reader :count_bland

  ##
  # Tasty tokens

  attr_reader :count_tasty

  ##
  # The BDB1 DB holding the token information.

  attr_reader :database

  ##
  # Creates a new RBayes object using the database +token_file+.  If +test+ is
  # true no writes are performed.  If +debug+ is true stuff gets logged to
  # $stderr.  +case_sensitive+ should be obvious.

  def initialize(token_file, case_sensitive = false, test = false,
                 debug = false)
    @case_sensitive = case_sensitive
    @test = test
    @debug = debug

    @database = DBM.open token_file, 'a+'

    @count_tasty = @database[COUNT_TASTY].to_i || 0
    @count_bland = @database[COUNT_BLAND].to_i || 0

    log "ham tokens: #{@count_tasty} bland tokens: #{@count_bland}"
  end

  ##
  # Logs +s+ to $stderr if debugging is on.

  def log(s)
    $stderr.puts s if @debug
  end

  ##
  # Yields tokens in +message+ ignoring the boring headers and such.

  def read_tokens_in(message)
    message.split($/).each do |line|
      line.chomp! "\r\n"
      
      next if line =~ /^\.?Date:/i
      next if line =~ /^\.?Message-ID:/i
      next if line =~ /^\.?In-Reply-To:/i
      next if line =~ /^\.?References:/i
      next if line =~ /^\.?[A-Za-z0-9\/\+]+$/
      next if line =~ /SMTP id/i
      next if line =~ /boundary=/
      next if line =~ /name=\"/
      next if line =~ /filename=\"/
      next if line =~ /^--[^\s\n]*$/
      
      line.downcase! unless @case_sensitive

      #log "Tokenizing #{line.inspect}"
      line.split(/(?:[^\w.?'@:$\/+-]+)/).each do |token|
        next if token.length < 3
        next if token =~ /^\d+$/

        yield token
      end
    end
  end

  ##
  # Returns a Hash mapping tokens to the number of occurances in +message+.

  def count_tokens_in(message)
    counts = Hash.new 0

    read_tokens_in message do |tok|
      counts[tok] += 1
    end

    return counts
  end

  ##
  # Rates +message+ as tasty or bland.

  def rate(message)
    ratings = {}

    read_tokens_in message do |tok|
      unless ratings.has_key? tok then
        ratings[tok] = (0.5 - rate_token(tok)).abs
      end
    end

    inttok = ratings.sort_by { |v| -v[1] }[0..14]

    p = 1.0
    m1p = 1.0

    inttok.each do |tok, blandness|
      y = rate_token tok
      log "token #{tok} is %0.2f bland" % y
      p *= y
      m1p *= 1.0 - y
    end

    return p / (p + m1p)
  end

  ##
  # Updates the database with tokens from +message+.
  #
  # +mode+ may be:
  #
  # <tt>:add_bland</tt>:: increases tastiness of found tokens
  # <tt>:add_tasty</tt>:: increases tastiness of found tokens
  # <tt>:remove_bland</tt>:: decreases blandness of found tokens
  # <tt>:remove_tasty</tt>:: decreases tastiness of found tokens

  def update_db_with(message, mode)
    unless [:add_bland, :remove_bland, :add_tasty, :remove_tasty].include? mode
      raise ArgumentError, 'invalid mode'
    end
    log "updating db: #{mode}"

    counts = count_tokens_in message

    counts.each do |tok, cnt|
      tnum, bnum = (@database[tok] || "0 0").split(/\s+/)
      tnum, bnum = tnum.to_i, bnum.to_i
      log "found: #{tok} #{cnt} times, tasty: #{tnum}, bland: #{bnum}"
      
      unless @test then
        case mode
        when :add_tasty then tnum += cnt
        when :add_bland then bnum += cnt
        when :remove_tasty then tnum -= cnt
        when :remove_bland then bnum -= cnt
        end
      end
      
      tnum = 0 if tnum < 0
      bnum = 0 if bnum < 0

      # token not needed any more, don't waste space
      if tnum == 0 && bnum == 0 then
        @database.delete tok unless @test
        log "probs: #{tok} deleted"

      # update probability database
      else
        @database[tok] = [tnum, bnum].join(" ") unless @test
        log "update: #{tok}, tasty: #{tnum}, bland: #{bnum}"
      end
    end

    # for master count
    case mode
    when :add_tasty then @count_tasty += 1
    when :add_bland then @count_bland += 1
    when :remove_tasty then @count_tasty -= 1
    when :remove_bland then @count_bland -= 1
    end

    @count_tasty = 0 if @count_tasty < 0
    @count_bland = 0 if @count_bland < 0

    unless @test then
      @database[COUNT_TASTY] = @count_tasty
      @database[COUNT_BLAND] = @count_bland
    end
  end
 
  ##
  # Rates token +tok+ for tastiness.  Returns a probability between 0 and 1.

  def rate_token(tok)
    tnum, bnum = (@database[tok] || "0 0").split(/\s+/)
    tnum, bnum = tnum.to_i, bnum.to_i

    if tnum == 0 && bnum > 0 then
      return 0.99

    elsif bnum == 0 && tnum > 0 then
      return 0.01

    elsif tnum == 0 && bnum == 0 then
      return 0.4

    end

    tasty = 2.0 * tnum
    bland = bnum.to_f

    tasty /= @count_tasty.to_f
    tasty = 1.0 if tasty > 1.0
    bland /= @count_bland.to_f
    bland = 1.0 if bland > 1.0
    
    t = bland / (tasty + bland)
    t = 0.99 if t > 0.99
    t = 0.01 if t < 0.01
    
    return t
  end

end

