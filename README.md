# Dispatchio

A light-weight Ruby event-dispatch library following the oberserve publish-subscribe model.

## Installation

Add this line to your application's Gemfile:

    gem 'dispatchio'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install dispatchio

## Usage

*Dispatchio* allows message dispatch to various listeners.  Unlike a typical observer model, 
*Dispatchio allows* listener to selectively receive certain messages based on their *event*.  
These events are user-defined dot-separated strings.

### Basic Usage

Basic usage is as follows:

```ruby
	require 'dispatchio'

	class SomeEventListener < Dispatchio::Listener
		def handle(payload)
			puts payload
		end
	end

	dispatcher = Dispatchio::Dispatcher.new()
	dispatcher << SomeEventListener.new('some-event')

	dispatcher.dispatch('some-event', 'Hello World')

	#=> "Hellow World"
```

Note that +handle+ is specificy called (unless a proc, lamabda or method is given -- see 
below).  You should override +handle+ in any sub-class you define.

### Defining Listeners

There are many ways to define a listener.  It can sub-class +Dispatch::Listener+.
```ruby
	class SomeEventListener < Dispatchio::Listener
	end

	dispatcher << SomeEventListener.new('some-event')
```

A proc, lambda or method name can be given if using the Dispatcher#add syntax.
```ruby
	dispatcher.add 'some-event' do |payload|
		puts "Some-Event happened"
	end
	
	dispatcher.add 'some-event', ->(payload) { puts "Some-Event Happened" }
	
	def some_event
		puts "Some Event Happened"
	end
	dispatcher.add 'some-event', :some_event

```

Alternatively, a block can be given with the class syntax.
```ruby
	dispatcher << Dispatchio::Listener.new('some-event') do |payload|
		puts "Some-Event Happened"
	end
```

### Specifying Events

The events can be a *dot.separated.string*.  Listeners can either sepecify the full 
multi-part string or can wildcard. 

```ruby
	dispatcher << Listener.new('create.model') { |payload| puts "whole name handled" }
	dispatcher << Listener.new('create.*') { |payload| puts "wildcard handled" }

	# note this will not be called
	dispatcher << Listener.new('create') { |payload| puts "should not be handled" }

	dispatcher.dispatch('create.model')
	# => "whole name handled"
	# => "wildcard handled"
```

### Block Style Definition

```ruby
	Dispatchio::Dispatcher do
		# Within the block you call +dispatch+ to add listeners.  Multiple 
		#  formats are allowed:
		#
		# pass Event class
		dispatch 'event-a', EventAListener

		# pass block
		dispatch 'event-b' do |payload|
			# handler code
		end

		# pass lambda
		dispatch 'event-c', ->(payload) { # handler code }

		# pass method symbol
		dispatch, 'event-c', :event_c_handler
	end
```

### Removing Listeners

Listeners can be removed by pass the listener object or it's subscriber ID (unique integer).

```ruby
	listener = dispatcher.add 'event', MyListener
	
	dispatcher.remove listener
	# or
	dispatcher.remove listener.sid

```


## Contributing

1. Fork it ( http://github.com/<my-github-username>/dispatchio/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
