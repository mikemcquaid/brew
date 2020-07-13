# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks for consistent style of change matcher.
      #
      # Enforces either passing object and attribute as arguments to the matcher
      # or passing a block that reads the attribute value.
      #
      # This cop can be configured using the `EnforcedStyle` option.
      #
      # @example `EnforcedStyle: block`
      #   # bad
      #   expect { run }.to change(Foo, :bar)
      #
      #   # good
      #   expect { run }.to change { Foo.bar }
      #
      # @example `EnforcedStyle: method_call`
      #   # bad
      #   expect { run }.to change { Foo.bar }
      #   expect { run }.to change { foo.baz }
      #
      #   # good
      #   expect { run }.to change(Foo, :bar)
      #   expect { run }.to change(foo, :baz)
      #   # also good when there are arguments or chained method calls
      #   expect { run }.to change { Foo.bar(:count) }
      #   expect { run }.to change { user.reload.name }
      #
      class ExpectChange < Cop
        extend AutoCorrector
        include ConfigurableEnforcedStyle

        MSG_BLOCK = 'Prefer `change(%<obj>s, :%<attr>s)`.'
        MSG_CALL = 'Prefer `change { %<obj>s.%<attr>s }`.'

        def_node_matcher :expect_change_with_arguments, <<-PATTERN
          (send nil? :change ({const send} nil? $_) (sym $_))
        PATTERN

        def_node_matcher :expect_change_with_block, <<-PATTERN
          (block
            (send nil? :change)
            (args)
            (send ({const send} nil? $_) $_)
          )
        PATTERN

        def on_send(node)
          return unless style == :block

          expect_change_with_arguments(node) do |receiver, message|
            msg = format(MSG_CALL, obj: receiver, attr: message)
            add_offense(node, message: msg) do |corrector|
              replacement = "change { #{receiver}.#{message} }"
              corrector.replace(node, replacement)
            end
          end
        end

        def on_block(node)
          return unless style == :method_call

          expect_change_with_block(node) do |receiver, message|
            msg = format(MSG_BLOCK, obj: receiver, attr: message)
            add_offense(node, message: msg) do |corrector|
              replacement = "change(#{receiver}, :#{message})"
              corrector.replace(node, replacement)
            end
          end
        end
      end
    end
  end
end