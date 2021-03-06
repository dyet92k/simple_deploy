require 'trollop'

module SimpleDeploy
  module CLI

    class Create
      include Shared

      def create
        @opts = Trollop::options do
          version SimpleDeploy::VERSION
          banner <<-EOS

Create a new stack.

simple_deploy create -n STACK_NAME -t PATH_TO_TEMPLATE -e ENVIRONMENT -a KEY1=VAL1 -a KEY2=VAL2

EOS
          opt :help, "Display Help"
          opt :attributes, "= seperated attribute(s) and it's value. \
Can be specified multiple times.", :type  => :string,
                                                                   :multi => true
          opt :input_stack, "Read outputs from given stack(s) and map them \
to parameter inputs in the new stack. These will be passed to inputs with \
matching or pluralized names. Can be specified multiple times.", :type  => :string,
                                :multi => true
          opt :environment, "Set the target environment", :type => :string
          opt :log_level, "Log level:  debug, info, warn, error", :type    => :string,
                                                                  :default => 'info'
          opt :name, "Stack name(s) of stack to deploy", :type => :string
          opt :read_from_env, "Read credentials and region from environment variables"
          opt :template, "Path to the template file", :type => :string
        end

        valid_options? :provided => @opts,
                       :required => [:environment, :name, :read_from_env, :template]

        config_arg = @opts[:read_from_env] ? :read_from_env : @opts[:environment]
        SimpleDeploy.create_config config_arg
        SimpleDeploy.logger @opts[:log_level]
        stack = Stack.new :name        => @opts[:name],
                          :environment => @opts[:environment]

        rescue_exceptions_and_exit do
          stack.create :attributes => merged_attributes,
                       :template   => @opts[:template]
        end
      end

      def command_summary
        'Create a new stack'
      end

      private

      def merged_attributes
        provided_attributes = parse_attributes :attributes => @opts[:attributes]

        attribute_merger.merge :attributes   => provided_attributes,
                               :environment  => @opts[:environment],
                               :input_stacks => @opts[:input_stack],
                               :template     => @opts[:template]
      end

      def attribute_merger
        SimpleDeploy::Misc::AttributeMerger.new
      end
    end

  end
end
