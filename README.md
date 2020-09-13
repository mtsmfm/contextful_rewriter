# ContextfulRewriter

Rewrite your Ruby codes with Ruby runtime information.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'contextful_rewriter'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install contextful_rewriter

## Usage

Let's say we have the following code:

```ruby
class Foo
  def foo
  end
end

class Bar
  def foo
    # Deprecated, use Bar#bar instead
  end

  def bar
  end
end

Foo.new.foo # keep using Foo#foo
Bar.new.foo # want to replace with .bar
```

In this case, you can't just replace `.foo` with `.bar`
because it also replaces `Foo#foo`.

This gem can help such situation.

### 1. Record runtime info

At the first, you need to create runtime info db:

```ruby
ContextfulRewriter.record_runtime_do
  # Put your codes here
end

ContextfulRewriter.write_runtime_info_db('db.yml')
```

### 2. Rewrite

Then, you can use `.rewrite` method to replace your codes:

```ruby
ContextfulRewriter.load_runtime_info_db('db.yml')

ContextfulRewriter.rewrite do |node, data, rewriter|
  receiver, method_name, *args = node.children

  if data[:caller_class_name] == "Foo" && method_name == :foo
    rewriter.replace(node.loc.expression, "#{receiver.loc.expression.source}.bar")
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/contextful_rewriter. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/contextful_rewriter/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the ContextfulRewriter project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/contextful_rewriter/blob/master/CODE_OF_CONDUCT.md).
