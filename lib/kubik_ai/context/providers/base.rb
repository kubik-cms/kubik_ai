# frozen_string_literal: true

module KubikAi
  module Context
    module Providers
      class Base
        def heading
          self.class.name.demodulize
        end

        def available?
          true
        end

        def to_prompt
          raise NotImplementedError
        end

        private

        def configuration
          Kubik::AiConfiguration.instance
        rescue StandardError
          nil
        end
      end
    end
  end
end
