require_relative '../../lib/navigable/command'
require_relative '../../lib/navigable/response'

class Command
  extend Navigable::Command

  def execute; render; end
end

class NoExecuteCommand
  extend Navigable::Command
end

RSpec.describe Navigable::Command do
  describe '.extended' do
    subject(:extended_object) { NoExecuteCommand.new({}) }

    it 'defines a constructor that accepts params' do
      expect { extended_object }.not_to raise_error
    end

    it 'defines a render method' do
      expect { extended_object.render }.not_to raise_error
    end

    it 'defines an execute method that raise an error' do
      expect { extended_object.execute }.to raise_error(NotImplementedError)
    end
  end

  describe '.inherited' do
    let(:registrar) { instance_double(Navigable::Registrar, register: true) }
    let(:app) { instance_double(Navigable::Application, router: router) }
    let(:router) { instance_double(Hanami::Router) }
    let(:child) { Class.new(Command) }

    before do
      allow(Navigable::Registrar).to receive(:new).and_return(registrar)
      allow(Navigable).to receive(:app).and_return(app)
    end

    it 'registers the child class with the Registrar' do
      expect(Navigable::Registrar).to have_received(:new).with(child, router)
      expect(registrar).to have_received(:register)
    end
  end

  describe '.call' do
    let(:env) do
      {
        'parsed_body' => parsed_body,
        'router.params' => url_params
      }
    end

    let(:rack_request) do
      instance_double(Rack::Request, params: form_params)
    end

    let(:form_params) { {} }
    let(:parsed_body) { {} }
    let(:url_params) { {} }

    before do
      allow(Rack::Request).to receive(:new).and_return(rack_request)
    end

    context 'when there are no params' do
      context 'when a responds_with_method has NOT been configured' do
        context 'and there is an execute method' do
          subject(:call) { Command.call(env) }

          let(:no_params_command) do
            instance_double(Command, execute: Navigable::Response.new({}))
          end

          before do
            allow(Command).to receive(:new).and_return(no_params_command)

            call
          end

          it 'instantiates a command' do
            expect(Command).to have_received(:new).with({})
          end

          it 'calls execute on the command' do
            expect(no_params_command).to have_received(:execute).with(no_args)
          end
        end

        context 'and there is NOT an execute method' do
          subject(:call) { NoExecuteCommand.call(env) }

          it 'raises not implemented' do
            expect { call }.to raise_error(NotImplementedError)
          end
        end
      end
    end

    context 'when there are params' do
      subject(:call) { Command.call(env) }

      let(:form_params) { { search: 'toast' } }
      let(:parsed_body) { { 'title' => 'title', 'description' => 'description' } }
      let(:url_params) { { id: '123' } }

      before do
        allow(Command).to receive(:new).and_call_original

        call
      end

      it 'instantiates a command' do
        expect(Command).to have_received(:new).with(
          search: 'toast',
          title: 'title',
          description: 'description',
          id: '123'
        )
      end
    end
  end
end