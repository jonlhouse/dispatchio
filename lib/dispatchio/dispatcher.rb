module Dispatchio

  class Dispatcher

    def initialize(&block)
      @listeners = []
      instance_eval(&block) if block_given?
    end

    def dispatch(event, payload = {})
      @listeners.each do |listener|
        listener.dispatch_to_handler(payload) if listener.for?(event)
      end
    rescue StopDispatch
      false
    end

    # Add listener for an event.
    #
    # Usage:
    # Using a custom listener:
    #  class MyListenver < Dispatchio::Listener
    #    def handle(payload)
    #      # code
    #    end
    #  end
    #
    # Passing an instantiated listener...
    # dispatcher.add MyListener.new('event')
    # 
    # Passing an event and a Listener class
    # dispatcher.add 'event', MyListener
    #
    # Using the default listener:
    # dispatcher.add Listener.new('event', ->(payload) { # code })
    # dispatcher.add( Listener.new('event') do |payload
    #   # code
    # end )
    # NOTE:  With the previous form due to binding prescedence either parens
    #  around the +add+ must be given: (e.g. +dispatch.add(Listener.new('event') do |x| x end)+) 
    #  or braces around the block must be used: (e.g. +dispatch.add Listener.new('event') { |x| x }})
    #
    # Using Shortcuts: 
    #
    # Using a block: (proc)
    # dispatcher.add 'event' do |payload|
    #   
    # end
    # dispatcher.add 'event', ->(payload) { # code }
    # dispatcher.add 'event', Proc.new{ |payload| # code }
    #
    def add(*params, &block)
      listener = if params.length == 1
                    klass_or_event = params.shift
                    if klass_or_event.is_a? Listener
                      listener = klass_or_event
                    else
                      if block_given?
                        Listener.new(klass_or_event, &block)
                      else
                        raise ArgumentError, "listener must be given"
                      end
                    end
                  else
                    # event/proc or event/Listener
                    event = params.shift
                    callable_or_klass = params.shift
                    if callable_or_klass.respond_to?(:call)
                      Listener.new('event', callable_or_klass)
                    elsif callable_or_klass <= Listener
                      callable_or_klass.new(event)
                    else
                      # should never get here as class compare will raise TypeError first
                      raise ArgumentError, "illegal #{callable_or_klass}"
                    end
                  end
        add_listener listener
        listener
      end
    alias_method :<<, :add
    alias_method :listen, :add

    # Removes a listener from the list waiting for events.
    #
    def remove(listener_or_sid)
      sid = sid_param(listener_or_sid)
      @listeners.delete_if { |listener| listener.sid == sid }
    end

    # Returns whether listener is listening for events.
    #
    def include?(listener_or_sid)
      sid = sid_param(listener_or_sid)
      @listeners.any? { |listener| listener.sid == sid }
    end

  private

    def add_listener(listener)
      @listeners << listener
      # re-sort
      @listeners.sort!
      listener
    end

    def sid_param(param)
      sid = param.respond_to?(:sid) ? param.sid : param.to_int
    end

  end

end