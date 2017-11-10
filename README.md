# Archimate::Dsl

Enterprise Architecture as Code.

Develop your Enterprise Architecture ArchiMate models using a DSL (rather than a GUI app).

Benefits:

* Text based representation is easier to review for changes and share between architects
* Modularize your architecture and share modules between ArchiMate models.
    - Reduce duplicate effort
    - Produce different models for different future options
    - Produce snapshots of architecture for different points in time (as an alternative to Plateaus)
* Produce automated diagrams for viewpoints (including custom viewpoints).
    - Spend less time dragging things around and updating artifacts

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'archimate-dsl'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install archimate-dsl

## Usage

Write your ArchiMate architecture into a file. For example, `myarch.arx`

```ruby
model("Archisurance") do
  version "3.1.1"
  purpose "An example of a fictional Insurance company."
  properties(
    Property1: "Value of Property 1",
    Property2: "Value of Property 2"
  )

  customer = BusinessRole("Customer")

  mail_interface = BusinessInterface("mail")
  bank = BusinessRole("Customer's Bank")
  withdrawal = BusinessService("Withdrawal")

  folder("Business", type: "business") do
    items = [mail_interface, bank, customer]
  end

  mail_interface.serving("create/update", customer)
  bank.composes(mail_interface)
  bank.realizes(withdrawal)
end
```

Then run:

```sh
archidsl -o myarch.archimate myarch.arx
```

The output in `myarch.archimate` is an ArchiMate model that can be opened (and further edited) in [Archi](https://archimatetool.com).

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/mmorga/archimate-dsl.
