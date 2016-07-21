require 'delegate'

$LOAD_PATH.unshift(File.expand_path('../vendor/bundle', __FILE__))
require 'bundler/setup'

require 'alphred'
require 'faker'

module Workflow
  class Faker
    def items
      Alphred::Items[
        faker_methods.map { |method|
          result = method.call rescue next # Ignore missing translations

          klass = method.owner.to_s[/#<Class:(.*)>/, 1]
          klass_short = klass.split('::').last.downcase
          query = [klass_short, method.name]

          Item.new(query, result)
        }
      ]
    end

    private

    def faker_klasses
      ::Faker.constants
        .reject {|c| c == :Config }
        .map {|c| ::Faker.const_get(c) }
        .select {|c| Class === c}
    end

    def faker_methods
      faker_klasses.flat_map { |klass|
        klass.singleton_methods(false)
          .map {|m| klass.method(m) }
          .select {|m| [-1, 0].include?(m.arity) }
      }
    end
  end

  class Item < SimpleDelegator
    def initialize(query, result)
      query_string = query.join(' ')
      title = query[0]
      title << " [#{query[1..-1].join(' ')}]" if query.size > 1

      super(
        Alphred::Item.new(
          uid: query_string,
          arg: result,
          autocomplete: query_string,
          title: title,
          subtitle: result,
          icon: 'icon.png',
        )
      )
    end
  end
end

if __FILE__ == $0
  workflow = Workflow::Faker.new
  puts workflow.items.to_json
end
