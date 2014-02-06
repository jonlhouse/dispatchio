module Dispatchio

  class Listener
    include Comparable

    attr_reader :sid
    attr_accessor :priority
    @@sid_counter = 0

    # define some priority constants and symbols
    PRIORITY = { last: 0, low: 25, normal: 50, high: 75, first: 100 }.freeze

    # Usage:
    #  Listener.new('event-name')
    #  Listener.new(:event_name) 
    #  Listener.new 'event-name' do |payload|
    #    # handler
    #  end
    #  Listener.new('event-name', ->(payload) { # handle w/ payload })
    #  Listener.new('event-name', Proc.new { |payload| # handle core })
    #
    #  Note: Internally events are stored as strings so we can use dot (.) 
    #   notation for scoping events and :not.legal.symbol so using symbols 
    #   as events is of limited use, but is allowed.
    def initialize(*params, &block)
      opts = params.last.is_a?(Hash) ? params.pop : { priority: PRIORITY[:normal] }    # extract options... boo! no 2.0
      @priority = parse_priority(opts[:priority])
      @sid = @@sid_counter += 1
      @event = parse_event_wildcards(params.shift.to_s)
      raise ArgumentError, "#{@event} cannot be blank or nil" unless @event.length > 0
      
      @callable = if params.length > 0
                    proc_or_lambda = params.shift
                    if proc_or_lambda.respond_to?(:call)
                      raise ArgumentError, "cannot accept both proc/lambda and a block" if block_given?
                      proc_or_lambda
                    else
                      nil
                    end
                  elsif block_given?
                    lambda(&block)
                  else
                    nil
                  end
    end

    # Used to sort/compare listener based on priority
    #
    # Returns:
    #   -1 when self should be higher priority than other
    #    0 when self and other are equal priority
    #   +1 when self should be lower priority than other
    def <=>(other)
      other.priority <=> self.priority
    end

    # Returns true if match_str matches @event.
    #
    def listens_for?(match_str)
      if @event_rx
        !!(@event_rx =~ match_str.to_s)
      else
        @event == match_str.to_s
      end
    end
    alias_method :for?, :listens_for?

    # Wrapper around whichever handle method actually gets invoked.  Basically,
    #  if a Listener is created with a callable proc or lamabda, that function
    #  take prescedent over the handle method.
    #
    # Note: This function **shouldn't** be overridden.  If you want to subclass 
    #  the handler, override ++.
    # 
    def dispatch_to_handler(payload = {})
      if @callable
        @callable.call payload
      else
        handle payload
      end
    end

    # Main "listener" handler.  Override this method to change the functionality of your 
    #  application-specific handler.
    # 
    # Usage:
    #  class MyListener < Dispatchio::Listener
    #    def handle(payload)
    #      puts "MyListener#handle called with #{payload}"
    #    end
    #  end
    #  
    # The return value of this function is ignored.  The dispatcher will either return true 
    #  if all handlers complete or false if handling is stopped.
    #
    # To stop event handling raise a Dispatchio::StopDispatch exception.
    #
    def handle(payload)
    end

  private 

    # If str matches:
    #  '*'
    #  'a.*.c'
    # formats convert to regex.
    #
    def parse_event_wildcards(str)
      # santize str
      str = str.squeeze('.')
      # build the regex only if wildcard is present
      if str.include?('*')
        if str =~ /^(\* | [\w-]+)(\.((\* | [\w-]+)))*$/ix
          escaped = Regexp.escape(str).gsub('\*','(.+)')
          @event_rx = Regexp.new "^#{escaped}$", Regexp::IGNORECASE
        else
          raise ArgumentError, "Illegal event wildcard string: #{str}"
        end
      end
      str
    end

    # Returns a priority value (0-100) converted a symbol (e.g. :low) into the corrsponding value.
    def parse_priority(value)
      num = Float(value) rescue false
      unless num
        num = PRIORITY[value.to_sym]
        raise ArgumentError, "#{value} not a valid priority" unless num
      end
      num
    end

  end

end