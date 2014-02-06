require 'spec_helper'

module Dispatchio

  class MyListener < Listener
    def handle(payload)
      42
    end
  end

  describe Dispatcher do

    describe "#initialize" do
      subject { Dispatcher.new }

      specify { expect(:dispatch).to be_true }

      it "can be initialized with a block" do
        dispatcher = Dispatcher.new do
          listen 'a', MyListener
          listen 'b' do
            # code
          end
          listen 'c', ->(x) { }
          listen MyListener.new('d')
        end
        expect(dispatcher.instance_variable_get(:@listeners).length).to be == 4
      end
    end

    let(:dispatcher) { Dispatcher.new }

    describe "#add" do      

      it "add MyListerner('event')" do        
        listener = dispatcher.add MyListener.new('event')
        expect(listener.dispatch_to_handler).to be == 42
      end
      it "add 'event', MyListener" do
        listener = dispatcher.add 'event', MyListener
        expect(listener.dispatch_to_handler).to be == 42
      end
      it "add 'event', ->(payload) { # code }" do
        listener = dispatcher.add 'event', ->(x) { 42 }
        expect(listener.dispatch_to_handler).to be == 42
      end
      it "add 'event' { |payload| 'a block' }" do
        listener = dispatcher.add('event') { |payload| 42 }
        expect(listener.dispatch_to_handler).to be == 42
      end
      it "add MyLisener.new('event') { |payload| 'block' }" do
        listener = dispatcher.add MyListener.new('event') { |payload|
          'not 42'
        }
        expect(listener.dispatch_to_handler).to be == 'not 42'
      end
    end

    describe "#include?" do
      let(:listener) { Listener.new('event') }
      before(:each) { dispatcher << listener }

      context "true when" do
        specify { expect(dispatcher.include? listener).to be_true }
        specify { expect(dispatcher.include? listener.sid).to be_true }
      end
      context "false when" do
        specify { expect(dispatcher.include? -1).to be_false }
        specify { expect(dispatcher.include? Listener.new('a')).to be_false }
      end
    end

    describe "#remove" do
      let(:listener) { Listener.new('event') }
      before(:each) { dispatcher << listener }

      context "by listener" do
        it "removes the listener" do
          dispatcher.remove listener
          expect(dispatcher.include?(listener)).to be_false
        end
      end
      context "by sid" do
        it "removes the listener" do
          dispatcher.remove listener.sid
          expect(dispatcher.include?(listener)).to be_false
        end
      end
    end

    describe "#dispatch" do
      let(:a_listener) { Listener.new('a') }
      let(:b_listener) { Listener.new('b') }
      before(:each) { dispatcher << a_listener ; dispatcher << b_listener }

      it "when event does not match listener" do
        expect(b_listener).to_not receive(:dispatch_to_handler)
        dispatcher.dispatch('a')
      end
      it "dispatches to a direct match" do
        expect(a_listener).to receive(:dispatch_to_handler)
        dispatcher.dispatch('a')
      end
      it "delegates matches to listener.for?" do
        dispatcher.instance_variable_get(:@listeners).each do |listener|
          listener.should receive(:for?)
        end
        dispatcher.dispatch('event')
      end
      it "returns false when StopDispatch exception is raised" do
        dispatcher.add 'abort' do |x|
          raise StopDispatch
        end
        expect(dispatcher.dispatch('abort')).to be_false
      end
    end

    describe "priority" do
      context "when unspecified" do
        let(:low_priority) { Listener.new('a') }
        let(:high_priority) { Listener.new('a') }
        before(:each) { dispatcher << low_priority ; dispatcher << high_priority }
        it "run in order they are added" do
          expect(low_priority).to receive(:handle).ordered
          expect(high_priority).to receive(:handle).ordered
          dispatcher.dispatch 'a'
        end
      end
      context "when specificed" do
        let(:low_priority) { Listener.new('a', priority: :low) }
        let(:high_priority) { Listener.new('a', priority: :high) }
        before(:each) { dispatcher << low_priority ; dispatcher << high_priority }
        it "run in order of priority" do
          expect(high_priority).to receive(:handle).ordered         
          expect(low_priority).to receive(:handle).ordered          
          dispatcher.dispatch 'a'
        end
      end
      
      specify { }
    end

  end

end