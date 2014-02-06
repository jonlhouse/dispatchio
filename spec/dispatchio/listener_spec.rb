require 'spec_helper'

module Dispatchio

  class MyListener < Listener
    def handle(payload)
      42
    end
  end

  describe Listener do

    describe "#initialize" do
      describe "event name" do
        context "when allowed" do
          specify { expect(Listener.new('something').listens_for?('else')).to be_false }
          specify { expect(Listener.new('event').listens_for?('event')).to be_true }
          specify { expect(Listener.new(:event).listens_for?('event')).to be_true }
          it "converts the argument using to_s" do
            param = double to_s: 'something'
            expect(Listener.new(param).listens_for?('something')).to be_true
          end
        end
        context "when disallowed" do
          specify { expect { Listener.new('') }.to raise_error(ArgumentError) }
          specify { expect { Listener.new(nil) }.to raise_error(ArgumentError) }          
        end
      end

      it "calls the handle method when dispatched to handler" do
        listener = Listener.new('event')
        expect(listener).to receive(:handle)
        listener.dispatch_to_handler
      end

      describe "blocks, procs and lambdas" do
        it "accepts a block" do
          expect(Listener.new('event') { |payload| 42 }.dispatch_to_handler).to be == 42
        end
        it "accepts a proc" do
          proc = Proc.new { 42 }
          expect(Listener.new('event', proc).dispatch_to_handler).to be == 42
        end
        it "accepts a lambda" do
          expect(Listener.new('event', -> (payload) { 42 }).dispatch_to_handler).to be == 42
        end
        it "raises error if block and proc/lambda is given" do
          expect{Listener.new('event', -> (x) { 'lambda' } ) { |payload| 'block' }}.to raise_error(ArgumentError)
        end
      end

      describe "subscriber IDs (sid)" do
        it "each SID is unique even with same event and handler" do
          a1 = Listener.new('a')
          a2 = Listener.new('a')
          expect(a1.sid).to_not eq(a2.sid)
        end
        it "common counter amongst subclasses" do
          a1 = Listener.new('a')
          a2 = MyListener.new('a')
          expect(a1.sid).to eq(a2.sid-1)
        end
      end
    end

    describe "#listens_for?" do
      # see normal matching above
      context "when symbols" do
        specify { expect(Listener.new(:event).listens_for?(:event)).to be_true }
      end

      context "when dot.separated.string" do
        specify { expect(Listener.new('a.b.c').listens_for?('a.b.c')).to be_true }
        specify { expect(Listener.new('c.b.a').listens_for?('a.b.c')).to be_false } # fail
      end

      context "when wildcards" do  
        context "doesn't match" do
          fail_strs = ['d.*', '*.d.*']
          fail_strs.each do |str|
            specify { expect(Listener.new(str).listens_for?('a.b.c')).to be_false }
          end
        end
        context "does match" do
          good_strs = ['*.b.c', '*', '*.b.*', 'a.*', 'a..b.c', 'a..*.c']
          good_strs.each do |str|
            specify { expect(Listener.new(str).listens_for?('a.b.c')).to be_true }
          end
        end

        context "when malformed raises ArgumentError" do
          malformed = ['a*.b', '*.']
          malformed.each do |malformed_str|
            specify { expect { Listener.new(malformed_str) }.to raise_error(ArgumentError) }  
          end
        end
      end
    end

  end

end