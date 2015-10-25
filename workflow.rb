require "delegate"

$LOAD_PATH.unshift(File.expand_path("../vendor/bundle", __FILE__))
require "bundler/setup"

require "builder"
require "faker"

module Workflow
  class Faker
    FAKER_KLASSES = ::Faker.constants
                           .map {|c| ::Faker.const_get(c) }
                           .select {|c| Class === c}

    attr_reader *%i[klass method]

    def initialize(klass, method="")
      @klass, @method = klass, method
    end

    def items
      items = Items.new
      klasses = FAKER_KLASSES.select {|c| c.to_s.downcase.include?(self.klass.downcase) }
      klasses.each do |klass|
        methods = klass.singleton_methods(false).map {|m| klass.method(m) }
        methods = methods.select do |method|
          method.to_s.downcase.include?(self.method.downcase) && [-1, 0].include?(method.arity)
        end
        methods.each do |method|
          klass_short = klass.to_s.split("::").last.downcase
          query = [klass_short, method.name].join(" ")
          items << Item.new(query,
                            method.call,
                            (klasses.size == 1) ? query : klass_short)
        end
      end

      items
    end
  end

  class Items < DelegateClass(Array)
    attr_reader :items

    def initialize
      @items = []
      super(@items)
    end

    def to_xml
      xml = Builder::XmlMarkup.new(indent: 2)
      xml.instruct! :xml
      xml.items do
        self.items.each do |item|
          item.to_xml(xml)
        end
      end
    end
  end

  class Item < Struct.new(*%i[query result autocomplete])
    def to_xml(xml)
      attrs = { uid: query,
                arg: result,
                autocomplete: autocomplete }
      xml.item attrs do
        xml.title query
        xml.subtitle result
        xml.icon "icon.png"
      end
    end
  end
end

if __FILE__ == $0
  query = ARGV.shift
  workflow = Workflow::Faker.new(*query.split(" "))
  puts workflow.items.to_xml
end
