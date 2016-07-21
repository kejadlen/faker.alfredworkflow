require 'delegate'

$LOAD_PATH.unshift(File.expand_path('../vendor/bundle', __FILE__))
require 'bundler/setup'

require 'alphred'
require 'faker'

module Workflow
  class Faker
    FAKER_KLASSES = ::Faker.constants
                           .reject {|c| c == :Config }
                           .map {|c| ::Faker.const_get(c) }
                           .select {|c| Class === c}
    FAKER_METHODS = FAKER_KLASSES.flat_map {|klass|
      klass.singleton_methods(false)
           .map {|m| klass.method(m) }
           .select {|m| [-1, 0].include?(m.arity) }
    }

    attr_reader :query

    def initialize(*query)
      @query = query.map {|term| Regexp.new(term, Regexp::IGNORECASE) }
    end

    def items
      items = Alphred::Items.new

      self.matching_methods.each do |method|
        result = method.call rescue next # Ignore missing translations

        klass = method.owner.to_s[/#<Class:(.*)>/, 1]
        klass_short = klass.split('::').last.downcase
        query = [klass_short, method.name].join(' ')

        items << Item.new(query, result, query)
      end

      items
    end

    # def matching_methods(klass)
    def matching_methods
      FAKER_METHODS.select { |method|
        query.all? { |term|
          method.to_s =~ term || method.owner.to_s =~ term
        }
      }
    end
  end

  class Item < SimpleDelegator
    def initialize(query, result, autocomplete)
      super(
        Alphred::Item.new(
          uid: query,
          arg: result,
          autocomplete: autocomplete,
          title: query,
          subtitle: result,
          icon: 'icon.png',
        )
      )
    end
  end
end

if __FILE__ == $0
  query = ARGV.shift
  workflow = Workflow::Faker.new(*query.split(/\s+/))
  puts workflow.items.to_json
end
