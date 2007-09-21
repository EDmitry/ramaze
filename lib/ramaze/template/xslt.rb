require 'xml/libxml'
require 'xml/xslt'
require 'thread'

module Ramaze

  # Use the Gestalt helper to put your controller result
  # into proper XML form
  #
  # TODO:
  # * Complex extFunction return values
  # * Error handling
  # * Maybe prevent extFunction to be called by HTTP
  module Template
    class XSLT < Template
      ENGINES[self] = %w[ xsl ]

      XSLT_EXT_FUNCTIONS_LOCK = Mutex.new

      class << self

        # Entry point for Action#render

        def transform action

          if options = action.instance.ancestral_trait[:xslt_options] and
              fun_xmlns = options[:fun_xmlns]
            # If a controller uses extFunctions, lock the whole
            # transform action with a Mutex to prevent mixing
            # extFunction binding and callback of two controller
            # instances with one fun_xmlns.
            ext_functions_synchronize do
              register_ext_functions action.instance, fun_xmlns
              do_transform action
            end

          else
            do_transform action
          end

        end
            
        private

        def do_transform(action)
          result, file = result_and_file(action)

          xslt = XML::XSLT.new
          xslt.xsl = action.template
          xslt.xml = result
          xslt.serve
        end

        def ext_functions_synchronize &block
          Inform.debug "Locking extFunctions Mutex #{XSLT_EXT_FUNCTIONS_LOCK.inspect}"
          XSLT_EXT_FUNCTIONS_LOCK.synchronize &block
        end

        def register_ext_functions instance, fun_xmlns

          instance.methods.each do |method|
            if method =~ /^xslt_.+/
              method_name = method[5..-1]
              
              proxy_instance = make_functor(method_name.intern) { |*a|
                instance.send method.intern, *a
              }
              
              XML::XSLT.extFunction method_name.gsub('_', '-'), fun_xmlns, proxy_instance
            end
          end

        end

        def make_functor(m, &block)
          # Create anonymous class and instantiate;
          # anonymous because only this one object with this
          # particular custom method should call &block
          o = Class.new.new

          class << o
            def create_method(name, &block)
              self.class.send(:define_method, name, &block)
            end
          end

          o.create_method(m, &block)
          o
        end

      end
    end
  end
end
